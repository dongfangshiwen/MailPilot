package app.mailpilot.mail

import app.mailpilot.data.*
import androidx.room.withTransaction
import jakarta.mail.*
import jakarta.mail.internet.*
import jakarta.mail.search.*
import jakarta.activation.DataHandler
import jakarta.activation.FileDataSource
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.withContext
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import org.eclipse.angus.mail.imap.IMAPFolder
import org.eclipse.angus.mail.imap.IMAPStore
import org.eclipse.angus.mail.imap.SortTerm
import org.jsoup.Jsoup
import org.jsoup.safety.Safelist
import java.io.File
import java.io.InputStream
import java.io.ByteArrayOutputStream
import java.nio.charset.Charset
import java.util.Date
import java.util.Properties
import kotlin.coroutines.coroutineContext

const val MAX_ATTACHMENT_BYTES = 20L * 1024 * 1024

fun InputStream.readLimited(limit: Long): ByteArray {
    val out=ByteArrayOutputStream(); val buffer=ByteArray(8192); var count=0L
    while(true) { val n=read(buffer); if(n<0) break; count+=n; require(count<=limit) { "内容超过大小上限" }; out.write(buffer,0,n) }
    return out.toByteArray()
}

interface MailRepository {
    suspend fun test(account: MailAccount): String
    suspend fun folders(accountId: String): List<String>
    suspend fun load(accountId: String, folder: String, query: MailQuery = MailQuery(), onProgress: (String)->Unit = {}): List<MailMessage>
    suspend fun markRead(message: MailMessage)
    suspend fun download(id: String): Attachment
    suspend fun saveDraft(draft: Draft): Draft
    suspend fun send(draftId: String, confirmedRevision: Long): Draft
    suspend fun syncAccount(accountId: String,priority: String,onProgress: (String)->Unit = {}): List<String> = error("同步不可用")
}

