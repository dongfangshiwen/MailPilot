package app.mailpilot

import android.app.Application
import androidx.room.Room
import app.mailpilot.data.*
import app.mailpilot.mail.*
import com.icegreen.greenmail.util.*
import jakarta.mail.*
import jakarta.mail.internet.MimeMessage
import kotlinx.coroutines.*
import org.junit.*
import org.junit.Assert.*
import org.junit.runner.RunWith
import org.robolectric.*
import org.robolectric.annotation.Config
import java.util.*

@RunWith(RobolectricTestRunner::class)
@Config(sdk=[28],application=Application::class)
class IncrementalSyncTest {
    private lateinit var db: MailDatabase; private lateinit var server: GreenMail
    private lateinit var account: MailAccount; private lateinit var repo: MailRepositoryImpl
    private lateinit var props: Properties
    private var stats=0 to 0
    @Before fun setup()=runBlocking {
        db=Room.inMemoryDatabaseBuilder(RuntimeEnvironment.getApplication(),MailDatabase::class.java).allowMainThreadQueries().build()
        server=GreenMail(ServerSetup(0,"127.0.0.1","imap")); server.start(); server.setUser("sync@example.test","sync@example.test","password")
        account=MailAccount(email="sync@example.test",passwordCipher="password",imapHost="127.0.0.1",imapPort=server.imap.port)
        db.dao().putAccount(account)
        props=Properties().apply { setProperty("mail.imap.ssl.enable","false"); setProperty("mail.imap.starttls.enable","false"); setProperty("mail.imap.starttls.required","false") }
        repo=MailRepositoryImpl(db,PlainTestSecrets(),RuntimeEnvironment.getApplication().filesDir,props,false) { d,h -> stats=d to h }
    }
    @After fun cleanup() { server.stop(); db.close() }
    private fun message(n: Int,body: String="Body $n")=MimeMessage(Session.getInstance(Properties())).apply {
        setFrom("sender@example.test"); setRecipients(Message.RecipientType.TO,account.email); setSubject("Message $n"); setText(body)
        sentDate=Date(1700000000000L+n*60000); saveChanges()
    }
    private fun folder(name: String,block: (Folder)->Unit) {
        Session.getInstance(props).getStore("imap").use { store ->
            store.connect(account.imapHost,account.imapPort,account.email,"password")
            val f=store.getFolder(name); if(!f.exists()) f.create(Folder.HOLDS_MESSAGES)
            f.open(Folder.READ_WRITE); try { block(f) } finally { f.close(false) }
        }
    }
    private fun add(name: String,range: IntRange)=folder(name) { f -> f.appendMessages(range.map { message(it) }.toTypedArray()) }
    @Test fun everyFolderFiftyThenMoreThanFiftyNewMessagesAndZeroWarmDownloads()=runBlocking {
        add("INBOX",1..60); add("Drafts",1..55); add("Sent",1..53)
        var metadataVisible=false
        assertTrue(repo.syncAccount(account.id,"INBOX") { label ->
            if(!metadataVisible && label.startsWith("读取正文")) {
                metadataVisible=true
                runBlocking {
                    for(name in listOf("INBOX","Drafts","Sent")) {
                        val rows=db.dao().cachedMessages(account.id,name)
                        assertEquals(50,rows.size); assertTrue(rows.all { it.bodyState=="PENDING" && it.body.isEmpty() })
                    }
                }
            }
        }.isEmpty())
        assertTrue(metadataVisible); assertEquals(150,stats.first)
        assertEquals("Message 60",db.dao().cachedMessages(account.id,"INBOX").first().subject)
        repo.syncAccount(account.id,"INBOX"); assertEquals(0 to 150,stats)
        add("INBOX",61..122)
        repo.syncAccount(account.id,"Drafts")
        assertEquals(62,stats.first); assertEquals(112,db.dao().cachedMessages(account.id,"INBOX").size)
        assertEquals("Message 122",db.dao().cachedMessages(account.id,"INBOX").first().subject)
        repo.syncAccount(account.id,"INBOX"); assertEquals(0,stats.first)
    }
    @Test fun canceledHydrationResumesFromCommittedMetadataWithoutLosingBodies()=runBlocking {
        add("INBOX",1..52)
        val e=runCatching { repo.syncAccount(account.id,"INBOX") { if(it.startsWith("读取正文")) throw CancellationException("test cancel") } }.exceptionOrNull()
        assertTrue(e is CancellationException)
        val cursor=db.dao().syncCursor(account.id,"INBOX")!!; assertTrue(cursor.lastUid>0)
        assertEquals(50,db.dao().cachedMessages(account.id,"INBOX").size)
        repo.syncAccount(account.id,"INBOX")
        assertEquals(50,stats.first); assertTrue(db.dao().cachedMessages(account.id,"INBOX").all { it.bodyState=="READY" })
        assertEquals(cursor.lastUid,db.dao().syncCursor(account.id,"INBOX")!!.lastUid)
        val more=repo.load(account.id,"INBOX",MailQuery(offset=50,limit=50)); assertEquals(2,more.size)
    }
    @Test fun cachedFlagsExpungesAndUidValidityChangesAreReconciled()=runBlocking {
        add("INBOX",1..4); repo.syncAccount(account.id,"INBOX")
        folder("INBOX") { f -> f.getMessage(4).setFlag(Flags.Flag.SEEN,true); f.getMessage(1).setFlag(Flags.Flag.DELETED,true); f.expunge() }
        repo.syncAccount(account.id,"INBOX")
        val rows=db.dao().cachedMessages(account.id,"INBOX"); assertEquals(3,rows.size); assertFalse(rows.first().unread); assertEquals(0,stats.first)
        val cursor=db.dao().syncCursor(account.id,"INBOX")!!
        db.dao().putSyncCursor(cursor.copy(validity=cursor.validity+1,lastUid=Long.MAX_VALUE))
        repo.syncAccount(account.id,"INBOX")
        assertEquals(cursor.validity,db.dao().syncCursor(account.id,"INBOX")!!.validity)
        assertEquals(3,db.dao().cachedMessages(account.id,"INBOX").size)
    }
    @Test fun oneOversizeBodyDoesNotBlockOtherFolders()=runBlocking {
        folder("INBOX") { it.appendMessages(arrayOf(message(1,"x".repeat(2*1024*1024+1)))) }; add("Sent",1..2)
        val errors=repo.syncAccount(account.id,"INBOX")
        assertTrue(errors.any { it.contains("正文") }); assertEquals("ERROR",db.dao().cachedMessages(account.id,"INBOX").single().bodyState)
        assertTrue(db.dao().cachedMessages(account.id,"Sent").all { it.bodyState=="READY" })
    }
    @Test fun staleOrDeletedDraftCannotBeOverwrittenByLateGeneration()=runBlocking {
        val draft=repo.saveDraft(Draft(accountId=account.id,body="old"))
        val changed=repo.saveDraft(draft.copy(body="manual"))
        assertNotNull(runCatching { repo.saveDraft(draft.copy(body="late model")) }.exceptionOrNull())
        assertEquals("manual",db.dao().draft(draft.id)!!.body)
        db.dao().deleteDraft(changed.id)
        assertNotNull(runCatching { repo.saveDraft(changed.copy(body="resurrection")) }.exceptionOrNull())
    }
}
