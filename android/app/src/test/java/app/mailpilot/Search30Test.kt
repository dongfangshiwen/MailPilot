package app.mailpilot

import android.app.Application
import android.graphics.Bitmap
import androidx.room.Room
import app.mailpilot.ai.*
import app.mailpilot.attachments.*
import app.mailpilot.data.*
import app.mailpilot.mail.*
import app.mailpilot.services.WebSearchClient
import app.mailpilot.services.WebPage
import app.mailpilot.services.WebPageReader
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import org.json.*
import org.junit.*
import org.junit.Assert.*
import org.junit.runner.RunWith
import org.robolectric.*
import org.robolectric.annotation.Config
import java.io.File

@RunWith(RobolectricTestRunner::class)
@Config(sdk=[28],application=Application::class)
class Search30Test {
    private lateinit var db: MailDatabase
    private val app get()=RuntimeEnvironment.getApplication()
    private val model=ModelProfile(model="deepseek-v4-flash-vision-exp",provider="deepseek",baseUrl="https://api.deepseek.com/v1",contextTokens=1000000,thinkingMode="disabled")
    @Before fun setup() { db=Room.inMemoryDatabaseBuilder(app,MailDatabase::class.java).allowMainThreadQueries().build() }
    @After fun close() { db.close() }
    private val web=SourceChunk(messageId="",title="产品官方资料",location="网页",text="设备技术规范",kind="web",url="https://example.test/spec")
    private fun plan(vararg queries: String)=roleMessage("assistant",JSONObject().put("mailpilot_action","web_search").put("arguments",JSONObject().put("queries",JSONArray(queries))).toString())
    private fun hasResult(input: JSONArray)=(0 until input.length()).any { input.getJSONObject(it).optString("role")=="tool" || input.getJSONObject(it).optString("content").startsWith("应用动作执行结果") }
    private inner class Client: ModelClient {
        val stages=mutableListOf<String>(); val inputs=mutableListOf<JSONArray>(); val uploads=mutableListOf<Int>()
        var streamChunkSize=0
        var handler: (String,JSONArray)->JSONObject={ _,input -> if(!hasResult(input)) plan("Makito M30 产品规格") else roleMessage("assistant","根据邮件及网页核对如下。") }
        override suspend fun test(profile: ModelProfile)=profile
        override fun generate(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?)=error("Use typed request")
        override fun generateRequest(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?,options: ModelRequestOptions)=flow {
            stages+=options.stage; inputs+=JSONArray(messages.toString()); uploads+=VisionRequestPlanner.imageCount(messages)
            assertEquals("disabled",profile.thinkingMode)
            val answer=handler(options.stage,messages)
            if(streamChunkSize>0) answer.optString("content").chunked(streamChunkSize).forEach { emit(ModelEvent.Delta(it)) }
            emit(ModelEvent.Completed(answer))
        }
    }
    private var processed=0
    private val processor=object: AttachmentProcessor {
        override suspend fun pdfCount(file: File)=1
        override suspend fun previewPdf(file: File,page: Int)=file
        override suspend fun process(attachment: Attachment,pages: List<Int>,onProgress: (String)->Unit): List<SourceChunk> {
            processed++
            return listOf(SourceChunk(messageId=attachment.messageId,attachmentId=attachment.id,title=attachment.name,location="图片",imagePath=attachment.localPath))
        }
    }
    private fun agent(client: ModelClient,search: WebSearchClient)=LocalAgent(db.dao(),MailRepositoryImpl(db,PlainTestSecrets(),app.filesDir),processor,client,search)
    private suspend fun conversation() { db.dao().putAccount(MailAccount(id="a",email="me@example.test")); db.dao().putConversation(Conversation(id="c",accountId="a")) }
    private suspend fun selectedMail(): List<Selection> {
        conversation()
        db.dao().putMessages(listOf(MailMessage("m","a","INBOX",1,1,"Makito M30 产品咨询","sender","personal@example.test",sentAt=0,body="请核对 Makito M30 产品的压力等级和接口尺寸。"),
            MailMessage("other","a","INBOX",1,2,"不得读取","sender","secret@example.test",sentAt=0,body="UNSELECTED_PRIVATE")))
        return listOf(Selection("m"))
    }
    @Test fun reasoningControlTextIsDisplayOnlyAndNeverExecutes(): Unit=runBlocking {
        conversation(); var searches=0
        val raw="核对公开资料。<｜DSML｜tool_calls><｜DSML｜invoke name=\"web_search\">"
        val service=object: WebSearchClient { override suspend fun search(config: ServiceConfig,query: String): List<SourceChunk> { searches++; return listOf(web) } }
        for(streaming in listOf(false,true)) {
            val thoughts=mutableListOf<String>()
            val client=object: ModelClient {
                override suspend fun test(profile: ModelProfile)=profile
                override fun generate(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?)=flow {
                    if(streaming) raw.chunked(1).forEach { emit(ModelEvent.Thinking(it)) }
                    emit(ModelEvent.Completed(roleMessage("assistant","尚未检索。").put("reasoning_content",raw)))
                }
            }
            val result=agent(client,service).run("a","INBOX",emptyList(),"说明情况",model,null,conversationId="c",onThinking={ thoughts+=it })
            assertEquals("核对公开资料。",thoughts.joinToString("")); assertEquals("尚未检索。",result.text)
        }
        assertEquals(0,searches); assertTrue(db.dao().allDrafts().isEmpty())
    }

