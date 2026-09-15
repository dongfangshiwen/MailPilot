package app.mailpilot.platform

import android.app.Application
import android.net.Uri
import android.provider.OpenableColumns
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import androidx.room.withTransaction
import app.mailpilot.MailPilotApp
import app.mailpilot.data.*
import app.mailpilot.ai.*
import org.json.JSONObject
import java.util.concurrent.atomic.AtomicReference
import app.mailpilot.mail.*
import app.mailpilot.attachments.*
import app.mailpilot.BridgeCodec
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import java.io.File

class MailCoordinator(application: Application): AndroidViewModel(application) {
    val graph=(application as MailPilotApp).graph
    private val _state=MutableStateFlow(MailState()); val state=_state.asStateFlow()
    private var mailboxJob: Job?=null; private var chatJob: Job?=null; private var workJob: Job?=null; private var analysisJob: Job?=null
    private var pageSize=50; private var cached=emptyList<MailMessage>(); private var searchIds: List<String>?=null
    private var workGeneration=0L; private var analysisGeneration=0L
    private var folderJob: Job?=null
    private var syncJob: Job?=null; private var searchJob: Job?=null
    private val selectionMutex=Mutex()
    private var materialJob: Job?=null
    private var conversationJob: Job?=null
    private var pdfJob: Job?=null
    private var drainingAnalysis: Job?=null
    init {
        viewModelScope.launch { graph.ready.await(); _state.update { it.copy(ready=true) } }
        viewModelScope.launch { graph.dao.accounts().collect { list -> _state.update { it.copy(accounts=list) }; resolveAccount() } }
        viewModelScope.launch { graph.dao.models().collect { list -> graph.preferences.ensureContextModes(list); _state.update { it.copy(models=list) } } }
        viewModelScope.launch { graph.preferences.flow.collect { prefs -> _state.update { it.copy(settings=prefs) }; resolveAccount() } }
        viewModelScope.launch { graph.dao.drafts().collect { drafts -> _state.update { it.copy(drafts=drafts) } } }
        viewModelScope.launch { graph.dao.conversationHeaders().distinctUntilChanged().collect { _state.update { it.copy(historyRevision=it.historyRevision+1) } } }
        observeChat()
    }
    private fun resolveAccount() {
        val s=_state.value; val id=s.accounts.firstOrNull { it.id==s.settings.accountId }?.id ?: s.accounts.firstOrNull()?.id.orEmpty()
        if(id==s.activeAccount) return
        val keepChat=s.selection.isEmpty() && s.currentConversation?.takeIf { it.id==s.conversationId }?.accountId.orEmpty().isBlank()
        workGeneration++; workJob?.cancel(); cancelAnalysis(); pageSize=50; searchIds=null; cached=emptyList(); searchJob?.cancel()
        folderJob?.cancel(); dismissPdf()
        _state.update { it.copy(activeAccount=id,folder="INBOX",folders=listOf("INBOX"),foldersLoading=false,foldersError="",messages=emptyList(),selection=emptyList(),detail=null,query="",editor=null,busy=false,status="",syncing=false,syncLabel="",searching=false) }
        // Opening the app restores local folders only; mail sync stays manual.
        folderJob=viewModelScope.launch {
            val names=graph.dao.cachedFolders(id)
            _state.update { if(it.activeAccount==id && names.isNotEmpty()) it.copy(folders=names) else it }
        }
        if(!keepChat) resetConversation()
        observeMailbox()
        syncJob?.cancel()
        syncJob=viewModelScope.launch {
            var observedRunning=""
            graph.sync.observe(id).collect { progress ->
                if(progress.running) observedRunning=progress.taskId
                val notice=progress.outcome.takeIf { !progress.running && observedRunning==progress.taskId }
                if(notice!=null) observedRunning=""
                val names=graph.dao.cachedFolders(id)
                _state.update { if(it.activeAccount==id) it.copy(syncing=progress.running,syncLabel=progress.label,
                    folders=names.ifEmpty { it.folders },notice=notice ?: it.notice) else it }
                updateSelectionLabels()
            }
        }
    }
    private fun observeMailbox() {
        mailboxJob?.cancel(); val s=_state.value
        if(s.activeAccount.isBlank()) return
        mailboxJob=viewModelScope.launch { graph.dao.messages(s.activeAccount,s.folder).collect { rows ->
            cached=rows; publishMessages()
            val detail=rows.firstOrNull { it.id==_state.value.detail?.id }
            if(detail!=null) {
                val files=graph.dao.attachments(detail.id)
                _state.update { if(it.detail?.id==detail.id) it.copy(detail=detail,detailAttachments=files) else it }
            }
        } }
    }
    private fun publishMessages() {
        val s=_state.value
        val visible=if(searchIds!=null) searchIds!!.mapNotNull { id -> cached.firstOrNull { it.id==id } } else cached.filter { !s.unreadOnly || it.unread }.filter { s.query.isBlank() || it.subject.contains(s.query,true) || it.sender.contains(s.query,true) }.take(pageSize)
        _state.update { it.copy(messages=visible) }
    }
    private fun observeChat() {
        chatJob?.cancel(); materialJob?.cancel(); val id=_state.value.conversationId
        conversationJob?.cancel()
        conversationJob=viewModelScope.launch { graph.dao.observeConversation(id).distinctUntilChanged().collect { conversation ->
            _state.update { if(it.conversationId==id) it.copy(currentConversation=conversation) else it }
        } }
        materialJob=viewModelScope.launch { graph.dao.materials(id).collect { rows ->
            _state.update { if(it.conversationId==id) it.copy(localMaterials=rows) else it }; updateSelectionLabels()
        } }
        chatJob=viewModelScope.launch { graph.dao.entries(id).collect { rows ->
            val turns=graph.dao.turns(id)
            val traces=turns.mapNotNull { turn -> AgentRunCheckpoint.from(turn).data.optJSONObject("reasoningTrace")?.let { turn.id to ReasoningSnapshot.from(it) } }.toMap()
            val editable=turns.mapNotNull { turn ->
                org.json.JSONObject(turn.requestJson).optString("userEntryId").takeIf { it.isNotBlank() }
                    ?: rows.takeWhile { it.id!=turn.id }.lastOrNull { it.role=="user" }?.id
            }.toSet()
            _state.update { if(it.conversationId==id) it.copy(entries=ChatBranch.active(rows.map { e -> if(e.resultStatus=="running" && !(it.analyzing && it.responseId==e.id)) it.entries.firstOrNull { old -> old.id==e.id && old.resultStatus!="running" } ?: e else e }),editableMessageIds=editable,reasoningRecords=traces.mapValues { (key,value) -> it.reasoningRecords[key]?.takeIf { old -> old.attemptId==value.attemptId && old.revision>value.revision } ?: value },
                entryVersionCounts=rows.filter { e -> e.role=="user" }.associate { e -> e.id to ChatBranch.versions(e,rows).size }) else it }
        } }
    }
    private fun resetConversation(keepCards: Boolean=false) { cancelAnalysis(); _state.update { it.copy(recheckAssets=emptySet(),conversationId=newId(),currentConversation=null,localMaterials=emptyList(),entries=emptyList(),entryVersionCounts=emptyMap(),streaming="",resultCards=if(keepCards) it.resultCards else emptyList(),source=null) }; observeChat(); updateSelectionLabels() }
    private fun updateSelectionLabels() { val snapshot=_state.value; val selection=snapshot.selection; viewModelScope.launch {
        val labels=selection.flatMap { selected -> listOfNotNull(graph.dao.message(selected.messageId)?.subject)+selected.attachmentIds.mapNotNull { id -> graph.dao.attachment(id)?.let { a -> a.name+(selected.pdfPages[id]?.let { "（${it.size} 页）" } ?: "") } } }
        val groups=selection.mapNotNull { selected -> graph.dao.message(selected.messageId)?.let { message ->
            val files=graph.dao.attachments(message.id)
            mapOf<String,Any?>("messageId" to message.id,"subject" to message.subject,"pending" to (message.bodyState!="READY" || files.size<message.attachmentCount),"attachments" to files.map { a -> BridgeCodec.attachment(a)+mapOf("selected" to (a.id in selected.attachmentIds),"defaultPages" to (a.id in selected.defaultPdfIds),"pages" to selected.pdfPages[a.id].orEmpty()) })
        } }
        val budget=selectionSummary(snapshot)
        if(_state.value.selection==selection && _state.value.conversationId==snapshot.conversationId && _state.value.localMaterials==snapshot.localMaterials) _state.update { it.copy(selectionLabels=labels,selectionGroups=groups,selectionBudget=budget) }
    } }
    suspend fun selectionSummary(s: MailState=_state.value): Map<String,Any> {
        val missing=mutableListOf<String>()
        val files=s.selection.flatMap { selected -> selected.attachmentIds.mapNotNull { id ->
            graph.dao.attachment(id).also { if(it==null) missing+="所选附件已失效，请取消该附件或重新选择邮件" }
        } }+s.localMaterials.filter { it.selected }.map { it.attachment() }
        val pages=s.selection.flatMap { it.pdfPages.entries }.associate { it.toPair() }+s.localMaterials.filter { it.selected }.associate { it.id to it.pages() }
        val summary=SelectionPolicy.summary(files,pages,s.selection.flatMap { it.defaultPdfIds }.toSet())
        return if(missing.isEmpty()) summary else summary+mapOf("blocked" to true,"issues" to ((summary["issues"] as List<*>)+missing.distinct()))
    }
    suspend fun refreshSelectionSummary(): Map<String,Any> { updateSelectionLabels(); return selectionSummary() }
    private fun sameSelectionScope(s: MailState)=_state.value.conversationId==s.conversationId && _state.value.activeAccount==s.activeAccount
    // Await each selection write; a later clear/toggle must not be overwritten by an older save.
    private suspend fun changeSelection(block: suspend (MailState)->Unit) {
        val requested=_state.value
        selectionMutex.withLock { if(sameSelectionScope(requested)) block(_state.value) }
    }
    private suspend fun commitSelection(s: MailState,selection: List<Selection>,clearLocal: Boolean=false) {
        if(!sameSelectionScope(s)) return
        graph.db.withTransaction {
            graph.dao.updateSelection(s.conversationId,if(selection.isNotEmpty()) s.activeAccount else "",s.folder,JsonCodec.selections(selection))
            if(clearLocal) graph.dao.deselectMaterials(s.conversationId)
        }
        _state.update { if(sameSelectionScope(s)) it.copy(selection=selection,
            localMaterials=if(clearLocal) it.localMaterials.map { m -> m.copy(selected=false) } else it.localMaterials,
            recheckAssets=if(clearLocal) emptySet() else it.recheckAssets) else it }
        updateSelectionLabels()
    }
    private fun operation(label: String,block: suspend ()->Unit) {
        if(_state.value.busy) { _state.update { it.copy(notice="请等待当前操作完成") }; return }
        val generation=++workGeneration
        workJob=viewModelScope.launch {
            _state.update { it.copy(busy=true,status=label,error=null) }
            try { graph.ready.await(); block() } catch(e: CancellationException) { throw e } catch(e: Exception) { _state.update { if(generation==workGeneration) it.copy(error=friendlyMailError(e)) else it } }
            finally { if(generation==workGeneration) _state.update { it.copy(busy=false,status=if(it.analyzing) it.status else "") } }
        }
    }
    fun clearFeedback() { _state.update { it.copy(error=null,notice=null) } }
    fun dismissNotice(value: String) { _state.update { if(it.notice==value) it.copy(notice=null) else it } }
    fun tab(index: Int) { _state.update { it.copy(tab=index,detail=null,editor=null) } }
    fun back() { dismissPdf(); _state.update { it.copy(detail=null,editor=null,sendPreview=null,source=null) } }
    fun account(id: String) { viewModelScope.launch { graph.preferences.set("account",id) } }
    fun loadFolders() {
        val id=_state.value.activeAccount
        if(id.isBlank() || _state.value.foldersLoading) return
        folderJob?.cancel()
        _state.update { it.copy(foldersLoading=true,foldersError="") }
        folderJob=viewModelScope.launch {
            try {
                graph.ready.await()
                val names=graph.mail.folders(id)
                _state.update { if(it.activeAccount==id) it.copy(folders=names.ifEmpty { listOf("INBOX") }) else it }
            } catch(e: CancellationException) { throw e }
              catch(e: Exception) { _state.update { if(it.activeAccount==id) it.copy(foldersError=friendlyMailError(e)) else it } }
            finally { _state.update { if(it.activeAccount==id) it.copy(foldersLoading=false) else it } }
        }
    }
    fun folder(value: String) { pageSize=50; searchIds=null; cached=emptyList(); searchJob?.cancel(); _state.update { it.copy(folder=value,query="",messages=emptyList(),searching=false,detail=null) }; observeMailbox() }
    fun refresh(more: Boolean=false) {
        val s=_state.value; if(s.activeAccount.isBlank()) return
        if(s.syncing) { _state.update { it.copy(notice="该账号正在同步，可继续浏览或聊天") }; return }
        if(more && s.query.isNotBlank()) { search(s.query,s.unreadOnly,true); return }
        val offset=if(more) minOf(pageSize,cached.size) else 0
        if(more) pageSize+=50 else { pageSize=maxOf(pageSize,50); searchIds=null }
        publishMessages()
        graph.sync.start(s.activeAccount,s.folder,more,offset)
        _state.update { it.copy(notice=if(more) "正在后台加载更早的 50 封邮件" else "已开始后台同步各文件夹，可继续使用") }
    }
    fun cancelSync() { graph.sync.cancel(_state.value.activeAccount) }
    fun search(query: String,unread: Boolean=_state.value.unreadOnly,more: Boolean=false,remote: Boolean=true) {
        searchJob?.cancel(); val s=_state.value; val keyword=query.trim()
        val offset=if(more) searchIds?.size ?: 0 else 0
        if(!more) searchIds=null
        _state.update { it.copy(query=keyword,unreadOnly=unread,searching=false) }; publishMessages()
        if(!remote || keyword.isBlank() || s.activeAccount.isBlank()) return
        searchJob=viewModelScope.launch {
            _state.update { it.copy(searching=true) }
            try {
                val found=graph.mail.load(s.activeAccount,s.folder,MailQuery(keyword=keyword,unreadOnly=unread,offset=offset,limit=50))
                if(_state.value.activeAccount==s.activeAccount && _state.value.folder==s.folder && _state.value.query==keyword) {
                    searchIds=((if(more) searchIds.orEmpty() else emptyList())+found.map { it.id }).distinct(); publishMessages()
                }
            } catch(e: CancellationException) { throw e } catch(e: Exception) { _state.update { it.copy(notice="服务器搜索未完成，本地结果已保留。${friendlyMailError(e)}") } }
            finally { _state.update { it.copy(searching=false) } }
        }
    }
    suspend fun toggleMessage(id: String)=changeSelection { before ->
        val message=graph.dao.message(id) ?: return@changeSelection
        val files=graph.dao.attachments(id)
        if(!sameSelectionScope(before) || before.activeAccount!=message.accountId) return@changeSelection
        val list=before.selection.toMutableList(); if(list.any { it.messageId==id }) list.removeAll { it.messageId==id } else list+=SelectionPolicy.defaults(id,files)
        commitSelection(before,list)
    }
    suspend fun selectMessageFiles(id: String,bodyOnly: Boolean)=changeSelection { before ->
        val message=graph.dao.message(id) ?: return@changeSelection; val files=graph.dao.attachments(id)
        if(!sameSelectionScope(before) || before.activeAccount!=message.accountId) return@changeSelection
        setSelection(before,if(bodyOnly) Selection(id) else SelectionPolicy.defaults(id,files))
    }
    suspend fun clearSelection()=changeSelection { commitSelection(it,emptyList(),clearLocal=true) }
    fun openMessage(message: MailMessage) { viewModelScope.launch {
        val attachments=graph.dao.attachments(message.id); _state.update { it.copy(detail=message,detailAttachments=attachments,editor=null) }
        if(message.unread) try { graph.mail.markRead(message); _state.update { if(it.detail?.id==message.id) it.copy(detail=it.detail?.copy(unread=false)) else it } }
            catch(e: CancellationException) { throw e } catch(_: Exception) { _state.update { it.copy(notice="已打开缓存邮件，未读标记暂未更新") } }
    } }
    suspend fun selectAttachment(att: Attachment)=changeSelection { s ->
        val message=graph.dao.message(att.messageId) ?: return@changeSelection
        require(message.accountId==s.activeAccount) { "附件不属于当前邮箱" }
        val existing=s.selection.firstOrNull { it.messageId==att.messageId } ?: Selection(att.messageId)
        setSelection(s,SelectionPolicy.toggle(existing,att))
    }
    private suspend fun setSelection(s: MailState,value: Selection)=commitSelection(s,s.selection.filterNot { it.messageId==value.messageId }+value)
    suspend fun choosePdf(pages: List<Int>,token: String?=null)=changeSelection { s ->
        val choice=s.pdfChoice ?: return@changeSelection
        if(token!=null && token!=choice.token) return@changeSelection
        if(choice.loading || choice.error.isNotBlank()) return@changeSelection
        if(pages.distinct().size>20 || pages.any { it !in 0 until choice.count }) { _state.update { it.copy(notice="每份 PDF 最多选择 20 页") }; return@changeSelection }
        if(choice.attachment.messageId.isBlank()) {
            val m=graph.dao.material(choice.attachment.id) ?: return@changeSelection
            require(m.conversationId==s.conversationId) { "文件不属于当前会话" }
            if(!sameSelectionScope(s) || _state.value.pdfChoice?.token!=choice.token) return@changeSelection
            val updated=m.copy(selected=pages.isNotEmpty(),pagesJson=org.json.JSONArray(pages.distinct().sorted()).toString())
            graph.dao.putMaterial(updated)
            _state.update { if(sameSelectionScope(s)) it.copy(localMaterials=it.localMaterials.map { old -> if(old.id==m.id) updated else old }) else it }
            if(_state.value.pdfChoice?.token==choice.token) dismissPdf()
            updateSelectionLabels(); return@changeSelection
        }
        val message=graph.dao.message(choice.attachment.messageId) ?: return@changeSelection
        require(message.accountId==s.activeAccount) { "附件不属于当前邮箱" }
        if(!sameSelectionScope(s) || _state.value.pdfChoice?.token!=choice.token) return@changeSelection
        val existing=s.selection.firstOrNull { it.messageId==choice.attachment.messageId }
        if(existing==null && pages.isEmpty()) { dismissPdf(); return@changeSelection }
        val old=existing ?: Selection(choice.attachment.messageId)
        val id=choice.attachment.id
        setSelection(s,old.copy(attachmentIds=if(pages.isEmpty()) old.attachmentIds-id else (old.attachmentIds+id).distinct(),pdfPages=if(pages.isEmpty()) old.pdfPages-id else old.pdfPages+(id to pages.distinct().sorted()),defaultPdfIds=old.defaultPdfIds-id))
        if(_state.value.pdfChoice?.token==choice.token) dismissPdf()
    }
    fun editPdf(att: Attachment) {
        pdfJob?.cancel(); val s=_state.value; val token=newId()
        _state.update { it.copy(pdfChoice=PdfChoice(att,0,emptyList(),token,loading=true)) }
        pdfJob=viewModelScope.launch {
            try {
                val downloaded=localAttachment(att.id); val count=graph.attachments.pdfCount(File(downloaded.localPath))
                val local=s.localMaterials.firstOrNull { it.id==att.id }; val chosen=s.selection.firstOrNull { it.messageId==att.messageId }
                val pages=local?.pages()?.takeIf { it.isNotEmpty() } ?: chosen?.pdfPages?.get(att.id) ?: (0 until minOf(count,10)).toList()
                _state.update { if(it.pdfChoice?.token==token && it.conversationId==s.conversationId) it.copy(pdfChoice=PdfChoice(downloaded,count,pages,token)) else it }
            } catch(e: CancellationException) { throw e } catch(e: Exception) { _state.update { if(it.pdfChoice?.token==token) it.copy(pdfChoice=PdfChoice(att,0,emptyList(),token,error="${att.name}：${e.message ?: "无法读取 PDF"}")) else it } }
        }
    }
    fun dismissPdf() { pdfJob?.cancel(); pdfJob=null; _state.update { it.copy(pdfChoice=null) } }
    suspend fun pdfThumbnail(id: String,page: Int,token: String): ByteArray {
        val choice=_state.value.pdfChoice
        require(choice!=null && choice.token==token && choice.attachment.id==id && !choice.loading && page in 0 until choice.count) { "页码选择已关闭" }
        val file=graph.attachments.thumbnailPdf(File(choice.attachment.localPath),page)
        require(_state.value.pdfChoice?.token==token) { "页码选择已关闭" }
        return withContext(Dispatchers.IO) { file.readBytes() }
    }
    // Opening the preview only changes navigation. sourceInfo downloads this one
    // attachment asynchronously; listing or selecting attachments never does.
    fun preview(att: Attachment) { _state.update { it.copy(source=SourceChunk(messageId=att.messageId,attachmentId=att.id,title=att.name,location="附件",kind="attachment-preview")) } }
    fun showSource(source: SourceChunk?) { _state.update { it.copy(source=source) } }
    fun draftFromAnswer(id: String,options: ChatRequestOptions=ChatRequestOptions()) {
        if(_state.value.analyzing || _state.value.busy) return
        val conversation=_state.value.conversationId
        viewModelScope.launch {
            val entry=graph.dao.history(conversation).firstOrNull { it.id==id && it.role=="assistant" && it.resultStatus=="complete" && !it.text.startsWith("回答未完成") && !it.text.startsWith("本次回答已停止") } ?: return@launch
            if(conversation!=_state.value.conversationId) return@launch
            analyze("将这条回答写成邮件",composeMode=true,targetAnswerId=entry.id,options=options)
        }
    }
    fun analyze(question: String,composeMode: Boolean=false,redraftId: String="",options: ChatRequestOptions=ChatRequestOptions(),targetAnswerId: String="",inputSnapshot: MailState?=null,retryEntryId: String="",editEntryId: String="",frozenTurn: TurnSnapshot?=null) {
        if(_state.value.analyzing || _state.value.busy) return
        val s=inputSnapshot ?: _state.value
        if(s.conversationId!=_state.value.conversationId || s.activeAccount!=_state.value.activeAccount) return
        if(editEntryId.isBlank() && retryEntryId.isBlank() && !composeMode && ChatSendGate.isConfirmation(question) && s.entries.lastOrNull()?.draftPreviewJson?.isNotBlank()==true) {
            confirmChatSend(s.entries.last().id,question); return
        }
        fun configured(p: ModelProfile)=ModelOutputPolicy.resolve(ModelContextPolicy.resolve(p,s.settings.contextModes[p.id]),s.settings.outputModes[p.id])
        val model=(s.models.firstOrNull { it.id==s.settings.textModelId } ?: s.models.firstOrNull())?.let(::configured)?.let(options::apply)
        if(model==null) { _state.update { it.copy(error="请先在设置中添加模型",tab=3) }; return }
        val vision=s.models.firstOrNull { it.id==s.settings.visionModelId }?.let(::configured)
        // Only explicit UI actions bypass semantic action selection. Sending stays separately gated.
        val structuredCompose=composeMode
        val turnOptions=options.freeze(model).copy(fastCompression=s.settings.fastCompression,webSearch=options.webSearch && !composeMode && redraftId.isBlank() && targetAnswerId.isBlank())
        val generation=++analysisGeneration
        val previousJob=analysisJob ?: drainingAnalysis
        analysisJob=viewModelScope.launch {
            previousJob?.cancelAndJoin()
            val partial=AtomicReference("")
            val responseId=retryEntryId.ifBlank { newId() }; val attemptId=newId()
            val previousReasoning=AgentRunCheckpoint.from(graph.dao.turn(responseId)).data.optJSONObject("reasoningTrace")?.let(ReasoningSnapshot::from)
                ?: s.reasoningRecords[responseId] ?: s.entries.firstOrNull { it.id==responseId }?.let(ReasoningSnapshot::legacy)
            val reasoning=ReasoningTrace(attemptId=attemptId,previous=previousReasoning)
            val draftPartial=AtomicReference(DraftPartial()); val stage=AtomicReference("preparing"); val diagnostics=AtomicReference(JSONObject())
            var saver: Job?=null; var committed=false; var entryTime=System.currentTimeMillis()
            fun extra()=JSONObject().put("draftPartial",draftPartial.get().json()).put("stage",stage.get()).put("diagnostics",diagnostics.get()).put("visionProgress",JSONObject(_state.value.visionProgress))
            fun publishReasoning() { val value=reasoning.snapshot(); _state.update { if(generation==analysisGeneration && it.conversationId==s.conversationId) it.copy(reasoning=value) else it } }
            fun reply(text: String,sources: String="[]")=reasoning.snapshot().attach(ChatEntry(id=responseId,conversationId=s.conversationId,role="assistant",text=text,sourcesJson=sources,failureJson=extra().toString(),createdAt=entryTime))
            _state.update { it.copy(tab=1,detail=null,analyzing=true,streaming="",error=null,resultCards=emptyList(),responseId=responseId,reasoning=reasoning.snapshot(),draftPartial=DraftPartial(),agentStage="preparing",visionProgress=emptyMap()) }
            try {
                graph.ready.await()
                val rawHistory=graph.dao.history(s.conversationId)
                // The assistant row must stay after its user bubble, including periodic saves.
                entryTime=rawHistory.firstOrNull { it.id==responseId }?.createdAt ?: maxOf(entryTime,(rawHistory.maxOfOrNull { it.createdAt } ?: 0)+2)
                val activeHistory=ChatBranch.active(rawHistory)
                val cutoff=when {
                    editEntryId.isNotBlank() -> activeHistory.indexOfFirst { it.id==editEntryId }.also { require(it>=0) { "该问题已更新，请重新选择" } }
                    retryEntryId.isNotBlank() -> activeHistory.indexOfFirst { it.id==retryEntryId }.let { i -> activeHistory.take(i).indexOfLast { it.role=="user" } }.coerceAtLeast(0)
                    else -> activeHistory.size
                }
                val history=activeHistory.take(cutoff)
                selectionMutex.withLock {
                    val old=graph.dao.conversation(s.conversationId)
                    val currentSelection=_state.value.takeIf { it.conversationId==s.conversationId } ?: s
                    graph.dao.putConversation((old ?: Conversation(id=s.conversationId,title=question.take(30))).copy(
                        selectionJson=JsonCodec.selections(currentSelection.selection),accountId=old?.accountId?.ifBlank { s.activeAccount } ?: s.activeAccount,folder=currentSelection.folder))
                }
                val priorTurn=if(retryEntryId.isNotBlank()) graph.dao.turn(retryEntryId) ?: frozenTurn else frozenTurn
                val userEntryId=if(retryEntryId.isNotBlank()) org.json.JSONObject(priorTurn?.requestJson ?: "{}").optString("userEntryId") else newId()
                val turnRequest=org.json.JSONObject().put("recheckAssets",org.json.JSONArray(s.recheckAssets.toList())).put("question",question).put("composeMode",structuredCompose).put("redraftId",redraftId).put("targetAnswerId",targetAnswerId).put("userEntryId",userEntryId)
                priorTurn?.let { org.json.JSONObject(it.requestJson).optJSONObject("resolvedPdfPages") }?.let { turnRequest.put("resolvedPdfPages",it) }
                if(retryEntryId.isNotBlank()) priorTurn?.let { JSONObject(it.requestJson).optJSONArray("recheckAssets") }?.let { turnRequest.put("recheckAssets",it) }
                if(retryEntryId.isNotBlank()) priorTurn?.let { JSONObject(it.requestJson).optJSONObject("agentRun") }?.let { turnRequest.put("agentRun",it) }
                if(!turnRequest.has("agentRun")) turnRequest.put("agentRun",JSONObject().put("version",1).put("phase","preparing"))
                graph.db.withTransaction {
                    if(editEntryId.isNotBlank()) graph.dao.updateContext(s.conversationId,s.activeAccount,"","",0)
                    val number=if(retryEntryId.isNotBlank()) priorTurn?.number ?: 1 else (graph.dao.turns(s.conversationId).maxOfOrNull { it.number } ?: 0)+1
                    graph.dao.putTurn(TurnSnapshot(responseId,s.conversationId,s.activeAccount,s.folder,JsonCodec.selections(s.selection),number,turnOptions.json(),org.json.JSONArray(s.localMaterials.filter { it.selected }.map { it.fields() }).toString(),turnRequest.toString()))
                    if(retryEntryId.isBlank()) graph.dao.touchConversation(s.conversationId,entryTime-1)
                    if(retryEntryId.isBlank()) graph.dao.putEntry(ChatEntry(id=userEntryId,conversationId=s.conversationId,role="user",text=question,createdAt=entryTime-1,action=if(editEntryId.isNotBlank()) "edit_user" else if(targetAnswerId.isNotBlank()) "draft_answer" else "",targetAnswerId=editEntryId.ifBlank { targetAnswerId }))
                    graph.dao.putEntry(reply("").copy(resultStatus="running"))
                }
                RunTelemetry.begin(graph.dao,responseId,attemptId)
                _state.update { if(it.conversationId==s.conversationId) it.copy(recheckAssets=it.recheckAssets-s.recheckAssets) else it }
                saver=launch {
                    while(isActive) {
                        delay(1000)
                        AgentCheckpoints.update(graph.dao,responseId) { it.put("preview",draftPartial.get().json()).put("phase",stage.get()).put("diagnostics",diagnostics.get()).put("reasoningTrace",JSONObject(reasoning.snapshot().fields())) }
                        graph.dao.putEntry(reply(partial.get()).copy(resultStatus="running"))
                    }
                }
                val result=(if(retryEntryId.isNotBlank()) AgentResultCommitter.restored(graph.dao.turn(responseId)) else null) ?: graph.agent.run(s.activeAccount,s.folder,s.selection,question,model,vision,history,
                    onDelta={ delta ->
                        partial.updateAndGet { if(delta.isEmpty()) "" else it+delta }
                        val text=partial.get()
                        _state.update { if(generation==analysisGeneration && it.conversationId==s.conversationId) it.copy(streaming=text) else it }
                    },
                    onProgress={ label -> _state.update { if(generation==analysisGeneration && it.conversationId==s.conversationId) it.copy(status=label) else it } },onCards={ cards -> _state.update { if(generation==analysisGeneration && it.conversationId==s.conversationId) it.copy(resultCards=cards) else it } },conversationId=s.conversationId,
                    onThinking={ delta -> reasoning.append(delta); publishReasoning() },onThinkingDone={ reasoning.finish(); publishReasoning() },composeMode=structuredCompose,requestId=responseId,redraftId=redraftId,options=turnOptions,localMaterials=s.localMaterials.filter { it.selected },searchConfig=s.settings.search,targetAnswerId=targetAnswerId,
                    onEvent={ event -> when(event) {
                        is AgentEvent.ToolActivity -> { reasoning.activity(event); publishReasoning() }
                        is AgentEvent.RequestStarted -> { reasoning.begin(event.id,event.stage); publishReasoning() }
                        is AgentEvent.Stage -> { stage.set(event.name); _state.update { if(generation==analysisGeneration) it.copy(agentStage=event.name,status=event.label) else it } }
                        is AgentEvent.DraftPreview -> { draftPartial.set(event.value); _state.update { if(generation==analysisGeneration) it.copy(draftPartial=event.value) else it } }
                        is AgentEvent.VisionProgress -> _state.update { if(generation==analysisGeneration) it.copy(visionProgress=mapOf("cacheHits" to event.cacheHits,"uploadedImages" to event.uploadedImages,"batches" to event.batches,"reason" to event.reason,"preprocessingMs" to event.preprocessingMs,"mode" to event.mode,"imageRequests" to event.imageRequests,"pendingImages" to event.pendingImages)) else it }
                        is AgentEvent.Diagnostics -> diagnostics.set(event.value)
                        else -> Unit
                    } })
                saver?.cancelAndJoin()
                reasoning.end()
                AgentCheckpoints.update(graph.dao,responseId) { it.put("reasoningTrace",JSONObject(reasoning.snapshot().fields())).put("diagnostics",diagnostics.get()) }
                AgentResultCommitter.checkpoint(graph.dao,responseId,result)
                currentCoroutineContext().ensureActive()
                val draft=withContext(NonCancellable) { AgentResultCommitter(graph.db,graph.mail).commit(reply(result.text,JsonCodec.sources(result.sources)).copy(visionModel=result.visionModel),result).also { committed=true } }
                RunTelemetry.end(graph.dao,responseId,"complete")
                val completed=graph.dao.history(s.conversationId)
                _state.update { if(generation==analysisGeneration && it.conversationId==s.conversationId) it.copy(entries=ChatBranch.active(completed),reasoningRecords=it.reasoningRecords+(responseId to reasoning.snapshot()),reasoning=reasoning.snapshot()) else it }
                _state.update { if(generation==analysisGeneration) it.copy(streaming="",notice=if(draft!=null) "草稿已保存，可在聊天中确认发送" else null) else it }
            } catch(e: CancellationException) { saver?.cancel(); reasoning.end("stopped"); withContext(NonCancellable) { saver?.join(); if(!committed) { AgentCheckpoints.update(graph.dao,responseId) { it.put("phase","stopped").put("preview",draftPartial.get().json()).put("reasoningTrace",JSONObject(reasoning.snapshot().fields())) }; graph.dao.putEntry(reply(partial.get().let { if(it.isBlank()) "本次回答已停止。" else "$it\n\n> 已停止，以上是收到的部分回答。" }).copy(resultStatus="stopped")) } ; RunTelemetry.end(graph.dao,responseId,"stopped") }; throw e }
            catch(e: Exception) {
                if(committed) return@launch
                reasoning.end("interrupted")
                saver?.cancelAndJoin()
                val failure=app.mailpilot.ai.FailureInfo.from(e)
                // A local preflight can fail after another request finished. Do not
                // attribute that request's finish reason or timings to this failure.
                val failureDiagnostic=JSONObject(failure.diagnostics.toString())
                if(!failureDiagnostic.has("stage")) failureDiagnostic.put("stage",stage.get())
                if(!failureDiagnostic.has("requestId")) failureDiagnostic.put("requestId",responseId)
                if(!failureDiagnostic.has("model")) failureDiagnostic.put("model",failure.model.ifBlank { model.model })
                if(!failureDiagnostic.has("cause")) failureDiagnostic.put("cause",failure.type)
                if(failure.diagnostics.length()==0) failureDiagnostic.put("origin","workflow")
                diagnostics.set(failureDiagnostic)
                AgentCheckpoints.update(graph.dao,responseId) { it.put("phase","failed").put("preview",draftPartial.get().json()).put("diagnostics",diagnostics.get()).put("reasoningTrace",JSONObject(reasoning.snapshot().fields())) }
                RunTelemetry.end(graph.dao,responseId,"failed")
                graph.dao.putEntry(reply(partial.get().let { if(it.isBlank()) "回答未完成：${failure.message}" else "$it\n\n> 回答未完成：${failure.message}" })
                    .copy(resultStatus="failed",failureJson=JSONObject(failure.fields()).put("draftPartial",draftPartial.get().json()).put("stage",stage.get()).put("diagnostics",diagnostics.get()).toString(),visionModel=failure.model,action=if(failure.type=="search") "search_failed" else "analysis_failed"))
            }
            finally { saver?.cancel(); if(generation==analysisGeneration) withContext(NonCancellable) { val finalRows=graph.dao.history(s.conversationId); _state.update { if(it.conversationId==s.conversationId) it.copy(entries=ChatBranch.active(finalRows),reasoningRecords=it.reasoningRecords+(responseId to reasoning.snapshot()),historyRevision=it.historyRevision+1,analyzing=false,streaming="",status="",responseId="",reasoning=ReasoningSnapshot(),draftPartial=DraftPartial(),agentStage="") else it } } }
        }
    }
    private suspend fun editableTurn(id: String): Pair<ChatEntry,TurnSnapshot> {
        val state=_state.value
        require(!state.analyzing && !state.busy) { "请先停止当前回答再修改" }
        val all=ChatBranch.active(graph.dao.history(state.conversationId)); val index=all.indexOfFirst { it.id==id }
        val user=all.getOrNull(index)?.takeIf { it.role=="user" } ?: error("问题已变更，请重新选择")
        val turn=graph.dao.turns(state.conversationId).firstOrNull { org.json.JSONObject(it.requestJson).optString("userEntryId")==id }
            ?: all.drop(index+1).takeWhile { it.role!="user" }.firstNotNullOfOrNull { graph.dao.turn(it.id) }
            ?: error("这条消息没有可恢复的资料快照，请作为新问题发送")
        require(turn.accountId==state.activeAccount) { "请切换回原邮箱后修改" }
        return user to turn
    }
    suspend fun prepareMessageEdit(id: String): String {
        val (user,turn)=editableTurn(id)
        val selected=JsonCodec.selections(turn.selectionJson)
        val count=selected.size
        val files=selected.sumOf { it.attachmentIds.size }+org.json.JSONArray(turn.localJson).length()
        return org.json.JSONObject().put("id",id).put("text",user.text).put("options",org.json.JSONObject(turn.optionsJson))
            .put("materialLabel","沿用原问题资料 · $count 封邮件 · $files 个附件").toString()
    }
    suspend fun editMessage(id: String,question: String,options: ChatRequestOptions) {
        require(question.isNotBlank() && question.length<=12000) { "请输入 1–12000 字的问题" }
        val current=_state.value; val (_,turn)=editableTurn(id)
        require(current.models.isNotEmpty()) { "请先添加模型，修改内容尚未提交" }
        val locals=org.json.JSONArray(turn.localJson)
        val materials=(0 until locals.length()).map { n -> val j=locals.getJSONObject(n)
            requireNotNull(graph.dao.material(j.getString("id"))) { "原问题的手机资料已清理，请重新选择后提问" }.copy(selected=true,pagesJson=j.optJSONArray("pages")?.toString() ?: "[]") }
        val snapshot=current.copy(selection=JsonCodec.selections(turn.selectionJson),localMaterials=materials,folder=turn.folder)
        SelectionPolicy.requireAllowed(selectionSummary(snapshot))
        require(_state.value.conversationId==current.conversationId && _state.value.activeAccount==current.activeAccount && !_state.value.analyzing && !_state.value.busy) { "会话已变更，请重新修改" }
        val request=org.json.JSONObject(turn.requestJson)
        analyze(question,composeMode=request.optBoolean("composeMode"),redraftId=request.optString("redraftId"),targetAnswerId=request.optString("targetAnswerId"),options=options,inputSnapshot=snapshot,editEntryId=id,frozenTurn=turn)
    }
    suspend fun messageVersions(id: String): String {
        val state=_state.value
        val all=graph.dao.history(state.conversationId)
        val user=all.firstOrNull { it.id==id && it.role=="user" } ?: error("消息不存在")
        return org.json.JSONArray(ChatBranch.versions(user,all).map { v ->
            val replies=ChatBranch.replies(v,all)
            val reply=replies.joinToString("\n\n") { app.mailpilot.ai.DraftPresentation.reference(it).replace(Regex("(?m)^草稿定位标识：.*\n?"),"") }
            mapOf("id" to v.id,"text" to v.text,"reply" to reply,
                "entries" to (listOf(v)+replies).map { app.mailpilot.BridgeCodec.entry(it,state,historical=true) })
        }).toString()
    }
    fun cancelAnalysis() { analysisGeneration++; drainingAnalysis=analysisJob ?: drainingAnalysis; analysisJob?.cancel(); analysisJob=null; _state.update { it.copy(analyzing=false,streaming="",status=if(it.busy) it.status else "",responseId="",reasoning=ReasoningSnapshot(),draftPartial=DraftPartial(),agentStage="") } }
    fun loadConversation(c: Conversation) { if(c.accountId.isNotBlank() && c.accountId!=_state.value.activeAccount) return; dismissPdf(); cancelAnalysis(); _state.update { it.copy(recheckAssets=emptySet(),conversationId=c.id,currentConversation=c,selection=JsonCodec.selections(c.selectionJson),localMaterials=emptyList(),tab=1,resultCards=emptyList()) }; observeChat(); updateSelectionLabels() }
    fun newConversation() { dismissPdf(); _state.update { it.copy(selection=emptyList()) }; resetConversation() }
    fun newDraft(body: String="") { if(_state.value.activeAccount.isBlank()) { _state.update { it.copy(error="保存邮件草稿需要先连接邮箱；普通聊天无需邮箱") }; return }; val plain=MailBody.fromMarkdown(body); _state.update { it.copy(editor=Draft(accountId=it.activeAccount,body=plain),detail=null) } }
    fun editDraft(draft: Draft) { _state.update { it.copy(editor=draft,detail=null) } }
    fun confirmChatSend(entryId: String,text: String="确认发送") {
        if(_state.value.analyzing || _state.value.busy) return
        val conversation=_state.value.conversationId
        operation("正在通过 SMTP 发送邮件") {
            val result=ChatSendGate(graph.db,graph.mail).send(conversation,entryId,text)
            val receipt=when(result.status) {
                "SENT" -> "邮件已通过 SMTP 提交给服务器，目标收件人：${result.to}。"+result.error
                "UNKNOWN" -> "发送结果待核实。服务器可能已接收邮件，我不会自动重发。请先核对收件情况。"
                else -> "邮件发送失败，尚未确认送达。${result.error}"
            }
            graph.dao.putEntry(ChatEntry(conversationId=conversation,role="assistant",text=receipt,draftId=result.id))
        }
    }
    fun reviewDraftInChat(draft: Draft) {
        operation("准备邮件确认消息") {
            val saved=graph.mail.saveDraft(draft)
            val id=_state.value.conversationId
            if(graph.dao.conversation(id)==null) graph.dao.putConversation(Conversation(id=id,title="邮件发送确认"))
            graph.dao.putEntry(ChatEntry(conversationId=id,role="assistant",text="请核对这封邮件。回复“确认发送”即可通过 SMTP 发送，也可以继续修改。",draftId=saved.id,draftPreviewJson=ChatSendGate(graph.db,graph.mail).snapshot(saved)))
            _state.update { it.copy(tab=1,editor=null,detail=null,sendPreview=null) }
        }
    }
    fun updateEditor(draft: Draft) { _state.update { it.copy(editor=draft) } }
    fun reply(message: MailMessage,all: Boolean=false,forward: Boolean=false) {
        val a=_state.value.accounts.firstOrNull { it.id==message.accountId }
        val cc=if(all) {
            val replyAddresses=runCatching { jakarta.mail.internet.InternetAddress.parseHeader(message.replyTo.ifBlank { message.senderAddress },false).map { it.address.lowercase() } }.getOrDefault(emptyList())
            runCatching { jakarta.mail.internet.InternetAddress.parseHeader(listOf(message.to,message.cc).filter { it.isNotBlank() }.joinToString(", "),false)
                .filter { !it.address.equals(a?.email,true) && it.address.lowercase() !in replyAddresses }.distinctBy { it.address.lowercase() }.joinToString(", ") { it.toUnicodeString() } }.getOrDefault("")
        } else ""
        _state.update { it.copy(detail=null,editor=Draft(accountId=message.accountId,to=if(forward) "" else message.replyTo.ifBlank { message.senderAddress },cc=cc,
            subject=(if(forward) "Fwd: " else if(message.subject.startsWith("Re:",true)) "" else "Re: ")+message.subject,
            body="\n\n-------- 原邮件 --------\n${message.sender}\n${message.subject}\n${message.body}",inReplyTo=if(forward) "" else message.internetMessageId,
            references=if(forward) "" else listOf(message.references,message.internetMessageId).filter { r -> r.isNotBlank() }.joinToString(" "))) }
        if(forward) operation("准备转发附件") {
            val copies=withContext(Dispatchers.IO) { graph.dao.attachments(message.id).map { att ->
                val a=graph.mail.download(att.id); val dir=File(graph.context.filesDir,"attachments/uploads").apply { mkdirs() }; val file=File(dir,newId())
                File(a.localPath).copyTo(file); DraftFile(file.absolutePath,a.name,a.mimeType)
            } }
            _state.update { current -> current.copy(editor=current.editor?.copy(filesJson=JsonCodec.files(copies))) }
        }
    }
    fun saveDraft(draft: Draft,preview: Boolean=false) { operation("保存草稿") { val saved=graph.mail.saveDraft(draft); _state.update { it.copy(editor=saved,sendPreview=if(preview) saved else null,notice=if(preview) null else "草稿已保存") } } }
    fun sendConfirmed() { val draft=_state.value.sendPreview ?: return; _state.update { it.copy(sendPreview=null) }; operation("正在发送邮件，请勿重复操作") { val sent=graph.mail.send(draft.id,draft.revision); _state.update { it.copy(editor=sent,notice=if(sent.status=="SENT") "邮件已提交给 SMTP 服务器" else null,error=sent.error.takeIf { text -> text.isNotBlank() }) } } }
    fun dismissSend() { _state.update { it.copy(sendPreview=null) } }
    fun resolveUnknown(draft: Draft,sent: Boolean) { operation("更新发送记录") { val updated=draft.copy(status=if(sent) "SENT" else "DRAFT",revision=draft.revision+1,error=""); graph.dao.putDraft(updated); _state.update { it.copy(editor=updated) } } }
    fun deleteDraft(draft: Draft) { operation("删除草稿") {
        graph.db.withTransaction {
            require(graph.dao.draft(draft.id)?.status in listOf("DRAFT","FAILED")) { "仅可删除未发送的本地草稿" }
            graph.dao.deleteDraft(draft.id); graph.dao.purgeOrphanAttempts()
        }
        _state.update { it.copy(editor=if(it.editor?.id==draft.id) null else it.editor,notice="本地草稿已删除") }; removeUnusedUploads()
    } }
    fun redraft(draft: Draft,options: ChatRequestOptions=ChatRequestOptions()) {
        if(_state.value.analyzing || _state.value.busy) return
        if(draft.status in listOf("SENDING","UNKNOWN")) { _state.update { it.copy(notice="请先核实发送状态") }; return }
        if(draft.accountId!=_state.value.activeAccount) { _state.update { it.copy(notice="请切换到该草稿的发件账号") }; return }
        viewModelScope.launch {
            val id=_state.value.conversationId
            if(graph.dao.conversation(id)==null) graph.dao.putConversation(Conversation(id=id,title="重新拟写邮件",accountId=draft.accountId))
            if(graph.dao.history(id).none { it.draftId==draft.id }) graph.dao.putEntry(ChatEntry(conversationId=id,role="assistant",text="将根据这份邮件重新拟写。",draftId=draft.id,draftPreviewJson=ChatSendGate(graph.db,graph.mail).snapshot(draft)))
            _state.update { it.copy(editor=null,detail=null,tab=1) }
            analyze("请重新拟一份邮件，保留已有事实、收件人和附件，优化表达。",composeMode=true,redraftId=draft.id,options=options)
        }
    }
    fun importFile(uri: Uri,draft: Draft,onResult: (Draft)->Unit) { operation("添加附件") {
        val file=withContext(Dispatchers.IO) {
            val resolver=getApplication<Application>().contentResolver
            val name=resolver.query(uri,arrayOf(OpenableColumns.DISPLAY_NAME),null,null,null)?.use { if(it.moveToFirst()) it.getString(0) else null } ?: "附件"
            val dir=File(graph.context.filesDir,"attachments/uploads").apply { mkdirs() }; val target=File(dir,newId())
            try { resolver.openInputStream(uri)?.use { input -> target.outputStream().use { out -> val buffer=ByteArray(8192); var total=0L; while(true) { val n=input.read(buffer); if(n<0) break; total+=n; require(total<=MAX_ATTACHMENT_BYTES) { "附件超过 20 MB" }; out.write(buffer,0,n) } } } ?: error("无法读取文件") }
            catch(e: Exception) { target.delete(); throw e }
            DraftFile(target.absolutePath,name,resolver.getType(uri) ?: "application/octet-stream")
        }
        onResult(draft.copy(filesJson=JsonCodec.files(JsonCodec.files(draft.filesJson)+file)))
    } }
    suspend fun saveAccount(account: MailAccount,password: String): String {
        require(account.email.isNotBlank() && account.imapHost.isNotBlank() && account.smtpHost.isNotBlank()) { "请填写邮箱地址与服务器" }
        jakarta.mail.internet.InternetAddress(account.email,true).validate()
        require(account.imapPort in 1..65535 && account.smtpPort in 1..65535) { "端口应在 1–65535 之间" }
        require(listOf(account.imapHost,account.smtpHost).all { !it.contains('/') && !it.any(Char::isWhitespace) }) { "服务器只填写主机名，不要添加 https:// 或路径" }
        require(password.isNotBlank() || account.passwordCipher.isNotBlank()) { "请填写邮箱授权码" }
        val saved=account.copy(label=account.label.ifBlank { account.email },passwordCipher=if(password.isNotBlank()) graph.secrets.encrypt(password) else account.passwordCipher)
        graph.dao.putAccount(saved); graph.preferences.set("account",saved.id); return "邮箱已保存"
    }
    suspend fun testAccount(account: MailAccount,password: String): String=graph.mail.test(account.copy(passwordCipher=if(password.isNotBlank()) graph.secrets.encrypt(password) else account.passwordCipher))
    suspend fun saveModel(model: ModelProfile,key: String,contextMode: String=ModelContextPolicy.mode(model),outputMode: String=ModelOutputPolicy.mode(model)): String {
        require(model.baseUrl.startsWith("https://") && model.model.isNotBlank()) { "请输入 HTTPS 地址和模型名称" }
        require(contextMode in setOf("auto","custom")) { "请选择有效的上下文设置" }
        require(outputMode in setOf("auto","custom")) { "请选择有效的输出设置" }
        require(outputMode!="custom" || model.outputTokens>0) { "请填写自定义输出长度" }
        val output=ModelOutputPolicy.resolve(model,outputMode)
        ContextBudgetPlanner.validate(ModelContextPolicy.resolve(output,contextMode))
        val saved=withCredential(output,key).copy(label=model.label.ifBlank { model.model })
        graph.dao.putModel(if(contextMode=="auto") saved.copy(contextTokens=32768) else saved)
        graph.preferences.contextMode(saved.id,contextMode)
        graph.preferences.outputMode(saved.id,outputMode)
        if(_state.value.settings.textModelId.isBlank()) graph.preferences.set("textModel",saved.id)
        return "模型已保存"
    }
    private fun withCredential(model: ModelProfile,key: String): ModelProfile {
        if(key.isBlank()) return model
        val same=runCatching { graph.secrets.decrypt(model.apiKeyCipher)==key }.getOrDefault(false)
        if(same) return model
        return model.copy(apiKeyCipher=graph.secrets.encrypt(key),credentialVersion=newId(),diagnosticIdentity="",diagnosticsJson="{}",textVerified=false,supportsTools=false,supportsStreaming=false,supportsVision=false,testReport="密钥已更新，旧诊断已过期；可直接使用")
    }
    suspend fun testModel(model: ModelProfile,key: String,contextMode: String=ModelContextPolicy.mode(model),outputMode: String=ModelOutputPolicy.mode(model)): ModelProfile=graph.models.test(ModelContextPolicy.resolve(ModelOutputPolicy.resolve(withCredential(model,key),outputMode),contextMode))
    fun defaultModel(id: String,vision: Boolean) { viewModelScope.launch { graph.preferences.set(if(vision) "visionModel" else "textModel",id) } }
    fun theme(theme: String) { viewModelScope.launch { graph.preferences.set("theme",theme) } }
    fun fastCompression(enabled: Boolean) { viewModelScope.launch { graph.preferences.set("fastCompression",enabled.toString()) } }
    fun syncMinutes(minutes: Int) { viewModelScope.launch { graph.preferences.sync(minutes) } }
    fun deleteAccount(account: MailAccount) { operation("删除邮箱与本地资料") {
        graph.sync.cancel(account.id)
        analysisJob?.cancelAndJoin(); cancelAnalysis()
        withContext(NonCancellable+Dispatchers.IO) {
            graph.db.withTransaction { graph.dao.deleteMessages(account.id); graph.dao.purgeOrphanAttachments(); graph.dao.deleteAccountDrafts(account.id); graph.dao.purgeOrphanAttempts(); graph.dao.deleteAccountEntries(account.id); graph.dao.deleteAccountConversations(account.id); graph.dao.purgeOrphanTurns(); graph.dao.deleteAccount(account.id) }
            File(graph.context.filesDir,"attachments/${account.id}").deleteRecursively()
            WebEvidenceStore.clearAccount(graph.webStorage,account.id)
            // Preview images can contain message data; remove them when deleting any account.
            File(graph.context.cacheDir,"preview").listFiles()?.forEach { it.deleteRecursively() }
            removeUnusedUploads(); removeUnusedMaterials()
        }
        resetConversation()
    } }
    fun deleteModel(model: ModelProfile) { operation("删除模型") { graph.dao.deleteModel(model.id); graph.preferences.contextMode(model.id,null); graph.preferences.outputMode(model.id,null) } }
    fun clearCache() { operation("清理已下载附件、聊天记录与摘要") {
        analysisJob?.cancelAndJoin(); cancelAnalysis(); graph.db.withTransaction { graph.dao.clearEntries(); graph.dao.clearConversations(); graph.dao.purgeOrphanTurns(); graph.dao.clearAttachmentPaths() }
        withContext(Dispatchers.IO) { graph.webStorage.deleteRecursively(); File(graph.context.cacheDir,"preview").listFiles()?.forEach { it.deleteRecursively() }; for(a in graph.dao.allAccounts()) File(graph.context.filesDir,"attachments/${a.id}").deleteRecursively() }
        removeUnusedUploads(); removeUnusedMaterials()
        resetConversation(); _state.update { it.copy(notice="附件缓存与分析记录已清理，草稿附件保留") }
    } }
    fun retrySearch(withSearch: Boolean) { retryAnalysis("",withSearch=withSearch) }
    fun retryAnalysis(entryId: String,defaults: Boolean=false,withSearch: Boolean?=null,useCurrentMaterials: Boolean=false,compatibleFormat: Boolean=false,batchImages: Boolean=false,continueResearch: Boolean=false) {
        val current=_state.value
        if(current.analyzing || current.busy) return
        viewModelScope.launch {
            val history=ChatBranch.active(graph.dao.history(current.conversationId))
            val index=if(entryId.isBlank()) history.lastIndex else history.indexOfFirst { it.id==entryId }
            val reply=history.getOrNull(index) ?: return@launch
            if(continueResearch && reply.action!="research_partial") return@launch
            if(reply.resultStatus=="complete" && !continueResearch && reply.action !in listOf("search_failed","thinking_failed") && !reply.text.startsWith("回答未完成")) return@launch
            val turn=graph.dao.turn(reply.id) ?: return@launch
            if(turn.accountId!=current.activeAccount || turn.conversationId!=current.conversationId) return@launch
            if(continueResearch) AgentCheckpoints.update(graph.dao,turn.id) { it.optJSONObject("actions")?.apply { put("continueResearch",true); remove("candidate") }; it.remove("result"); it.put("phase","resuming") }
            if(batchImages && runCatching { JSONObject(reply.failureJson).optString("action") }.getOrNull()!="multimodal_choice") return@launch
            val request=org.json.JSONObject(turn.requestJson)
            if(useCurrentMaterials) { request.remove("resolvedPdfPages"); request.remove("agentRun"); graph.dao.putTurn(turn.copy(requestJson=request.toString())) }
            if(compatibleFormat) AgentCheckpoints.update(graph.dao,turn.id) { it.put("compatibleFormat",true) }
            val question=history.take(index).lastOrNull { it.role=="user" } ?: return@launch
            val locals=org.json.JSONArray(turn.localJson)
            val materials=(0 until locals.length()).mapNotNull { n -> val item=locals.getJSONObject(n); graph.dao.material(item.getString("id"))?.copy(selected=true,pagesJson=item.optJSONArray("pages")?.toString() ?: "[]") }
            if(!useCurrentMaterials && materials.size!=locals.length()) { _state.update { it.copy(notice="原问题的手机资料已清理，请重新选择后提问") }; return@launch }
            val options=ChatRequestOptions.parse(org.json.JSONObject(turn.optionsJson))
            val snapshot=current.copy(selection=if(useCurrentMaterials) current.selection else JsonCodec.selections(turn.selectionJson),localMaterials=if(useCurrentMaterials) current.localMaterials else materials,folder=turn.folder,
                models=if(defaults) current.models.map { it.copy(thinkingMode="default",reasoningEffort="",thinkingBudget=0) } else current.models)
            analyze(request.optString("question",question.text),composeMode=request.optBoolean("composeMode",question.action=="draft_answer"),targetAnswerId=request.optString("targetAnswerId",question.targetAnswerId),redraftId=request.optString("redraftId"),retryEntryId=reply.id,
                options=options.copy(thinking=if(defaults) "default" else options.thinking,reasoningEffort=if(defaults) "" else options.reasoningEffort,thinkingBudget=if(defaults) 0 else options.thinkingBudget,webSearch=withSearch ?: options.webSearch,imageMode=if(batchImages) "batch" else if(useCurrentMaterials) "complete" else options.imageMode),inputSnapshot=snapshot)
        }
    }
    suspend fun localAttachment(id: String): Attachment = graph.dao.material(id)?.attachment() ?: graph.mail.download(id)
    suspend fun toggleLocal(id: String)=changeSelection { s ->
        val m=graph.dao.material(id) ?: return@changeSelection
        require(m.conversationId==s.conversationId) { "文件不属于当前会话" }
        if(!sameSelectionScope(s)) return@changeSelection
        val updated=m.copy(selected=!m.selected)
        graph.dao.putMaterial(updated)
        _state.update { if(sameSelectionScope(s)) it.copy(localMaterials=it.localMaterials.map { old -> if(old.id==id) updated else old }) else it }
        updateSelectionLabels()
    }
    fun localPdf(id: String) { val m=_state.value.localMaterials.firstOrNull { it.id==id } ?: return; editPdf(m.attachment()) }
    suspend fun importMaterial(uri: Uri,conversation: String) {
        require(conversation==_state.value.conversationId) { "会话已切换，请重新选择文件" }
        val resolver=graph.context.contentResolver
        val material=withContext(Dispatchers.IO) {
            val name=resolver.query(uri,arrayOf(OpenableColumns.DISPLAY_NAME),null,null,null)?.use { if(it.moveToFirst()) it.getString(0) else null } ?: "附件"
            require(name.substringAfterLast('.').lowercase() in listOf("docx","xlsx","pptx","pdf","jpg","jpeg","png","webp","txt")) { "支持 DOCX、XLSX、PPTX、PDF、图片和 TXT；旧版 Office 请先转换" }
            val dir=File(graph.context.filesDir,"materials").apply { mkdirs() }; val file=File(dir,newId())
            try {
                resolver.openInputStream(uri)?.use { input -> file.outputStream().use { out -> val buffer=ByteArray(8192); var total=0L; while(true) { currentCoroutineContext().ensureActive(); val n=input.read(buffer); if(n<0) break; total+=n; require(total<=MAX_ATTACHMENT_BYTES) { "文件超过 20 MB" }; out.write(buffer,0,n) } } } ?: error("无法读取文件")
                LocalMaterial(conversationId=conversation,name=name,mime=resolver.getType(uri) ?: "application/octet-stream",path=file.path,size=file.length(),selected=!name.endsWith(".pdf",true))
            } catch(e: Exception) { file.delete(); throw e }
        }
        try {
            graph.db.withTransaction { if(graph.dao.conversation(conversation)==null) graph.dao.putConversation(Conversation(id=conversation,title="资料问答")); graph.dao.putMaterial(material) }
        } catch(e: Exception) { File(material.path).delete(); throw e }
        if(conversation==_state.value.conversationId && material.name.endsWith(".pdf",true)) localPdf(material.id)
    }
    fun fillRecipient(entryId: String,address: String,userText: String="补充收件人") { operation("更新收件人") {
        DraftReviewState.validateAddresses(address)
        val id=_state.value.conversationId
        val entry=requireNotNull(graph.dao.history(id).firstOrNull { it.id==entryId })
        val preview=org.json.JSONObject(entry.draftPreviewJson)
        val draft=requireNotNull(graph.dao.draft(entry.draftId)) { "草稿已删除" }
        require(draft.status in listOf("DRAFT","FAILED") && draft.revision==preview.optLong("revision")) { "草稿已更新，请先查看最新版本" }
        val saved=graph.mail.saveDraft(draft.copy(to=address.trim()))
        val submitted=ChatEntry(conversationId=id,role="user",text=if(userText=="补充收件人") "收件人：${address.trim()}" else userText)
        graph.dao.putEntry(submitted); graph.dao.touchConversation(id,submitted.createdAt)
        graph.dao.putEntry(ChatEntry(conversationId=id,role="assistant",text="收件人已更新，请核对新版本后确认发送。",draftId=saved.id,draftPreviewJson=ChatSendGate(graph.db,graph.mail).snapshot(saved)))
    } }
    fun latestDraft(id: String) { operation("查看最新草稿") {
        val d=requireNotNull(graph.dao.draft(id)) { "草稿已删除" }; val conversation=_state.value.conversationId
        require(graph.dao.history(conversation).any { it.draftId==id })
        graph.dao.putEntry(ChatEntry(conversationId=conversation,role="assistant",text="这是当前最新版本，请核对后确认。",draftId=d.id,draftPreviewJson=ChatSendGate(graph.db,graph.mail).snapshot(d)))
    } }
    suspend fun serviceConfig(j: org.json.JSONObject,speech: Boolean,save: Boolean): ServiceConfig {
        val old=if(speech) _state.value.settings.speech else _state.value.settings.search
        val cfg=ServiceConfig.parse(j.toString(),speech).copy(keyCipher=if(j.optString("secret").isNotBlank()) graph.secrets.encrypt(j.getString("secret")) else if(j.optString("provider",old.provider)==old.provider) old.keyCipher else "")
        require(cfg.baseUrl.startsWith("https://") && !cfg.baseUrl.contains('{')) { "请输入完整 HTTPS 接口地址" }
        require(cfg.language in listOf("auto","zh","en") && cfg.mode in listOf("system","cloud"))
        require(if(speech) cfg.provider=="qwen" else cfg.provider in listOf("volcengine","bocha"))
        if(save) graph.preferences.set(if(speech) "speechConfig" else "searchConfig",cfg.json())
        return cfg
    }
    suspend fun conversationPage(j: JSONObject): String {
        val account=_state.value.activeAccount
        require(j.optString("accountId",account)==account) { "邮箱已切换，请刷新会话列表" }
        val cursor=j.optJSONObject("cursor")
        val search=j.optString("search").trim(); require(search.length<=400) { "搜索内容过长" }
        val rows=graph.dao.conversationPage(account,cursor==null,cursor?.optLong("pinnedAt") ?: 0,cursor?.optLong("lastActivityAt") ?: 0,cursor?.optString("id").orEmpty(),51,search)
        val page=rows.take(50)
        fun fields(h: ConversationHeader)=mapOf("id" to h.id,"title" to h.title,"createdAt" to h.createdAt,"lastActivityAt" to h.lastActivityAt,"pinnedAt" to h.pinnedAt)
        return JSONObject().put("items",org.json.JSONArray(page.map(::fields))).put("cursor",if(rows.size>50) JSONObject(fields(page.last())) else JSONObject.NULL).put("revision",_state.value.historyRevision).toString()
    }
    private suspend fun scopedConversations(ids: List<String>): List<Conversation> {
        val account=_state.value.activeAccount
        return ids.distinct().map { requireNotNull(graph.dao.conversation(it)) { "会话已删除，请刷新列表" }.also { c -> require(c.accountId.isBlank() || c.accountId==account) { "会话不属于当前邮箱" } } }
    }
    suspend fun renameConversation(id: String,title: String) {
        val trimmed=title.trim(); require(trimmed.codePointCount(0,trimmed.length) in 1..80) { "名称需要 1–80 个字符" }
        scopedConversations(listOf(id)); graph.dao.renameConversation(id,trimmed)
    }
    suspend fun pinConversations(ids: List<String>,pin: Boolean) {
        scopedConversations(ids)
        graph.db.withTransaction { ids.distinct().chunked(500).forEach { graph.dao.pinConversations(it,if(pin) System.currentTimeMillis() else 0) } }
    }
    fun deleteConversation(id: String)=deleteConversations(listOf(id))
    fun deleteConversations(ids: List<String>) { operation("删除会话") {
        val rows=scopedConversations(ids)
        val active=rows.any { it.id==_state.value.conversationId }
        if(active) { analysisJob?.cancelAndJoin(); cancelAnalysis() }
        graph.db.withTransaction { rows.forEach { graph.dao.deleteEntries(it.id); graph.dao.deleteConversation(it.id) }; graph.dao.purgeOrphanTurns() }
        withContext(Dispatchers.IO) { rows.forEach { WebEvidenceStore(graph.webStorage,it.accountId,it.id).clear() } }
        removeUnusedMaterials(); removeUnusedProcessedImages(); if(active) newConversation()
    } }
    suspend fun visualMaterials(): String {
        val s=_state.value
        val selected=(s.selection.flatMap { it.attachmentIds }+s.localMaterials.filter { it.selected }.map { it.id }).toSet()
        val values=graph.dao.visualEvidence(s.conversationId,s.activeAccount).flatMap { JsonCodec.sources(it.sourcesJson) }.distinctBy { it.assetKey }
            .filter { it.attachmentId in selected && it.assetKey.isNotBlank() }
            .map { mapOf("assetKey" to it.assetKey,"title" to it.title,"location" to it.location,"pending" to (it.assetKey in s.recheckAssets)) }
        return org.json.JSONArray(values).toString()
    }
    suspend fun recheckVisual(key: String) {
        val rows=org.json.JSONArray(visualMaterials())
        require((0 until rows.length()).any { rows.getJSONObject(it).getString("assetKey")==key }) { "图片已取消选择，请重新选择资料" }
        _state.update { it.copy(recheckAssets=if(key in it.recheckAssets) it.recheckAssets-key else it.recheckAssets+key,notice="已更新读图选择，下次发送时生效") }
    }
    private suspend fun removeUnusedMaterials()=withContext(Dispatchers.IO) {
        val used=graph.dao.allMaterials().map { File(it.path).canonicalPath }.toSet()
        File(graph.context.filesDir,"materials").listFiles()?.filter { it.canonicalPath !in used }?.forEach { it.delete() }
    }
    private suspend fun removeUnusedProcessedImages()=withContext(Dispatchers.IO) {
        // Processing can create a file before its index is committed. Defer collection during a run.
        if(analysisJob?.isActive==true) return@withContext
        val used=graph.dao.retainedImageSources().flatMap { JsonCodec.sources(it) }.filter { it.imagePath.isNotBlank() }.map { File(it.imagePath).canonicalPath }.toMutableSet()
        fun retain(value: Any?) {
            when(value) {
                is JSONObject -> value.keys().forEach { key -> if(key=="imagePath") value.optString(key).takeIf(String::isNotBlank)?.let { used+=File(it).canonicalPath } else retain(value.opt(key)) }
                is org.json.JSONArray -> (0 until value.length()).forEach { retain(value.opt(it)) }
                is String -> if(value.startsWith("[")) runCatching { retain(org.json.JSONArray(value)) }
            }
        }
        graph.dao.allTurns().forEach { runCatching { retain(JSONObject(it.requestJson)) } }
        val root=File(graph.context.cacheDir,"preview").canonicalFile
        root.listFiles()?.filter { it.isFile && it.canonicalFile.parentFile==root && it.canonicalPath !in used }?.forEach { it.delete() }
    }
    private suspend fun removeUnusedUploads()=withContext(Dispatchers.IO) {
        val used=(graph.dao.allDrafts()+listOfNotNull(_state.value.editor?.takeIf { graph.dao.account(it.accountId)!=null })).flatMap { JsonCodec.files(it.filesJson) }.map { File(it.path).canonicalPath }.toSet()
        File(graph.context.filesDir,"attachments/uploads").listFiles()?.filter { it.canonicalPath !in used }?.forEach { it.delete() }
    }
}

