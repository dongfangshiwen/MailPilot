package app.mailpilot

import android.app.Application
import androidx.room.Room
import app.mailpilot.ai.*
import app.mailpilot.attachments.*
import app.mailpilot.data.*
import app.mailpilot.mail.MailRepository
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.flow
import org.json.*
import org.junit.*
import org.junit.Assert.*
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import java.io.File
import java.io.RandomAccessFile

@RunWith(RobolectricTestRunner::class)
@Config(sdk=[28],application=Application::class)
class Selection101Test {
    private lateinit var db: MailDatabase
    private val temporary=mutableListOf<File>()
    private fun a(id: String,ext: String="txt",size: Long=1)=Attachment(id,"m","$id.$ext","application/octet-stream",size,"1")
    @Before fun setup() { db=Room.inMemoryDatabaseBuilder(RuntimeEnvironment.getApplication(),MailDatabase::class.java).allowMainThreadQueries().build() }
    @After fun close() { db.close(); temporary.forEach { it.delete() } }
    private fun disk(a: Attachment,size: Long): Attachment {
        val f=File.createTempFile("selection101-",".${SelectionPolicy.extension(a)}",RuntimeEnvironment.getApplication().cacheDir)
        temporary+=f; RandomAccessFile(f,"rw").use { it.setLength(size) }
        return a.copy(localPath=f.path)
    }
    private suspend fun message() { db.dao().putMessages(listOf(MailMessage("m","account","INBOX",1,1,"Selected mail","sender","sender@example.test",sentAt=0,body="body"))) }
    private class Client: ModelClient {
        var calls=0
        override suspend fun test(profile: ModelProfile)=profile
        override fun generate(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?)=flow { calls++; emit(ModelEvent.Completed(roleMessage("assistant","已分析所选内容"))) }
    }
    private class Mail(val files: Map<String,Attachment> = emptyMap()): MailRepository {
        val downloads=mutableListOf<String>()
        override suspend fun test(account: MailAccount)=""
        override suspend fun folders(accountId: String)=emptyList<String>()
        override suspend fun load(accountId: String,folder: String,query: MailQuery,onProgress: (String)->Unit)=emptyList<MailMessage>()
        override suspend fun markRead(message: MailMessage) {}
        override suspend fun download(id: String): Attachment { downloads+=id; return files.getValue(id) }
        override suspend fun saveDraft(draft: Draft)=error("must not draft")
        override suspend fun send(draftId: String,confirmedRevision: Long)=error("must not send")
    }
    private class Processor(var count: Int=9,var images: Int=0): AttachmentProcessor {
        val pages=mutableListOf<List<Int>>()
        override suspend fun pdfCount(file: File)=count
        override suspend fun previewPdf(file: File,page: Int)=error("not a preview test")
        override suspend fun process(attachment: Attachment,pages: List<Int>,onProgress: (String)->Unit): List<SourceChunk> {
            this.pages+=pages
            return if(images>0) (0 until images).map { SourceChunk(messageId="m",title=attachment.name,location="image $it",imagePath="not-read-before-limit") }
            else listOf(SourceChunk(messageId="m",attachmentId=attachment.id,title=attachment.name,location="text",text="content"))
        }
    }
    @Test fun defaultsIncludeUnknownSizesButExcludeUnsupportedAndOversize() {
        val all=listOf(a("pdf","pdf"),a("unknown","png",-1),a("limit","docx",SelectionPolicy.FILE_BYTES),a("large","xlsx",SelectionPolicy.FILE_BYTES+1),a("legacy","doc"),a("zip","zip"))
        val selected=SelectionPolicy.defaults("m",all)
        assertEquals(listOf("pdf","unknown","limit"),selected.attachmentIds)
        assertEquals(listOf("pdf"),selected.defaultPdfIds)
        assertTrue(selected.pdfPages.isEmpty())
        assertEquals("超过单文件 20 MB",SelectionPolicy.reason(all[3]))
    }
    @Test fun deselectAndReselectDoNotChangeOtherExplicitPdfPages() {
        val old=Selection("m",listOf("x","pdf"),mapOf("pdf" to listOf(2,5)))
        val removed=SelectionPolicy.toggle(old,a("x"))
        assertEquals(old.pdfPages,removed.pdfPages)
        assertEquals(old,SelectionPolicy.toggle(removed,a("x")).copy(attachmentIds=old.attachmentIds))
        val pdfRemoved=SelectionPolicy.toggle(old,a("pdf","pdf"))
        assertFalse(pdfRemoved.pdfPages.containsKey("pdf"))
        assertEquals(listOf("pdf"),SelectionPolicy.toggle(pdfRemoved,a("pdf","pdf")).defaultPdfIds)
    }
    @Test fun oldSelectionJsonStaysExplicitAndNewDefaultsRoundTrip() {
        val old="""[{"messageId":"m","attachmentIds":["p"],"pdfPages":{"p":[1,4]}}]"""
        assertEquals(Selection("m",listOf("p"),mapOf("p" to listOf(1,4))),JsonCodec.selections(old).single())
        val value=listOf(SelectionPolicy.defaults("m",listOf(a("p","pdf"))))
        assertEquals(value,JsonCodec.selections(JsonCodec.selections(value)))
        assertTrue(JsonCodec.selections("""[{"messageId":"m","attachmentIds":[],"pdfPages":{}}]""").single().attachmentIds.isEmpty())
    }
    @Test fun aggregateBoundariesAreInclusiveAndDeduplicated() {
        val files=(0..9).map { a("f$it",size=5L*1024*1024) }
        val boundary=SelectionPolicy.summary(files+files,emptyMap(),emptySet())
        assertFalse(boundary["blocked"] as Boolean); assertEquals(10,boundary["count"])
        assertTrue(SelectionPolicy.summary(files+a("extra"),emptyMap(),emptySet())["blocked"] as Boolean)
        assertTrue(SelectionPolicy.summary(files.dropLast(1)+a("bigger",size=5L*1024*1024+1),emptyMap(),emptySet())["blocked"] as Boolean)
        assertFalse(SelectionPolicy.summary(listOf(a("p","pdf")),mapOf("p" to (0..19).toList()),emptySet())["blocked"] as Boolean)
        assertTrue(SelectionPolicy.summary(listOf(a("p","pdf"),a("photo","png")),mapOf("p" to (0..19).toList()),emptySet())["blocked"] as Boolean)
        assertEquals(1,SelectionPolicy.summary(listOf(a("unknown",size=-1)),emptyMap(),emptySet())["unknown"])
    }
    @Test fun overLimitPreventsDownloadsAndEvenSearchPlanning()=runBlocking {
        message(); val files=(0..10).map { a("f$it") }; db.dao().putAttachments(files)
        val client=Client(); val mail=Mail()
        val error=runCatching { LocalAgent(db.dao(),mail,Processor(),client).run("account","INBOX",listOf(SelectionPolicy.defaults("m",files)),"搜索资料",ModelProfile(),null,options=ChatRequestOptions(webSearch=true)) }.exceptionOrNull()
        assertTrue(error is MaterialFailure); assertTrue(mail.downloads.isEmpty()); assertEquals(0,client.calls)
    }
    @Test fun actualUnknownSizeStopsBeforeModelAndDoesNotIgnoreAnyFile()=runBlocking {
        message(); val files=(0..2).map { a("f$it",size=-1) }; db.dao().putAttachments(files)
        val downloaded=files.mapIndexed { i,a -> disk(a,(if(i==2) 12L else 20L)*1024*1024) }.associateBy { it.id }
        val client=Client(); val mail=Mail(downloaded)
        val error=runCatching { LocalAgent(db.dao(),mail,Processor(),client).run("account","INBOX",listOf(SelectionPolicy.defaults("m",files)),"内容",ModelProfile(),null) }.exceptionOrNull()
        assertTrue(error is MaterialFailure); assertTrue(error!!.message!!.contains("f2.txt")); assertEquals(0,client.calls)
    }
    @Test fun officeImagesAreCountedBeforeVisionAndSearch()=runBlocking {
        message(); val file=a("office","docx"); db.dao().putAttachments(listOf(file))
        val client=Client(); val mail=Mail(mapOf(file.id to disk(file,1)))
        val error=runCatching { LocalAgent(db.dao(),mail,Processor(images=21),client).run("account","INBOX",listOf(SelectionPolicy.defaults("m",listOf(file))),"搜索",ModelProfile(),null,options=ChatRequestOptions(webSearch=true)) }.exceptionOrNull()
        assertTrue(error is MaterialFailure); assertEquals(0,client.calls)
    }
    @Test fun defaultPageResolutionIsFrozenForRetryAndUnselectedFileNeverDownloads()=runBlocking {
        message(); val file=a("pdf","pdf"); db.dao().putAttachments(listOf(file,a("unselected")))
        val selection=listOf(SelectionPolicy.defaults("m",listOf(file)))
        db.dao().putConversation(Conversation(id="chat"))
        db.dao().putTurn(TurnSnapshot("turn","chat","account","INBOX",JsonCodec.selections(selection),1))
        val mail=Mail(mapOf(file.id to disk(file,1))); val processor=Processor(); val client=Client()
        val agent=LocalAgent(db.dao(),mail,processor,client)
        agent.run("account","INBOX",selection,"内容",ModelProfile(),null,conversationId="chat",requestId="turn")
        processor.count=40
        agent.run("account","INBOX",selection,"内容",ModelProfile(),null,conversationId="chat",requestId="turn")
        assertEquals(listOf((0..8).toList()),processor.pages) // Retry reuses extracted content.
        assertEquals(listOf("pdf","pdf"),mail.downloads)
        assertEquals(9,JSONObject(db.dao().turn("turn")!!.requestJson).getJSONObject("resolvedPdfPages").getJSONArray("pdf").length())
    }
    @Test fun cancellationNeverBecomesAFileFailure()=runBlocking {
        message(); val file=a("cancel"); db.dao().putAttachments(listOf(file)); val client=Client()
        val mail=object: MailRepository by Mail() { override suspend fun download(id: String): Attachment { throw CancellationException("cancel") } }
        val error=runCatching { LocalAgent(db.dao(),mail,Processor(),client).run("account","INBOX",listOf(SelectionPolicy.defaults("m",listOf(file))),"内容",ModelProfile(),null) }.exceptionOrNull()
        assertTrue(error is CancellationException); assertEquals(0,client.calls)
    }
}