    @Test fun dsmlOverHttpSseExecutesRealAgentSearchAndNeverLeaksWireFormat(): Unit=runBlocking {
        conversation()
        for(native in listOf(false,true)) {
            val server=MockWebServer(); server.start()
            try {
                fun sse(text: String)=text.chunked(1).joinToString("") { part ->
                    "data: "+JSONObject().put("choices",JSONArray().put(JSONObject().put("delta",JSONObject().put("content",part))))+"\n\n"
                }+"data: {\"choices\":[{\"delta\":{},\"finish_reason\":\"stop\"}]}\n\n"
                val raw="""先检索公开资料。<｜｜DSML｜｜ calls> <｜｜DSML｜｜ invoke name="web\_search"> <｜｜DSML｜｜ parameter name="queries" string="false">["GitHub Trending 今日热榜","GitHub trending repositories 2026年9月"]\</｜｜DSML｜｜ parameter> \</｜｜DSML｜｜ invoke> \</｜｜DSML｜｜ calls>"""
                server.enqueue(MockResponse().setHeader("Content-Type","text/event-stream").setBody(sse(raw)))
                server.enqueue(MockResponse().setHeader("Content-Type","text/event-stream").setBody(sse("依据实际检索结果汇总。[S1]")))
                val queries=java.util.Collections.synchronizedList(mutableListOf<String>()); val frames=mutableListOf<String>()
                val service=object: WebSearchClient { override suspend fun search(config: ServiceConfig,query: String)=listOf(web).also { queries+=query } }
                val profile=ModelProfile(model="fixture",baseUrl=server.url("/v1").toString(),supportsTools=native)
                val result=agent(CompatibleModelClient(PlainTestSecrets(),allowHttpForTests=true),service).run("a","INBOX",emptyList(),"检索公开项目热榜",profile,null,
                    conversationId="c",options=ChatRequestOptions(webSearch=true),onDelta={ frames+=it })
                assertEquals(setOf("GitHub Trending 今日热榜","GitHub trending repositories 2026年9月"),queries.toSet())
                assertEquals(2,queries.size); assertEquals(2,server.requestCount)
                assertEquals("依据实际检索结果汇总。[S1]",result.text); assertFalse(result.partial)
                assertFalse(frames.joinToString("").contains("DSML")); assertFalse(frames.joinToString("").contains("<｜"))
                server.takeRequest(); assertFalse(server.takeRequest().body.readUtf8().contains("DSML"))
                assertTrue(db.dao().allDrafts().isEmpty())
            } finally { server.shutdown() }
        }
    }

