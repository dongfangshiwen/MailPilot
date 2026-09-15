package app.mailpilot

import android.app.Application
import androidx.room.Room
import app.mailpilot.ai.*
import app.mailpilot.attachments.*
import app.mailpilot.data.*
import app.mailpilot.mail.*
import app.mailpilot.services.*
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import org.json.*
import org.junit.*
import org.junit.Assert.*
import org.junit.runner.RunWith
import org.robolectric.*
import org.robolectric.annotation.Config
import java.io.File

@RunWith(RobolectricTestRunner::class)
@Config(sdk=[28],application=Application::class)
class SelectedLinks37Test {
    private lateinit var db: MailDatabase
    private val app get()=RuntimeEnvironment.getApplication()
    private val url="https://example.org/record?access=fixture%2Btoken&item=2"
    private val profile=ModelProfile(model="fixture",thinkingMode="disabled")
    @Before fun setup() { db=Room.inMemoryDatabaseBuilder(app,MailDatabase::class.java).allowMainThreadQueries().build() }
    @After fun close() { db.close() }
    private val processor=object: AttachmentProcessor {
        override suspend fun pdfCount(file: File)=1
        override suspend fun previewPdf(file: File,page: Int)=file
        override suspend fun process(attachment: Attachment,pages: List<Int>,onProgress: (String)->Unit)=listOf(SourceChunk(messageId=attachment.messageId,attachmentId=attachment.id,title=attachment.name,location="文字附件",text="资料网址：https://example.org/manual"))
    }
    private suspend fun fixture() {
        db.dao().putAccount(MailAccount(id="a",email="fixture@example.test"))
        db.dao().putConversation(Conversation(id="c",accountId="a"))
        db.dao().putMessages(listOf(MailMessage("m","a","INBOX",1,1,"合成通知","sender","sender@example.test",sentAt=0,body="查看记录。了解详情。",
            html="""<a href="https://example.org/record?access=fixture%2Btoken&amp;item=2">查看记录</a><a>了解详情</a><img src="https://example.org/tracker">"""),
            MailMessage("other","a","INBOX",1,2,"未选择","sender","sender@example.test",sentAt=0,body="https://unselected.example/private")))
    }
    private class Client(val native: Boolean,val read: Boolean=true): ModelClient {
        val inputs=mutableListOf<JSONArray>(); val stages=mutableListOf<String>()
        override suspend fun test(profile: ModelProfile)=profile
        override fun generate(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?)=error("typed requests")
        override fun generateRequest(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?,options: ModelRequestOptions)=flow {
            inputs+=JSONArray(messages.toString()); stages+=options.stage
            val hasResult=(0 until messages.length()).any { messages.getJSONObject(it).optString("role")=="tool" || messages.getJSONObject(it).optString("content").startsWith("应用动作执行结果") }
            val content=(0 until messages.length()).joinToString("\n") { messages.getJSONObject(it).optString("content") }
            assertFalse(content.contains("unselected.example"))
            if(!hasResult && read) {
                assertTrue(content.contains("example.org/record?access=fixture%2Btoken&item=2"))
                assertTrue(content.contains("本轮资料来源：[S1], [S2]"))
                assertTrue(content.contains("read_web_page")); assertFalse(content.contains("\"name\":\"web_search\""))
                val action=roleMessage("assistant","""{"mailpilot_action":"read_web_page","arguments":{"source_ids":["S2"]}}""")
                emit(ModelEvent.Completed(if(native) AgentActions(requireNotNull(tools)).normalize(action,false) else action))
            } else emit(ModelEvent.Completed(roleMessage("assistant",if(read) "已按工具返回状态核对记录。[S2]" else "邮件包含一条记录链接，尚未访问。")))
        }
    }
    private fun agent(client: ModelClient,reader: WebPageReader,root: File?=null)=LocalAgent(db.dao(),MailRepositoryImpl(db,PlainTestSecrets(),app.filesDir),processor,client,
        object: WebSearchClient { override suspend fun search(config: ServiceConfig,query: String): List<SourceChunk> = error("Selected URLs must never enter search") },webStorage=root).also { it.pageReader=reader }