class MailRepositoryImpl(private val db: MailDatabase, private val secrets: SecretStore, private val filesDir: File,
    private val extraProperties: Properties = Properties(), private val preferServerSort: Boolean = true,
    private val onSyncStats: (Int,Int)->Unit = { _,_ -> }) : MailRepository {
    private val dao=db.dao()
    // Bounded locks prevent preview/retry/analysis from writing the same .part file.
    private val downloadLocks=Array(32) { Mutex() }
    private fun session(a: MailAccount): Session {
        require(a.imapHost.isNotBlank() && a.smtpHost.isNotBlank()) { "请填写邮箱服务器" }
        require(a.imapPort in 1..65535 && a.smtpPort in 1..65535) { "端口应在 1–65535 之间" }
        require(a.imapSecurity in listOf("SSL","STARTTLS") && a.smtpSecurity in listOf("SSL","STARTTLS")) { "邮箱必须启用 TLS" }
        val p=Properties()
        for ((protocol, security) in listOf("imap" to a.imapSecurity,"smtp" to a.smtpSecurity)) {
            p["mail.$protocol.connectiontimeout"]="15000"; p["mail.$protocol.timeout"]="20000"; p["mail.$protocol.writetimeout"]="20000"
            p["mail.$protocol.ssl.checkserveridentity"]="true"
            p["mail.$protocol.ssl.enable"]=(security=="SSL").toString()
            p["mail.$protocol.starttls.enable"]=(security=="STARTTLS").toString()
            p["mail.$protocol.starttls.required"]=(security=="STARTTLS").toString()
            p["mail.$protocol.socketFactory"]=RouteSocketFactory()
            p["mail.$protocol.socketFactory.fallback"]="false"
        }
        p["mail.smtp.auth"]="true"; p["mail.imap.peek"]="true"; p["mail.mime.decodefilename"]="true"
        p["mail.imap.fetchsize"]="65536"
        p.putAll(extraProperties)
        return Session.getInstance(p)
    }
    private fun connect(a: MailAccount): Store = session(a).getStore("imap").apply {
        connect(a.imapHost,a.imapPort,a.username.ifBlank { a.email },secrets.decrypt(a.passwordCipher))
        try { if(this is IMAPStore && hasCapability("ID")) id(mapOf("name" to "MailPilot", "version" to app.mailpilot.BuildConfig.VERSION_NAME, "vendor" to "MailPilot")) }
        catch(e: Exception) { runCatching { close() }; throw e }
    }
    override suspend fun test(account: MailAccount): String = withContext(Dispatchers.IO) {
        connect(account).use { check(it.isConnected) }
        coroutineContext.ensureActive()
        session(account).getTransport("smtp").use { it.connect(account.smtpHost,account.smtpPort,account.username.ifBlank { account.email },secrets.decrypt(account.passwordCipher)) }
        "IMAP 收信与 SMTP 发信认证成功（未发送测试邮件）"
    }
    override suspend fun folders(accountId: String): List<String> = withContext(Dispatchers.IO) {
        val a=requireNotNull(dao.account(accountId)) { "邮箱已被删除" }
        val names=connect(a).use { s -> s.defaultFolder.list("*").filter { it.type and Folder.HOLDS_MESSAGES != 0 }.map { it.fullName }.distinct().sortedWith(compareBy<String> { !it.equals("INBOX",true) }.thenBy { it }) }
        db.withTransaction { requireNotNull(dao.account(accountId)); dao.clearFolders(accountId); dao.putFolders(names.map { MailFolder(accountId,it) }) }
        names
    }
    override suspend fun load(accountId: String, folder: String, query: MailQuery, onProgress: (String)->Unit): List<MailMessage> = withContext(Dispatchers.IO) {
        require(query.limit in 1..50 && query.offset >= 0)
        val account=requireNotNull(dao.account(accountId)) { "请先添加邮箱" }
        onProgress("正在连接邮箱")
        connect(account).use { store ->
            val f=store.getFolder(folder) as IMAPFolder
            f.open(Folder.READ_ONLY)
            try {
                val terms=mutableListOf<SearchTerm>()
                if(query.keyword.isNotBlank()) terms+=OrTerm(SubjectTerm(query.keyword),FromStringTerm(query.keyword))
                if(query.unreadOnly) terms+=FlagTerm(Flags(Flags.Flag.SEEN),false)
                query.after?.let { terms+=ReceivedDateTerm(ComparisonTerm.GE,Date(it)) }
                query.before?.let { terms+=ReceivedDateTerm(ComparisonTerm.LE,Date(it)) }
                val filter=terms.takeIf { it.isNotEmpty() }?.let { AndTerm(it.toTypedArray()) }
                val items=newestPage(accountId,store as IMAPStore,f,filter,query,onProgress)
                onProgress("正在读取 ${items.size} 封邮件信息")
                val fp=FetchProfile().apply { add(FetchProfile.Item.ENVELOPE); add(FetchProfile.Item.FLAGS); add(FetchProfile.Item.CONTENT_INFO); add(UIDFolder.FetchProfileItem.UID); add("Message-ID"); add("References") }
                f.fetch(items.toTypedArray(),fp)
                val result=mutableListOf<MailMessage>(); val attachments=mutableListOf<Attachment>()
                var downloaded=0; var reused=0
                for(m in items) {
                    coroutineContext.ensureActive()
                    onProgress("正在读取邮件 ${result.size+1}/${items.size}")
                    val uid=f.getUID(m); val id=stableId("$accountId|$folder|${f.uidValidity}|$uid")
                    val old=dao.message(id)
                    if(old!=null && old.bodyError.isEmpty() && old.bodyState=="READY") {
                        result+=old.copy(unread=!m.isSet(Flags.Flag.SEEN)); reused++; continue
                    }
                    var bodyError=""
                    val parsed=try { downloaded++; MimeReader.parse(m,id) }
                        catch(e: FolderClosedException) { throw e }
                        catch(e: kotlinx.coroutines.CancellationException) { throw e }
                        catch(e: Exception) { bodyError="正文未完整读取，请刷新重试。${if(e is IllegalArgumentException) e.message.orEmpty().take(120) else "邮件格式异常或网络中断"}"; null }
                    val from=m.from?.firstOrNull() as? InternetAddress
                    val plain=parsed?.plain.orEmpty().ifBlank { Jsoup.parse(parsed?.html.orEmpty()).wholeText() }
                    result+=MailMessage(id,accountId,folder,f.uidValidity,uid,m.subject ?: "（无主题）",from?.personal ?: from?.address ?: "未知发件人",from?.address ?: "",
                        m.getRecipients(Message.RecipientType.TO)?.joinToString(", ") ?: "",m.getRecipients(Message.RecipientType.CC)?.joinToString(", ") ?: "",
                        m.replyTo?.joinToString(", ") ?: "",messageDate(m),
                        if(bodyError.isEmpty()) plain.replace(Regex("\\s+")," ").take(180) else bodyError,plain,parsed?.html.orEmpty(),!m.isSet(Flags.Flag.SEEN),parsed?.files?.size ?: 0,
                        m.getHeader("Message-ID")?.firstOrNull() ?: "",m.getHeader("References")?.joinToString(" ") ?: "",bodyError,if(bodyError.isEmpty()) "READY" else "ERROR")
                    for(att in parsed?.files.orEmpty()) attachments+=att.copy(localPath=dao.attachment(att.id)?.localPath ?: "")
                }
                db.withTransaction {
                    requireNotNull(dao.account(accountId)) { "邮箱已被删除，同步已停止" }
                    dao.purgeOldValidity(accountId,folder,f.uidValidity); dao.putMessages(result); dao.putAttachments(attachments); dao.purgeOrphanAttachments()
                }
                onSyncStats(downloaded,reused)
                result
            } finally { f.close(false) }
        }
    }
    private fun messageDate(message: Message): Long = (message.sentDate ?: message.receivedDate)?.time ?: 0L

    /** One account connection; metadata for every folder becomes visible before
     * body hydration. Checkpoints advance only after each metadata batch commits. */
    override suspend fun syncAccount(accountId: String,priority: String,onProgress: (String)->Unit): List<String> = withContext(Dispatchers.IO) {
        val errors=mutableListOf<String>(); var downloads=0; var reused=0
        val account=requireNotNull(dao.account(accountId)) { "邮箱已删除" }
        onProgress("正在连接邮箱")
        connect(account).use { store ->
            val names=store.defaultFolder.list("*").filter { it.type and Folder.HOLDS_MESSAGES!=0 }.map { it.fullName }.distinct()
            db.withTransaction { requireNotNull(dao.account(accountId)); dao.clearFolders(accountId); dao.putFolders(names.map { MailFolder(accountId,it) }) }
            val ordered=(listOf(priority,"INBOX")+names).distinct().filter { it in names }
            suspend fun visit(name: String,block: suspend (IMAPFolder)->Unit) {
                coroutineContext.ensureActive()
                try {
                    val f=store.getFolder(name) as IMAPFolder; f.open(Folder.READ_ONLY)
                    try { block(f) } finally { runCatching { f.close(false) } }
                } catch(e: kotlinx.coroutines.CancellationException) { throw e }
                  catch(e: Exception) { errors+="$name：${friendlyMailError(e)}" }
            }
            for(name in ordered) visit(name) { f ->
                onProgress("同步文件夹 ${ordered.indexOf(name)+1}/${ordered.size} · $name")
                val validity=f.uidValidity; val startHigh=if(f.uidNext>0) f.uidNext-1 else if(f.messageCount>0) f.getUID(f.getMessage(f.messageCount)) else 0
                val cursor=dao.syncCursor(accountId,name)?.takeIf { it.validity==validity }
                db.withTransaction { dao.purgeOldValidity(accountId,name,validity); dao.purgeOldIndex(accountId,name,validity); dao.purgeOrphanAttachments() }
                if(cursor==null) {
                    val page=newestPage(accountId,store as IMAPStore,f,null,MailQuery(limit=50),onProgress)
                    for(batch in page.chunked(10)) persistBatch(accountId,f,batch,false)
                    dao.putSyncCursor(SyncCursor(accountId,name,validity,startHigh))
                } else {
                    // Guard UIDNEXT: an inverted UID range can include old mail.
                    if(startHigh>cursor.lastUid) {
                        val added=f.getMessagesByUID(cursor.lastUid+1,startHigh).filter { !it.isExpunged }
                        f.fetch(added.toTypedArray(),FetchProfile().apply { add(UIDFolder.FetchProfileItem.UID) })
                        for(batch in added.sortedBy { f.getUID(it) }.chunked(50)) {
                            coroutineContext.ensureActive()
                            persistBatch(accountId,f,batch,false)
                            dao.putSyncCursor(SyncCursor(accountId,name,validity,f.getUID(batch.last())))
                        }
                    }
                    dao.putSyncCursor(SyncCursor(accountId,name,validity,maxOf(cursor.lastUid,startHigh)))
                }
                // Check only locally cached UIDs, without rescanning the full mailbox.
                for(batch in dao.cachedMessages(accountId,name).chunked(200)) {
                    coroutineContext.ensureActive()
                    val present=f.getMessagesByUID(batch.map { it.uid }.toLongArray()).filterNotNull().filter { !it.isExpunged }
                    f.fetch(present.toTypedArray(),FetchProfile().apply { add(UIDFolder.FetchProfileItem.UID); add(FetchProfile.Item.FLAGS) })
                    val flags=present.associate { f.getUID(it) to !it.isSet(Flags.Flag.SEEN) }
                    db.withTransaction {
                        batch.filter { it.uid in flags }.forEach { dao.setUnread(it.id,flags.getValue(it.uid)) }
                        val gone=batch.map { it.uid }.filter { it !in flags }
                        if(gone.isNotEmpty()) { dao.deleteMissingMessages(accountId,name,validity,gone); dao.deleteIndex(accountId,name,validity,gone) }
                        dao.purgeOrphanAttachments()
                    }
                }
            }
            for(name in ordered) visit(name) { f ->
                val cached=dao.cachedMessages(accountId,name).filter { it.uidValidity==f.uidValidity }
                reused+=cached.count { it.bodyState=="READY" && it.bodyError.isEmpty() }
                val pending=cached.filter { it.bodyState!="READY" || it.bodyError.isNotEmpty() }
                for((i,batch) in pending.chunked(5).withIndex()) {
                    coroutineContext.ensureActive(); onProgress("读取正文 · $name · ${minOf((i+1)*5,pending.size)}/${pending.size}")
                    val messages=f.getMessagesByUID(batch.map { it.uid }.toLongArray()).filterNotNull().filter { !it.isExpunged }
                    persistBatch(accountId,f,messages,true); downloads+=messages.size
                }
                val incomplete=dao.cachedMessages(accountId,name).count { it.bodyState=="ERROR" }
                if(incomplete>0) errors+="$name：$incomplete 封正文尚未完整读取"
            }
        }
        onSyncStats(downloads,reused); errors.distinct()
    }

    private suspend fun persistBatch(accountId: String,f: IMAPFolder,items: List<Message>,readBody: Boolean) {
        val profile=FetchProfile().apply { add(FetchProfile.Item.ENVELOPE); add(FetchProfile.Item.FLAGS); add(FetchProfile.Item.CONTENT_INFO); add(UIDFolder.FetchProfileItem.UID); add("Message-ID"); add("References") }
        f.fetch(items.toTypedArray(),profile)
        for(m in items) {
            coroutineContext.ensureActive()
            val uid=f.getUID(m); val id=stableId("$accountId|${f.fullName}|${f.uidValidity}|$uid")
            val old=dao.message(id)
            if(old?.bodyState=="READY" && old.bodyError.isEmpty()) { dao.setUnread(id,!m.isSet(Flags.Flag.SEEN)); continue }
            var error=""
            val parsed=try { MimeReader.parse(m,id,readBody) } catch(e: FolderClosedException) { throw e }
                catch(e: kotlinx.coroutines.CancellationException) { throw e }
                catch(e: Exception) { error="正文未完整读取，请同步重试。${friendlyMailError(e).take(100)}"; null }
            val from=m.from?.firstOrNull() as? InternetAddress
            val plain=parsed?.plain.orEmpty().ifBlank { Jsoup.parse(parsed?.html.orEmpty()).wholeText() }
            val state=if(error.isNotEmpty()) "ERROR" else if(readBody) "READY" else "PENDING"
            val value=MailMessage(id,accountId,f.fullName,f.uidValidity,uid,m.subject ?: "（无主题）",from?.personal ?: from?.address ?: "未知发件人",from?.address.orEmpty(),
                m.getRecipients(Message.RecipientType.TO)?.joinToString(", ").orEmpty(),m.getRecipients(Message.RecipientType.CC)?.joinToString(", ").orEmpty(),m.replyTo?.joinToString(", ").orEmpty(),messageDate(m),
                if(state=="READY") plain.replace(Regex("\\s+")," ").take(180) else if(state=="PENDING") "正文待同步" else error,plain,parsed?.html.orEmpty(),!m.isSet(Flags.Flag.SEEN),parsed?.files?.size ?: old?.attachmentCount ?: 0,
                m.getHeader("Message-ID")?.firstOrNull().orEmpty(),m.getHeader("References")?.joinToString(" ").orEmpty(),error,state)
            val files=parsed?.files.orEmpty().map { it.copy(localPath=dao.attachment(it.id)?.localPath.orEmpty()) }
            db.withTransaction {
                requireNotNull(dao.account(accountId)) { "邮箱已删除" }
                dao.putMessages(listOf(value)); dao.putAttachments(files)
                dao.putIndex(listOf(MailIndex(accountId,f.fullName,f.uidValidity,uid,value.sentAt)))
            }
        }
    }

    private suspend fun newestPage(accountId: String, store: IMAPStore, folder: IMAPFolder, filter: SearchTerm?, query: MailQuery,onProgress: (String)->Unit): List<Message> {
        if(preferServerSort && store.hasCapability("SORT")) {
            try {
                // DATE is ascending; reversing also reverses the implicit sequence tie-break.
                val ordered=if(filter==null) folder.getSortedMessages(arrayOf(SortTerm.DATE)) else folder.getSortedMessages(arrayOf(SortTerm.DATE),filter)
                return ordered.asList().asReversed().drop(query.offset).take(query.limit)
            } catch(e: FolderClosedException) { throw e }
              catch(e: MessagingException) { /* Rejected SORT falls back; connection errors still fail on fetch. */ }
        }
        // A UID-only scan detects additions and expunges. Dates are fetched only
        // for unknown UIDs, preserving Date ordering even after old mail imports.
        val candidates=folder.getMessagesByUID(1,UIDFolder.LASTUID)
        onProgress("正在核对 ${candidates.size} 封邮件索引")
        folder.fetch(candidates,FetchProfile().apply { add(UIDFolder.FetchProfileItem.UID) })
        val byUid=candidates.filter { !it.isExpunged }.associateBy { folder.getUID(it) }.filterKeys { it>0 }
        val name=folder.fullName; val validity=folder.uidValidity
        val cached=dao.mailIndex(accountId,name,validity).associateBy { it.uid }.toMutableMap()
        val oldUids=cached.keys.toSet()
        val profile=FetchProfile().apply { add(FetchProfile.Item.ENVELOPE); add(IMAPFolder.FetchProfileItem.INTERNALDATE) }
        val added=mutableListOf<MailIndex>()
        var ordered=emptyList<Message>()
        val compatibleSearch=CompatibleImapSearch { folder.search(it) }
        // Search recent dates first. Widen until the page is provably inside the
        // searched interval, then stop without indexing years of old mail.
        // OR with arrival date includes messages whose Date header is missing.
        for(days in listOf(2L,7L,30L,90L,365L,3650L,null)) {
            coroutineContext.ensureActive()
            val cutoff=days?.let { java.time.LocalDate.now().minusDays(it).atStartOfDay(java.time.ZoneId.systemDefault()).toInstant().toEpochMilli() }
            val window=cutoff?.let { OrTerm(SentDateTerm(ComparisonTerm.GE,Date(it)),ReceivedDateTerm(ComparisonTerm.GE,Date(it))) }
            val term=if(filter!=null && window!=null) AndTerm(filter,window) else filter ?: window
            val subset=if(term==null) byUid else compatibleSearch.find(term).filter { !it.isExpunged }.associateBy { folder.getUID(it) }.filterKeys { it>0 }
            val missing=subset.filterKeys { it !in cached }
            for(batch in missing.entries.chunked(200)) {
                onProgress("正在读取日期索引，新增 ${missing.size} 封")
                coroutineContext.ensureActive(); folder.fetch(batch.map { it.value }.toTypedArray(),profile)
                for((uid,message) in batch) {
                    val entry=MailIndex(accountId,name,validity,uid,messageDate(message))
                    cached[uid]=entry; added+=entry
                }
            }
            val uids=subset.keys.sortedWith(compareByDescending<Long> { cached[it]?.sentAt ?: 0 }.thenByDescending { it })
            ordered=uids.drop(query.offset).take(query.limit).mapNotNull { subset[it] }
            // SEARCH dates discard time zones. A two-day guard avoids stopping
            // across the date-only boundary; imported old dates still widen.
            if(cutoff==null || (ordered.size==query.limit && (cached[folder.getUID(ordered.last())]?.sentAt ?: 0)>=cutoff+2*86400000L)) break
        }
        db.withTransaction {
            requireNotNull(dao.account(accountId)) { "邮箱已被删除，同步已停止" }
            dao.purgeOldIndex(accountId,name,validity); dao.purgeOldValidity(accountId,name,validity)
            dao.putIndex(added)
            for(removed in (oldUids-byUid.keys).chunked(500)) {
                dao.deleteIndex(accountId,name,validity,removed); dao.deleteMissingMessages(accountId,name,validity,removed)
            }
            dao.purgeOrphanAttachments()
        }
        return ordered
    }
    override suspend fun markRead(message: MailMessage) = withContext(Dispatchers.IO) {
        val a=requireNotNull(dao.account(message.accountId))
        connect(a).use { s -> val f=s.getFolder(message.folder) as IMAPFolder; f.open(Folder.READ_WRITE)
            try { require(f.uidValidity==message.uidValidity) { "邮箱索引已变化，请刷新" }; f.getMessageByUID(message.uid)?.setFlag(Flags.Flag.SEEN,true); dao.setUnread(message.id,false) } finally { f.close(false) }
        }
    }
    override suspend fun download(id: String): Attachment = withContext(Dispatchers.IO) {
        downloadLocks[(id.hashCode() and Int.MAX_VALUE)%downloadLocks.size].withLock { downloadAttachment(id) }
    }
    private suspend fun downloadAttachment(id: String): Attachment {
        val att=requireNotNull(dao.attachment(id)) { "附件已不存在，请刷新邮件" }
        if(att.localPath.isNotEmpty() && File(att.localPath).exists()) return att
        require(att.size<=MAX_ATTACHMENT_BYTES) { "单附件不能超过 20 MB" }
        val m=requireNotNull(dao.message(att.messageId)); val a=requireNotNull(dao.account(m.accountId))
        val dir=File(filesDir,"attachments/${a.id}").apply { mkdirs() }
        val target=File(dir,"${att.id}.${att.name.substringAfterLast('.',"bin").filter { it.isLetterOrDigit() }.take(10)}")
        val temp=File(dir,"${att.id}.part")
        try {
            connect(a).use { store -> val f=store.getFolder(m.folder) as IMAPFolder; f.open(Folder.READ_ONLY)
                try {
                    require(f.uidValidity==m.uidValidity) { "邮件索引已变化，请刷新" }
                    var part: Part=requireNotNull(f.getMessageByUID(m.uid)) { "邮件已被删除" }
                    if(att.partPath.isNotEmpty()) for(index in att.partPath.split('.')) part=(part.content as Multipart).getBodyPart(index.toInt())
                    part.inputStream.use { input -> temp.outputStream().use { out ->
                        val buf=ByteArray(8192); var bytes=0L
                        while(true) { coroutineContext.ensureActive(); val n=input.read(buf); if(n<0) break; bytes+=n; require(bytes<=MAX_ATTACHMENT_BYTES) { "单附件不能超过 20 MB" }; out.write(buf,0,n) }
                    } }
                } finally { f.close(false) }
            }
            check(temp.renameTo(target)) { "无法保存附件" }
            return att.copy(localPath=target.absolutePath,size=target.length()).also { updated ->
                db.withTransaction {
                    if(dao.account(a.id)==null || dao.attachment(id)==null) { target.delete(); error("邮箱或附件已被删除") }
                    dao.putAttachments(listOf(updated))
                }
            }
        } finally { temp.delete() }
    }
    override suspend fun saveDraft(draft: Draft): Draft = db.withTransaction {
        val old=dao.draft(draft.id)
        require(old?.status !in listOf("SENDING","UNKNOWN","SENT")) { "此邮件已发送或发送状态待核实，请先核对" }
        require(old==null || old.revision==draft.revision) { "草稿已被修改，请重新拟写" }
        require(old!=null || draft.revision==0L) { "草稿已删除，不能覆盖或恢复旧版本" }
        val saved=draft.copy(revision=(old?.revision ?: 0)+1,status="DRAFT",error="",updatedAt=System.currentTimeMillis())
        dao.putDraft(saved); saved
    }
    override suspend fun send(draftId: String, confirmedRevision: Long): Draft = withContext(Dispatchers.IO) {
        val pair=db.withTransaction {
            val draft=requireNotNull(dao.draft(draftId))
            require(draft.revision==confirmedRevision && draft.status in listOf("DRAFT","FAILED")) { "草稿已变化或正在发送，请重新确认" }
            require(dao.attempt(draftId,confirmedRevision)==null) { "该草稿版本已有发送记录，请先核对" }
            val attempt=SendAttempt(draftId=draftId,revision=draft.revision,messageId="<${newId()}@mailpilot.local>")
            dao.insertAttempt(attempt); dao.putDraft(draft.copy(status="SENDING",error="")); draft to attempt
        }
        val draft=pair.first; val attempt=pair.second; var enteredSend=false
        try {
            val a=requireNotNull(dao.account(draft.accountId)) { "发件账号已删除" }
            val review=DraftReviewState.content(draft); require(review.canSend) { review.label }
            val session=session(a)
            val mime=object: MimeMessage(session) { override fun updateMessageID() { setHeader("Message-ID",attempt.messageId) } }
            mime.setFrom(InternetAddress(a.email,a.displayName.ifBlank { a.label },"UTF-8"))
            for((type,value) in listOf(Message.RecipientType.TO to draft.to,Message.RecipientType.CC to draft.cc,Message.RecipientType.BCC to draft.bcc)) {
                if(value.isNotBlank()) mime.setRecipients(type,InternetAddress.parse(value,true).onEach { it.validate() })
            }
            require(!draft.subject.contains('\r') && !draft.subject.contains('\n')) { "主题不能包含换行" }
            mime.setSubject(draft.subject,"UTF-8"); mime.sentDate=Date()
            if(draft.inReplyTo.isNotBlank()) mime.setHeader("In-Reply-To",draft.inReplyTo.replace(Regex("[\\r\\n]"),""))
            if(draft.references.isNotBlank()) mime.setHeader("References",draft.references.replace(Regex("[\\r\\n]")," "))
            val files=JsonCodec.files(draft.filesJson)
            if(files.isEmpty()) mime.setText(draft.body,"UTF-8") else {
                val mp=MimeMultipart("mixed"); mp.addBodyPart(MimeBodyPart().apply { setText(draft.body,"UTF-8") })
                var total=0L
                for(file in files) {
                    val f=File(file.path); require(f.canonicalPath.startsWith(File(filesDir,"attachments").canonicalPath+File.separator)) { "附件路径无效" }
                    require(f.exists() && f.length()<=MAX_ATTACHMENT_BYTES) { "附件丢失或超过 20 MB：${file.name}" }
                    total+=f.length(); require(total<=MAX_ATTACHMENT_BYTES) { "单封邮件的附件总大小不能超过 20 MB" }
                    mp.addBodyPart(MimeBodyPart().apply { dataHandler=DataHandler(FileDataSource(f)); fileName=MimeUtility.encodeText(file.name,"UTF-8",null); disposition=Part.ATTACHMENT })
                }
                mime.setContent(mp)
            }
            mime.saveChanges(); coroutineContext.ensureActive()
            val transport=session.getTransport("smtp")
            try {
                transport.connect(a.smtpHost,a.smtpPort,a.username.ifBlank { a.email },secrets.decrypt(a.passwordCipher))
                dao.putAttempt(attempt.copy(status="SENDING")); enteredSend=true
                transport.sendMessage(mime,mime.allRecipients)
            } finally { runCatching { transport.close() } }
            val sent=draft.copy(status="SENT",error="",updatedAt=System.currentTimeMillis())
            withContext(kotlinx.coroutines.NonCancellable) { db.withTransaction { dao.putAttempt(attempt.copy(status="SENT")); dao.putDraft(sent) } }
            // SMTP delivery is already acknowledged. IMAP archival failure never causes a resend.
            val archiveIssue=try { saveSentCopy(a,mime); "" } catch(_: Exception) { "邮件已发送，但未能保存服务器已发送副本。本地已保留发送记录。" }
            sent.copy(error=archiveIssue).also { withContext(kotlinx.coroutines.NonCancellable) { dao.putDraft(it) } }
        } catch(e: Exception) {
            val status=if(enteredSend) "UNKNOWN" else "FAILED"
            val detail=if(enteredSend) "服务器可能已接收全部或部分收件人。请先核对邮箱的已发送记录和收件情况，不要直接重发。" else friendlyMailError(e)
            val failed=draft.copy(status=status,error=detail,updatedAt=System.currentTimeMillis())
            withContext(kotlinx.coroutines.NonCancellable) { db.withTransaction { dao.putAttempt(attempt.copy(status=status,detail=detail)); dao.putDraft(failed) } }
            failed
        }
    }
    private fun saveSentCopy(account: MailAccount,message: MimeMessage) {
        connect(account).use { store ->
            val existing=store.defaultFolder.list("*").firstOrNull { f ->
                (f as? IMAPFolder)?.attributes?.any { it.equals("\\Sent",true) }==true || f.name.lowercase() in listOf("sent","sent messages","sent items","已发送")
            }
            val folder=existing ?: store.getFolder("Sent").also { if(!it.exists()) it.create(Folder.HOLDS_MESSAGES) }
            folder.open(Folder.READ_WRITE)
            try {
                if(folder.search(HeaderTerm("Message-ID",message.messageID)).isEmpty()) {
                    val copy=MimeMessage(message).apply { removeHeader("Bcc"); setFlag(Flags.Flag.SEEN,true) }
                    folder.appendMessages(arrayOf(copy))
                }
            } finally { folder.close(false) }
        }
    }
}