    @Test fun proseAndCompleteReadJsonWorksThroughSseWithoutLeakingProtocol(): Unit=runBlocking {
        conversation(); val server=MockWebServer(); server.start()
        try {
            fun sse(text: String)=text.chunked(2).joinToString("") { part ->
                "data: "+JSONObject().put("choices",JSONArray().put(JSONObject().put("delta",JSONObject().put("content",part))))+"\n\n"
            }+"data: {\"choices\":[{\"delta\":{},\"finish_reason\":\"stop\"}]}\n\n"
            val read="""搜索结果片段大多只显示了开头，我先读取几篇有实质内容的来源再汇总。
{"mailpilot_action":"read_web_page","arguments":{"source_ids":["S1"]}}"""
            for(text in listOf(plan("公开产品规范").getString("content"),read,"已核对原文中的参数。[S1]")) server.enqueue(MockResponse().setHeader("Content-Type","text/event-stream").setBody(sse(text)))
            var searches=0; var pages=0; val frames=mutableListOf<String>()
            val service=object: WebSearchClient { override suspend fun search(config: ServiceConfig,query: String)=listOf(web).also { searches++ } }
            val agent=agent(CompatibleModelClient(PlainTestSecrets(),allowHttpForTests=true),service).also { it.pageReader=WebPageReader { pages++; WebPage("公开产品规范中的完整参数。".repeat(10),"complete") } }
            val result=agent.run("a","INBOX",emptyList(),"核对公开产品规范",ModelProfile(model="fixture",baseUrl=server.url("/v1").toString(),supportsTools=false),null,conversationId="c",options=ChatRequestOptions(webSearch=true),onDelta={ frames+=it })
            assertEquals(1,searches); assertEquals(1,pages); assertEquals(3,server.requestCount)
            assertEquals("已核对原文中的参数。[S1]",result.text); assertFalse(result.partial)
            assertFalse(frames.joinToString("").contains("mailpilot_action")); assertTrue(db.dao().allDrafts().isEmpty())
        } finally { server.shutdown() }
    }
    @Test fun malformedReadFinalizesExistingEvidenceAndRetryResumesOnlyFinalAnswer(): Unit=runBlocking {
        conversation(); db.dao().putTurn(TurnSnapshot("format-resume","c","a","INBOX","[]",1))
        var searches=0; var pages=0; var attempt=0; var failFinal=true
        val service=object: WebSearchClient { override suspend fun search(config: ServiceConfig,query: String)=listOf(web).also { searches++ } }
        val client=Client().apply { handler={ phase,_ ->
            if(phase=="synthesis") {
                if(failFinal) { failFinal=false; throw java.io.IOException("fixture final interruption") }
                roleMessage("assistant","依据已有摘录回答，网页原文尚未核实。[T1:S1]")
            } else if(attempt++==0) plan("公开产品规范")
            else roleMessage("assistant","先读取原文。{\"mailpilot_action\":\"read_web_page\",\"arguments\":{\"source_ids\":[\"T1:S1\"]}")
        } }
        val agent=agent(client,service).also { it.pageReader=WebPageReader { pages++; error("Malformed decision must not execute") } }
        suspend fun ask()=agent.run("a","INBOX",emptyList(),"搜索并核对资料",model,null,conversationId="c",requestId="format-resume",options=ChatRequestOptions(webSearch=true))
        assertTrue(runCatching { ask() }.exceptionOrNull() is java.io.IOException)
        AgentCheckpoints.update(db.dao(),"format-resume") { cp ->
            cp.getJSONObject("actions").put("pending",roleMessage("assistant","").put("tool_calls",JSONArray().put(JSONObject()
                .put("id","legacy-invalid").put("type","function").put("function",JSONObject().put("name","read_web_page").put("arguments","{incomplete")))))
        }
        val answer=ask()
        assertTrue(answer.partial); assertEquals(1,searches); assertEquals(0,pages)
        assertEquals(listOf("answer","answer","synthesis","synthesis"),client.stages)
        assertTrue(db.dao().allDrafts().isEmpty())
    }
    @Test fun inlineSeedSearchStreamsNoMarkupAndCompletesThroughSameAgent(): Unit=runBlocking {
        val selected=selectedMail()
        for(native in listOf(false,true)) {
            val queries=java.util.Collections.synchronizedList(mutableListOf<String>()); val frames=mutableListOf<String>()
            val service=object: WebSearchClient { override suspend fun search(config: ServiceConfig,query: String)=listOf(web).also { queries+=query } }
            val client=Client().apply {
                streamChunkSize=1
                handler={ _,input -> if(!hasResult(input)) roleMessage("assistant","""我来检索两项公开主题。seed:tool_call<function name="web_search"><parameter name="queries" string="false">["Makito company Spain","plastic bar caddy PS"]</parameter></function></seed:tool_call>""")
                    else roleMessage("assistant","已根据实际检索来源完成核对。") }
            }
            val result=agent(client,service).run("a","INBOX",selected,"联网核对邮件里的公司与产品",model.copy(supportsTools=native),null,
                conversationId="c",options=ChatRequestOptions(webSearch=true),onDelta={ frames+=it })
            assertEquals(listOf("Makito company Spain","plastic bar caddy PS"),queries.sorted())
            assertEquals(listOf("answer","answer"),client.stages)
            assertEquals("已根据实际检索来源完成核对。",result.text)
            assertTrue(result.sources.any { it.kind=="web" })
            assertFalse(frames.joinToString("").contains("seed:")); assertFalse(frames.joinToString("").contains("<function"))
            assertFalse(client.inputs.last().toString().contains("seed:tool_call"))
        }
        assertTrue(db.dao().allDrafts().isEmpty())
    }
    @Test fun malformedInlineSearchIsTypedFailureWithoutSearchOrDraftEffects(): Unit=runBlocking {
        val selected=selectedMail(); var searched=0
        val service=object: WebSearchClient { override suspend fun search(config: ServiceConfig,query: String)=listOf(web).also { searched++ } }
        val client=Client().apply { streamChunkSize=1; handler={ _,_ -> roleMessage("assistant","正在准备。seed:tool_call<function name=\"web_search\">") } }
        val frames=mutableListOf<String>()
        val error=runCatching { agent(client,service).run("a","INBOX",selected,"联网核对",model,null,conversationId="c",options=ChatRequestOptions(webSearch=true),onDelta={ frames+=it }) }.exceptionOrNull()
        assertTrue(error is ModelFailure); assertEquals("action_format",(error as ModelFailure).info.type)
        assertEquals(0,searched); assertTrue(db.dao().allDrafts().isEmpty())
        assertEquals("正在准备。",frames.joinToString(""))
    }
    @Test fun seedEnvelopeOverHttpSseExecutesSearchThenRequestsFinalAnswer(): Unit=runBlocking {
        val selected=selectedMail(); val server=MockWebServer(); server.start()
        try {
            fun sse(text: String)=text.chunked(3).joinToString("") { part ->
                "data: "+JSONObject().put("choices",JSONArray().put(JSONObject().put("delta",JSONObject().put("content",part))))+"\n\n"
            }+"data: {\"choices\":[{\"delta\":{},\"finish_reason\":\"stop\"}]}\n\n"
            val envelope="""准备检索。<seed:tool_call><function name="web_search"><parameter name="queries" string="false">["Makito company"]</parameter></function></seed:tool_call>"""
            server.enqueue(MockResponse().setHeader("Content-Type","text/event-stream").setBody(sse(envelope)))
            server.enqueue(MockResponse().setHeader("Content-Type","text/event-stream").setBody(sse("根据返回来源，核对完成。")))
            var searched=0; val frames=mutableListOf<String>()
            val search=object: WebSearchClient { override suspend fun search(config: ServiceConfig,query: String)=listOf(web).also { searched++; assertEquals("Makito company",query) } }
            val client=CompatibleModelClient(PlainTestSecrets(),allowHttpForTests=true)
            val profile=ModelProfile(model="fixture",baseUrl=server.url("/v1").toString(),supportsTools=true)
            val result=withTimeout(15000) { agent(client,search).run("a","INBOX",selected,"联网核对",profile,null,conversationId="c",options=ChatRequestOptions(webSearch=true),onDelta={ frames+=it }) }
            assertEquals(1,searched); assertEquals(2,server.requestCount)
            assertEquals("根据返回来源，核对完成。",result.text)
            assertFalse(frames.joinToString("").contains("seed:"))
            server.takeRequest()
            val second=JSONObject(server.takeRequest().body.readUtf8()).getJSONArray("messages")
            assertTrue((0 until second.length()).any { second.getJSONObject(it).optString("role")=="tool" })
            assertFalse(second.toString().contains("seed:tool_call"))
            assertTrue(db.dao().allDrafts().isEmpty())
        } finally { server.shutdown() }
    }
    @Test fun threeDeicticQuestionsUseSelectedMaterialAndRecentScopeInsteadOfLooping(): Unit=runBlocking {
        val selected=selectedMail(); val history=mutableListOf<ChatEntry>(); val queries=mutableListOf<String>()
        val search=object: WebSearchClient { override suspend fun search(config: ServiceConfig,query: String)=listOf(web).also { queries+=query } }
        for(q in listOf("搜索一下网络上有没有相关的资料","关于邮件里面的内容","就这封邮件里面的附件相关信息")) {
            val c=Client(); val result=agent(c,search).run("a","INBOX",selected,q,model,null,history=history,conversationId="c",options=ChatRequestOptions(webSearch=true))
            val planning=c.inputs.first().toString()
            assertTrue(planning.contains("Makito M30")); assertFalse(planning.contains("UNSELECTED_PRIVATE"))
            if(history.isNotEmpty()) assertTrue(planning.contains(history.first().text))
            assertEquals(listOf("answer","answer"),c.stages)
            assertTrue(c.inputs.last().toString().contains("read_evidence"))
            assertTrue(result.sources.any { it.kind=="web" }); assertFalse(result.text.contains("具体关键词"))
            history+=ChatEntry(conversationId="c",role="user",text=q)
            history+=ChatEntry(conversationId="c",role="assistant",text=result.text)
        }
        assertEquals(3,queries.size); assertTrue(queries.all { it=="Makito M30 产品规格" })
        assertTrue(db.dao().allDrafts().isEmpty())
    }
    @Test fun threeImagesReadOnceThenReusedAcrossSearchFailureRetryAndFollowup(): Unit=runBlocking {
        conversation()
        val files=(1..3).map { n ->
            val file=File(app.filesDir,"search30-$n.png")
            val bitmap=Bitmap.createBitmap(32,32,Bitmap.Config.ARGB_8888)
            bitmap.eraseColor(n); file.outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG,100,it) }; bitmap.recycle()
            LocalMaterial(id="file$n",conversationId="c",name="产品$n.png",mime="image/png",path=file.path,size=file.length()).also { db.dao().putMaterial(it) }
        }
        db.dao().putTurn(TurnSnapshot("r","c","a","INBOX","[]",1,ChatRequestOptions(webSearch=true).json(),localJson=JSONArray(files.map { it.fields() }).toString()))
        var fail=true; var searched=0
        val search=object: WebSearchClient { override suspend fun search(config: ServiceConfig,query: String): List<SourceChunk> { searched++; if(fail) throw java.io.IOException("fixture"); return listOf(web) } }
        val c=Client().apply { handler={ stage,input ->
            if(stage=="vision") {
                val parts=(0 until input.length()).flatMap { i -> input.getJSONObject(i).optJSONArray("content")?.let { a -> (0 until a.length()).mapNotNull { a.optJSONObject(it) as? LocalImagePart } }.orEmpty() }
                roleMessage("assistant",JSONObject().put("results",JSONArray(parts.map { JSONObject().put("id",it.source.id).put("text","图片中是 Makito M30 压力调节设备") })).toString())
            } else if(!hasResult(input)) {
                assertTrue(input.toString().contains("Makito M30 压力调节设备")); assertEquals(0,VisionRequestPlanner.imageCount(input)); plan("Makito M30 产品规格")
            } else roleMessage("assistant","已结合此前图片分析和网页资料回答。")
        } }
        suspend fun ask(run: String="r",q: String="搜索附件相关信息")=agent(c,search).run("a","INBOX",emptyList(),q,model,null,conversationId="c",localMaterials=files,requestId=run,options=ChatRequestOptions(webSearch=true))
        assertTrue(runCatching { ask() }.exceptionOrNull() is WebSearchFailure)
        assertEquals(3,db.dao().visualEvidence("c","a").size)
        fail=false; ask(); ask("","再查一下它的适用范围")
        assertEquals(listOf(3),c.uploads.filter { it>0 }); assertEquals(3,processed)
        assertEquals(2,c.inputs.count { VisionRequestPlanner.imageCount(it)==0 && !hasResult(it) }); assertEquals(3,searched)
        assertTrue(db.dao().allDrafts().isEmpty())
    }
    @Test fun twoQueriesResumeOnlyMissingResultAfterFailureAndRestart(): Unit=runBlocking {
        conversation(); db.dao().putTurn(TurnSnapshot("r","c","a","INBOX","[]",1,"{}"))
        val requests=java.util.Collections.synchronizedList(mutableListOf<String>()); var fail=true
        val service=object: WebSearchClient { override suspend fun search(config: ServiceConfig,query: String): List<SourceChunk> {
            requests+=query; if(query=="第二个主题" && fail) throw java.io.IOException("fixture disconnect")
            return listOf(web.copy(url="https://example.test/"+query))
        } }
        val client=Client().apply { handler={ _,input -> if(!hasResult(input)) plan("第一个主题","第二个主题") else roleMessage("assistant","综合两项检索结果") } }
        suspend fun ask()=agent(client,service).run("a","INBOX",emptyList(),"总结所选邮件，并联网搜索一下相关资料",model,null,conversationId="c",requestId="r",options=ChatRequestOptions(webSearch=true,fastCompression=!fail))
        assertTrue(ask().partial)
        AgentCheckpoints.update(db.dao(),"r") { it.put("phase","search_retrieving") }
        recoverAgentRuns(db.dao()); assertEquals("failed",db.dao().history("c").single().resultStatus)
        fail=false; var requested=false
        client.handler={ _,_ -> if(!requested) { requested=true; plan("第一个主题","第二个主题") } else roleMessage("assistant","综合两项检索结果") }
        AgentCheckpoints.update(db.dao(),"r") { it.getJSONObject("actions").put("continueResearch",true) }
        val answer=ask()
        assertEquals(listOf("第一个主题","第二个主题","第二个主题").sorted(),requests.sorted())
        assertTrue(answer.sources.first { it.kind=="web" }.url.contains("第一个主题"))
        assertEquals(4,client.inputs.size); assertEquals(2,answer.sources.count { it.kind=="web" })
        assertEquals(listOf("answer","synthesis","answer","answer"),client.stages)
    }
    @Test fun savedLongSearchResultsFitWithoutModelCompression()=runBlocking {
        conversation(); db.dao().putTurn(TurnSnapshot("r","c","a","INBOX","[]",1,"{}"))
        val service=object: WebSearchClient { override suspend fun search(config: ServiceConfig,query: String)=
            (1..8).map { web.copy(title="长网页 $it",url="https://example.test/$it",text="有用的技术事实。".repeat(3000)) } }
        val client=Client()
        val small=model.copy(model="fixture",provider="compatible",baseUrl="https://example.test",contextTokens=18000,outputTokens=4096)
        val result=agent(client,service).run("a","INBOX",emptyList(),"搜索相关产品规格",small,null,conversationId="c",requestId="r",options=ChatRequestOptions(webSearch=true,fastCompression=true))
        assertEquals(listOf("answer","answer"),client.stages)
        assertEquals(8,result.sources.count { it.kind=="web" })
        assertTrue(result.sources.first().text.length>10000)
        ContextBudgetPlanner.requireFits(small,client.inputs.last())
    }
    @Test fun retrievalCacheMissNullAndCorruptionAreNotEmptyJsonAndContextIsIsolated(): Unit=runBlocking {
        conversation(); db.dao().putTurn(TurnSnapshot("r","c","a","INBOX","[]",1,"{}"))
        var calls=0
        val service=object: WebSearchClient { override suspend fun search(config: ServiceConfig,query: String)=listOf(web).also { synchronized(this) { calls++ } } }
        suspend fun run(key: String="context-a")=SearchWorkflow(db.dao(),service).run(JSONArray(listOf("主题一","主题二")),key,ServiceConfig(),"r",{},{})
        run(); run(); assertEquals(2,calls)
        AgentCheckpoints.update(db.dao(),"r") { it.getJSONObject("search").getJSONObject("results").put(stableId("主题二"),JSONObject.NULL) }
        run(); assertEquals(3,calls)
        AgentCheckpoints.update(db.dao(),"r") { it.getJSONObject("search").getJSONObject("results").put(stableId("主题一"),"malformed") }
        run(); assertEquals(4,calls)
        run("context-b"); assertEquals(6,calls)
    }
    @Test fun invalidActionsCannotReachServicesAndOrdinaryAnswersStaySingleRequest(): Unit=runBlocking {
        selectedMail(); var calls=0
        val service=object: WebSearchClient { override suspend fun search(config: ServiceConfig,query: String)=listOf(web).also { synchronized(this) { calls++ } } }
        for(raw in listOf("{\"mailpilot_action\":", "{\"mailpilot_action\":\"send_email\",\"arguments\":{}}", "{\"mailpilot_action\":\"web_search\",\"arguments\":{\"queries\":[null]}}", "{\"mailpilot_action\":\"web_search\",\"arguments\":{\"queries\":[\"one\",\"two\",\"three\"]}}")) {
            val c=Client().apply { handler={ _,_ -> roleMessage("assistant",raw) } }
            val error=runCatching { agent(c,service).run("a","INBOX",emptyList(),"继续处理",model,null,conversationId="c",options=ChatRequestOptions(webSearch=true)) }.exceptionOrNull()
            assertTrue(raw,error is ModelFailure); assertEquals("action_format",(error as ModelFailure).info.type)
        }
        val c=Client().apply { handler={ _,_ -> roleMessage("assistant","你好，有什么需要帮助的？") } }
        val result=agent(c,service).run("a","INBOX",emptyList(),"你好",model,null,conversationId="c")
        assertTrue(result.text.startsWith("你好")); assertEquals(1,c.inputs.size); assertEquals(0,calls)
        assertTrue(db.dao().allDrafts().isEmpty())
    }
    @Test fun onlySanitizedKeywordsReachSearchAndCancellationIsPreserved(): Unit=runBlocking {
        val safe=SearchPrivacy.publicText("产品 https://user:pass@example.test/private/order?token=secret#fragment API_KEY=hidden-secret")
        assertTrue(safe.contains("https://example.test")); assertFalse(safe.contains("private")); assertFalse(safe.contains("secret")); assertFalse(safe.contains("pass"))
        val sent=mutableListOf<String>(); var cancel=false
        val search=object: WebSearchClient { override suspend fun search(config: ServiceConfig,query: String): List<SourceChunk> { if(cancel) throw CancellationException("fixture"); sent+=query; return listOf(web) } }
        val workflow=SearchWorkflow(db.dao(),search)
        workflow.run(JSONArray(listOf("Makito 13800138000 personal@example.test sk-abcdefghijklmnop 官方资料")),"context",ServiceConfig(),"",{},{})
        assertEquals(1,sent.size); assertTrue(sent.single().contains("Makito")); assertFalse(sent.single().contains("@")); assertFalse(sent.single().contains("13800138000")); assertFalse(sent.single().contains("sk-"))
        cancel=true
        assertTrue(runCatching { workflow.run(JSONArray(listOf("另一个主题")),"context",ServiceConfig(),"",{},{}) }.exceptionOrNull() is CancellationException)
        assertEquals(1,sent.size)
    }
    @Test fun searchAgainCannotBecomeRedraftOrDisableSearchEvenWhenDraftExists(): Unit=runBlocking {
        val selected=selectedMail()
        val draft=Draft(id="old",accountId="a",to="recipient@example.test",subject="原稿",body="原正文")
        db.dao().putDraft(draft)
        val c=Client(); var requests=0
        val search=object: WebSearchClient { override suspend fun search(config: ServiceConfig,query: String)=listOf(web).also { requests++ } }
        val history=listOf(ChatEntry(conversationId="c",role="assistant",text="已起草",draftId="old"))
        val result=agent(c,search).run("a","INBOX",selected,"重新搜索附件资料",model,null,history=history,conversationId="c",options=ChatRequestOptions(webSearch=true))
        assertEquals(1,requests); assertEquals(listOf("answer","answer"),c.stages)
        assertNull(result.candidate); assertEquals(draft,db.dao().draft("old"))
    }
    @Test fun semanticRevisionWorksWithoutNativeToolsAndNeverSavesBeforeCompletion(): Unit=runBlocking {
        selectedMail(); val draft=Draft(id="old",accountId="a",to="keep@example.test",subject="主题",body="原正文",revision=3)
        db.dao().putDraft(draft)
        val history=listOf(ChatEntry(conversationId="c",role="assistant",text="已起草",draftId="old"))
        for(native in listOf(false,true)) {
            val c=Client().apply { handler={ _,input -> if(!hasResult(input)) roleMessage("assistant","{\"mailpilot_action\":\"revise_draft\",\"arguments\":{\"draft_id\":\"old\",\"body\":\"更加礼貌的新正文\"}}") else roleMessage("assistant","已调整，请核对新卡片。") } }
            val service=object: WebSearchClient { override suspend fun search(config: ServiceConfig,query: String): List<SourceChunk> = error("No web action requested") }
            val result=agent(c,service).run("a","INBOX",emptyList(),"语气再客气些，收件人照旧",model.copy(supportsTools=native),null,history=history,conversationId="c",options=ChatRequestOptions(webSearch=true))
            assertEquals("更加礼貌的新正文",result.candidate!!.draft.body); assertEquals("keep@example.test",result.candidate!!.draft.to)
            assertEquals(draft,db.dao().draft("old")); assertEquals(2,c.inputs.size)
            assertEquals(native,c.inputs.last().toString().contains("\"role\":\"tool\""))
        }
    }
    @Test fun nativeSearchToolUsesSameSchemaAndKeepsResultsOutOfUserInstructions(): Unit=runBlocking {
        val selected=selectedMail(); val sent=mutableListOf<String>()
        val service=object: WebSearchClient { override suspend fun search(config: ServiceConfig,query: String)=listOf(web).also { sent+=query } }
        val c=Client().apply { handler={ _,input -> if(!hasResult(input)) AgentActions.forCapabilities(true,false,true).normalize(plan("Makito M30 官方规范"),false) else roleMessage("assistant","根据实际来源核对。") } }
        agent(c,service).run("a","INBOX",selected,"帮我在网上核对这封邮件的附件",model.copy(supportsTools=true),null,conversationId="c",options=ChatRequestOptions(webSearch=true))
        assertEquals(1,sent.size); assertEquals(2,c.inputs.size)
        val result=c.inputs.last().getJSONObject(c.inputs.last().length()-1)
        assertEquals("tool",result.getString("role")); assertTrue(result.getString("content").contains("设备技术规范"))
    }
    @Test fun completedActionsResumeAfterFinalAnswerFailsWithoutRepeatingDecision(): Unit=runBlocking {
        conversation(); db.dao().putTurn(TurnSnapshot("r","c","a","INBOX","[]",1,"{}"))
        var queries=0; var fail=true
        val service=object: WebSearchClient { override suspend fun search(config: ServiceConfig,query: String)=listOf(web).also { queries++ } }
        val c=Client().apply { handler={ _,input -> if(!hasResult(input)) plan("产品技术主题") else if(fail) throw java.io.IOException("fixture") else roleMessage("assistant","最终回答") } }
        suspend fun ask()=agent(c,service).run("a","INBOX",emptyList(),"搜索相关产品资料",model,null,conversationId="c",requestId="r",options=ChatRequestOptions(webSearch=true))
        assertTrue(runCatching { ask() }.exceptionOrNull() is java.io.IOException)
        fail=false; assertEquals("最终回答",ask().text)
        assertEquals(1,queries); assertEquals(3,c.inputs.size); assertEquals(1,c.inputs.count { !hasResult(it) })
    }
    @Test fun ark32kFiveCachedImagesTwoLongSearchesAndRestart(): Unit=runBlocking {
        conversation()
        val files=(1..5).map { n ->
            val file=File(app.filesDir,"budget31-$n.png")
            val bitmap=Bitmap.createBitmap(32,32,Bitmap.Config.ARGB_8888); bitmap.eraseColor(n)
            file.outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG,100,it) }; bitmap.recycle()
            LocalMaterial(id="budget$n",conversationId="c",name="产品$n.png",mime="image/png",path=file.path,size=file.length()).also { db.dao().putMaterial(it) }
        }
        val p=ModelProfile(model="doubao-seed-evolving",baseUrl="https://ark.cn-beijing.volces.com/api/plan/v3",contextTokens=32768)
        var uploads=0; var calls=0; var fail=false; var searched=0
        val client=object: ModelClient {
            override suspend fun test(profile: ModelProfile)=profile
            override fun generate(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?)=error("typed")
            override fun generateRequest(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?,options: ModelRequestOptions)=flow {
                ContextBudgetPlanner.requireFits(profile,messages,tools); uploads+=VisionRequestPlanner.imageCount(messages); calls++
                val text=messages.toString()
                val answer=when {
                    options.stage=="compression" -> roleMessage("assistant","产品 Makito M30；日期2026-09-10，金额500元；来源覆盖本轮5张图片，具体细节需按来源继续读取。")
                    VisionRequestPlanner.imageCount(messages)>0 -> roleMessage("assistant","五张图片均为 Makito M30 产品介绍，日期2026-09-10、金额500元。")
                    !hasResult(messages) -> plan("Makito M30 规格","Makito M30 接口")
                    fail -> throw java.io.IOException("final reply fixture")
                    else -> { assertTrue(text.contains("未完整")); assertFalse(text.contains("UNSENT_TAIL")); roleMessage("assistant","根据5张图片此前分析和两条检索来源核对；摘录未覆盖部分仍需读取。") }
                }
                emit(ModelEvent.Completed(answer))
            }
        }
        val service=object: WebSearchClient { override suspend fun search(config: ServiceConfig,query: String): List<SourceChunk> {
            synchronized(this) { searched++ }; return (1..5).map { n -> web.copy(title="规范$n",url="https://example.test/${stableId(query)}/$n",text=("\\\"参数值😀\n|规格|值|".repeat(800))+"UNSENT_TAIL") }
        } }
        try {
            agent(client,service).run("a","INBOX",emptyList(),"总结图片",p,null,conversationId="c",localMaterials=files)
            assertEquals(5,uploads)
            db.dao().putTurn(TurnSnapshot("r31","c","a","INBOX","[]",1,localJson=JSONArray(files.map { it.fields() }).toString()))
            suspend fun ask()=agent(client,service).run("a","INBOX",emptyList(),"总结所选邮件，并联网搜索一下相关资料",p,null,conversationId="c",requestId="r31",localMaterials=files,options=ChatRequestOptions(webSearch=true))
            fail=true; assertTrue(runCatching { ask() }.exceptionOrNull() is java.io.IOException)
            val afterFailure=calls; fail=false; val result=ask()
            assertEquals(afterFailure+1,calls); assertEquals(2,searched); assertEquals(5,uploads); assertEquals(5,processed)
            assertEquals(8,result.sources.count { it.kind=="web" }); assertTrue(result.sources.filter { it.kind=="web" }.all { it.text.endsWith("UNSENT_TAIL") })
            assertTrue(db.dao().allDrafts().isEmpty())
        } finally { files.forEach { File(it.path).delete() } }
    }
    @Test fun incompleteActionJsonDoesNotLeakToStreamingAndUnknownActionsAreRejected() {
        val actions=AgentActions.forCapabilities(false,false,true)
        val wire="{\"mailpilot_action\":\"web_search\",\"arguments\":{\"queries\":[\"技术主题\"]}}"
        for(i in 1..wire.length) assertEquals("",actions.visible(wire.take(i)))
        assertEquals("普通文字",actions.visible("普通文字"))
        val normalized=actions.normalize(roleMessage("assistant",wire),false)
        assertEquals("web_search",normalized.getJSONArray("tool_calls").getJSONObject(0).getJSONObject("function").getString("name"))
        assertTrue(runCatching { actions.normalize(roleMessage("assistant",wire.replace("web_search","smtp_send")),false) }.exceptionOrNull() is ModelFailure)
    }

    @Test fun noNewSourcesFinalizesAndRetryOnlyRetriesSynthesis()=runBlocking {
        val selected=selectedMail(); db.dao().putTurn(TurnSnapshot("r34","c","a","INBOX",JsonCodec.selections(selected),1))
        var queryCount=0; var failFinal=true
        val service=object: WebSearchClient { override suspend fun search(config: ServiceConfig,query: String)=listOf(web).also { queryCount++ } }
        val client=Client().apply { handler={ stage,_ ->
            if(stage=="synthesis") { if(failFinal) throw java.io.IOException("offline"); roleMessage("assistant","依据 [T1:S2] 已有资料回答，尚有待核实部分。") }
            else plan("topic variant "+stages.size)
        } }
        val a=agent(client,service)
        suspend fun ask()=a.run("a","INBOX",selected,"搜索相关公开资料",model,null,conversationId="c",requestId="r34",options=ChatRequestOptions(webSearch=true))
        assertTrue(runCatching { ask() }.exceptionOrNull() is java.io.IOException)
        assertEquals(3,queryCount); assertEquals(listOf("answer","answer","answer","synthesis"),client.stages)
        val before=client.stages.size; failFinal=false
        val result=ask(); assertTrue(result.partial); assertEquals(before+1,client.stages.size); assertEquals(3,queryCount)
        val journal=AgentRunCheckpoint.from(db.dao().turn("r34")).data.getJSONObject("actions")
        journal.put("continueResearch",true)
        AgentCheckpoints.update(db.dao(),"r34") { it.put("actions",journal) }
        ask(); assertTrue(queryCount>3); assertTrue(db.dao().allDrafts().isEmpty())
    }
    @Test fun exhaustedLegacyJournalStillGetsOneFinalAnswer()=runBlocking {
        val selected=selectedMail(); db.dao().putTurn(TurnSnapshot("r34","c","a","INBOX",JsonCodec.selections(selected),1))
        val client=Client().apply { handler={ _,_-> throw java.io.IOException("before response") } }
        var searched=0
        val a=agent(client,object: WebSearchClient { override suspend fun search(config: ServiceConfig,query: String)=listOf(web).also { searched++ } })
        suspend fun ask()=a.run("a","INBOX",selected,"搜索",model,null,conversationId="c",requestId="r34",options=ChatRequestOptions(webSearch=true))
        runCatching { ask() }
        AgentCheckpoints.update(db.dao(),"r34") { it.getJSONObject("actions").apply { put("round",8); remove("research") } }
        client.handler={ stage,_ -> assertEquals("synthesis",stage); roleMessage("assistant","目前没有可核实的联网结果。") }
        val result=ask(); assertTrue(result.partial); assertEquals(0,searched)
    }
    @Test fun pageReadsReuseSuccessfulBodyAndStopRepeatedActions()=runBlocking {
        val selected=selectedMail(); var reads=0
        val client=Client().apply { handler={ stage,input -> when {
            stage=="synthesis" -> roleMessage("assistant","根据网页正文回答。")
            !hasResult(input) -> plan("public product")
            else -> roleMessage("assistant",JSONObject().put("mailpilot_action","read_web_page").put("arguments",JSONObject().put("source_ids",JSONArray(listOf("S2")))).toString())
        } } }
        val a=agent(client,object: WebSearchClient { override suspend fun search(config: ServiceConfig,query: String)=listOf(web) })
        a.pageReader=WebPageReader { reads++; WebPage("经核实的规格。".repeat(40),"complete") }
        val events=mutableListOf<AgentEvent>()
        val result=a.run("a","INBOX",selected,"搜索相关资料",model,null,conversationId="c",options=ChatRequestOptions(webSearch=true),onEvent={ events+=it })
        assertEquals(1,reads); assertTrue(result.partial); assertTrue(result.sources.any { it.location.startsWith("网页正文") })
        assertTrue(events.filterIsInstance<AgentEvent.ToolActivity>().any { it.kind=="read_web_page" && it.count==1 })
    }
    @Test fun finalAnswerCannotExecuteNativeOrTextualTools()=runBlocking {
        val selected=selectedMail(); var searches=0
        val client=Client().apply { handler={ _,_ -> plan("same query") } }
        val service=object: WebSearchClient { override suspend fun search(config: ServiceConfig,query: String)=listOf(web).also { searches++ } }
        val error=runCatching { agent(client,service).run("a","INBOX",selected,"搜索",model,null,conversationId="c",options=ChatRequestOptions(webSearch=true)) }.exceptionOrNull()
        assertTrue(error is ModelFailure); assertEquals(1,searches); assertTrue(client.stages.last()=="synthesis")
    }
}