    @Test fun extractsHiddenHrefAndPlainUrlsWithoutFetchingOrGuessing() {
        val links=SelectedLinks.extract("资料：https://example.org/a?q=1。还有 (https://example.org/b_(x))", """<a href="https://example.org/a?q=1">查看</a><a href="/relative">不猜</a><a>无地址</a><a href="javascript:alert(1)">脚本</a><a href="mailto:a@b.test">邮件</a><img src="https://example.org/track"><a href="https://user:pass@example.org">凭据</a>""")
        assertEquals(listOf("https://example.org/a?q=1","https://example.org/b_(x)"),links.map { it.url })
        assertEquals("查看",links.first().label)
        val disguised=SelectedLinks.extract("https://visible.example/", "<a href=\"https://actual.example/\">https://visible.example/</a>")
        assertEquals(listOf("https://actual.example/"),disguised.map { it.url })
    }
    @Test fun selectedTextAttachmentLinksAreIncludedWithoutReadingOtherAttachments(): Unit=runBlocking {
        fixture(); val file=File.createTempFile("links37-",".txt",app.cacheDir).also { it.writeText("synthetic") }
        try {
            db.dao().putAttachments(listOf(Attachment(id="attachment",messageId="m",name="资料.txt",mimeType="text/plain",size=file.length(),partPath="1",localPath=file.path)))
            val client=object: ModelClient {
                override suspend fun test(profile: ModelProfile)=profile
                override fun generate(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?)=flow {
                    assertTrue(messages.toString().contains("example.org")); emit(ModelEvent.Completed(roleMessage("assistant","仅总结资料。")))
                }
            }
            val result=agent(client,WebPageReader { error("Summary does not prefetch") }).run("a","INBOX",listOf(Selection("m",listOf("attachment"))),"总结",profile,null,conversationId="c")
            val link=result.sources.single { it.url=="https://example.org/manual" }
            assertEquals("attachment",link.attachmentId); assertEquals("selected_link",link.retrieval)
        } finally { file.delete() }
    }
    @Test fun selectedMailLinkReadsWithoutSearchConfigurationInBothModes(): Unit=runBlocking {
        fixture()
        for(native in listOf(false,true)) {
            var requests=0; val client=Client(native)
            val result=agent(client,WebPageReader { assertEquals(url,it); requests++; WebPage("合成记录原文：金额 500 元，状态有效。","complete") })
                .run("a","INBOX",listOf(Selection("m")),"总结邮件并查看链接内容",profile.copy(supportsTools=native),null,conversationId="c",options=ChatRequestOptions(webSearch=false))
            assertEquals(1,requests); assertEquals(2,client.inputs.size); assertFalse(result.partial)
            assertTrue(client.inputs.last().toString().contains("金额 500 元"))
            assertEquals("webpage",result.sources.single { it.url==url }.retrieval); assertEquals("m",result.sources.single { it.url==url }.messageId)
            assertTrue(db.dao().allDrafts().isEmpty())
        }
    }
    @Test fun justSummarizingDoesNotPreFetchAndClearedSelectionDoesNotRestoreLinks(): Unit=runBlocking {
        fixture(); var requests=0
        val client=Client(false,false)
        val flow=agent(client,WebPageReader { requests++; error("Should not fetch") })
        val result=flow.run("a","INBOX",listOf(Selection("m")),"只总结正文",profile,null,conversationId="c")
        assertEquals(0,requests); assertEquals("selected_link",result.sources.single { it.url==url }.retrieval)
        val history=listOf(ChatEntry(conversationId="c",role="assistant",text=result.text,sourcesJson=JsonCodec.sources(result.sources)))
        val absent=object: ModelClient {
            override suspend fun test(profile: ModelProfile)=profile
            override fun generate(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?)=flow {
                assertFalse(messages.toString().contains("fixture%2Btoken")); assertFalse(messages.toString().contains("\"name\":\"read_web_page\""))
                emit(ModelEvent.Completed(roleMessage("assistant","请重新选择资料。")))
            }
        }
        agent(absent,WebPageReader { error("No selection") }).run("a","INBOX",emptyList(),"当前未选择",profile,null,conversationId="c",history=history)
    }
    @Test fun completedPageSurvivesSerializationAndAgentRestartWithoutAnotherFetch(): Unit=runBlocking {
        fixture(); val root=java.nio.file.Files.createTempDirectory("links37-").toFile()
        try {
            var fetched=0; val reader=WebPageReader { fetched++; WebPage("已核实的长记录。".repeat(1000),"complete") }
            val first=agent(Client(false),reader,root).run("a","INBOX",listOf(Selection("m")),"查看链接",profile,null,conversationId="c")
            val history=listOf(ChatEntry(conversationId="c",role="assistant",text=first.text,sourcesJson=JsonCodec.sources(first.sources)))
            val next=agent(Client(false),reader,root).run("a","INBOX",listOf(Selection("m")),"核对同一链接",profile,null,conversationId="c",history=history)
            assertEquals(1,fetched); assertEquals("webpage",next.sources.single { it.url==url }.retrieval)
        } finally { root.deleteRecursively() }
    }
    @Test fun inaccessiblePagesKeepMailAndReturnSpecificStatus(): Unit=runBlocking {
        fixture()
        for((status,description) in mapOf("login_required" to "登录","empty_or_dynamic" to "JavaScript","unsupported_type" to "下载后","http_403" to "拒绝访问","too_large" to "2 MiB")) {
            val client=Client(false)
            val result=agent(client,WebPageReader { WebPage(status=status) }).run("a","INBOX",listOf(Selection("m")),"查看链接",profile,null,conversationId="c")
            assertTrue(client.inputs.last().toString().contains(description)); assertEquals("selected_link",result.sources.single { it.url==url }.retrieval)
            assertTrue(result.sources.any { it.messageId=="m" && it.kind=="mail" })
        }
    }
    @Test fun arbitraryUrlAndOtherMailIdsDoNotReachReader(): Unit=runBlocking {
        fixture(); val sources=SelectedLinks.sources(SourceChunk(messageId="m",title="m",location="mail"),SelectedLinks.extract(url)).map { it.copy(id="S2") }
        var fetched=0
        val result=WebReadWorkflow(db.dao(),WebPageReader { fetched++; WebPage("should not happen","complete") })
            .run(listOf("S1","https://example.org/arbitrary","other"),sources,ResearchProgress(JSONObject()),4096,"read","") {}
        assertEquals(0,fetched); assertFalse(result.cacheable)
    }
}