fun friendlyMailError(e: Throwable): String = when(e) {
    is AuthenticationFailedException -> "邮箱认证失败，请检查授权码及 IMAP/SMTP 开关"
    is java.net.UnknownHostException -> "无法找到服务器，请检查地址和网络"
    is javax.net.ssl.SSLException -> "TLS 连接失败，请检查服务器证书和加密方式"
    is java.net.SocketTimeoutException -> "连接超时，请检查网络后重试"
    else -> e.message?.take(300) ?: "邮件操作失败，请检查网络与配置"
}

object MimeReader {
    data class Parsed(val plain: String, val html: String, val files: List<Attachment>)
    fun parse(message: Part,id: String,readText: Boolean=true): Parsed {
        val plain=StringBuilder(); val html=StringBuilder(); val files=mutableListOf<Attachment>(); var parts=0; var textBytes=0
        fun visit(part: Part,path: String,depth: Int) {
            require(depth<=16 && ++parts<=500) { "邮件结构过于复杂" }
            val name=part.fileName?.let { runCatching { MimeUtility.decodeText(it) }.getOrDefault(it) }
            if(part.disposition.equals(Part.ATTACHMENT,true) || name!=null || (part.isMimeType("image/*"))) {
                val safeName=(name ?: "图片-${files.size+1}.${part.contentType.substringAfter('/').substringBefore(';')}").replace(Regex("[\\\\/\\r\\n]"),"_")
                files+=Attachment(stableId("$id|$path"),id,safeName,part.contentType.substringBefore(';').lowercase(),part.size.toLong(),path)
            } else if(part.isMimeType("multipart/*")) {
                val mp=part.content as Multipart
                for(i in 0 until mp.count) visit(mp.getBodyPart(i),if(path.isBlank()) "$i" else "$path.$i",depth+1)
            } else if(readText && (part.isMimeType("text/plain") || part.isMimeType("text/html"))) {
                val charset=runCatching { Charset.forName(ContentType(part.contentType).getParameter("charset") ?: "UTF-8") }.getOrDefault(Charsets.UTF_8)
                val text=part.inputStream.use { String(it.readLimited(2L*1024*1024),charset) }
                textBytes+=text.length; require(textBytes<=4*1024*1024) { "邮件正文内容过大，请使用邮箱原生客户端查看" }
                if(part.isMimeType("text/html")) html.append(text).append('\n') else plain.append(text).append('\n')
            }
        }
        visit(message,"",0)
        val safe=Jsoup.clean(html.toString(),Safelist.relaxed().removeTags("img","video","audio","iframe","form","input").removeAttributes(":all","style","background"))
        return Parsed(plain.toString().trim(),safe,files)
    }
}
