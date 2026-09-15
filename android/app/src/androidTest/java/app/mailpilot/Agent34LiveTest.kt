package app.mailpilot

import android.graphics.*
import androidx.room.Room
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import app.mailpilot.ai.*
import app.mailpilot.attachments.AndroidAttachmentProcessor
import app.mailpilot.data.*
import app.mailpilot.mail.MailRepositoryImpl
import app.mailpilot.services.WebSearchClient
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import org.json.*
import org.junit.Test
import org.junit.Assume.assumeTrue
import org.junit.Assert.*
import org.junit.runner.RunWith
import java.io.File
import java.io.IOException

/** Opt-in real model benchmark. Only synthetic mail/images/history leave the device.
 * Real configured search; synthetic in-memory mailbox, no SMTP credentials. */
@RunWith(AndroidJUnit4::class)
class Agent34LiveTest {
    @Test fun realConfiguredModels(): Unit=runBlocking {
        val args=InstrumentationRegistry.getArguments()
        assumeTrue(args.getString("realProvider34")=="true")
        val context=InstrumentationRegistry.getInstrumentation().targetContext
        val graph=(context.applicationContext as MailPilotApp).graph; graph.ready.await()
        val settings=graph.preferences.flow.first()
        val profiles=graph.dao.models().first().filter { it.model=="doubao-seed-evolving" && it.apiKeyCipher.isNotBlank() }
        val report=JSONArray(); val tag=args.getString("benchmarkTag") ?: "current"
        val output=File(context.getExternalFilesDir(null),"agent34-live-$tag.json")
        for(saved in profiles) {
            val db=Room.inMemoryDatabaseBuilder(context,MailDatabase::class.java).build()
            val files=mutableListOf<File>()
            try {
                val dao=db.dao(); dao.putAccount(MailAccount(id="bench",email="fixture@example.test"))
                dao.putConversation(Conversation(id="bench",accountId="bench"))
                val mail=MailMessage("mail","bench","INBOX",1,1,"公开技术交流会","Example","fixture@example.test",sentAt=1,body="请李明参加2026-09-15的技术交流会，预算500元，讨论USB-C接口及USB Power Delivery。五张图片是合成编号卡片。")
                dao.putMessages(listOf(mail))
                val materials=(1..5).map { n ->
                    val f=File.createTempFile("agent34-$n-",".png",context.cacheDir).also { files+=it }
                    val bitmap=Bitmap.createBitmap(256,160,Bitmap.Config.ARGB_8888)
                    Canvas(bitmap).apply { drawColor(Color.WHITE); drawText("CARD $n",20f,90f,Paint().apply { color=Color.BLACK;textSize=36f }) }
                    f.outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG,100,it) }; bitmap.recycle()
                    LocalMaterial("image$n","bench","卡片$n.png","image/png",f.path,f.length()).also { dao.putMaterial(it) }
                }
                val profile=ModelOutputPolicy.resolve(ModelContextPolicy.resolve(saved,settings.contextModes[saved.id]),settings.outputModes[saved.id]).copy(thinkingMode="enabled")
                val helper=profiles.firstOrNull { it.provider=="volcengine" }?.let { ModelOutputPolicy.resolve(ModelContextPolicy.resolve(it,settings.contextModes[it.id]),settings.outputModes[it.id]) }
                val history=(1..4).flatMap { n -> listOf(ChatEntry(id="u$n",conversationId="bench",role="user",text="本次只整理公开技术资料，保留姓名日期金额，不发送邮件。".repeat(24),createdAt=n*2L),ChatEntry(id="a$n",conversationId="bench",role="assistant",text="已确认技术交流主题为USB-C和USB Power Delivery，需核对来源。".repeat(24),createdAt=n*2L+1)) }
                var queries=0; var inject=false; var requestNo=0
                val samples=JSONArray()
                val client=object: ModelClient {
                    override suspend fun test(profile: ModelProfile)=profile
                    override fun generate(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?)=error("typed")
                    override fun generateRequest(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?,options: ModelRequestOptions)=flow {
                        if(inject && options.stage=="answer") { inject=false; throw IOException("synthetic failure before request") }
                        val start=System.nanoTime(); var firstText: Long?=null; var firstThinking: Long?=null
                        val sample=JSONObject().put("stage",options.stage).put("model",profile.model).put("thinking",profile.thinkingMode)
                            .put("images",VisionRequestPlanner.imageCount(messages)).put("inputEstimate",ContextBudgetPlanner.estimate(messages,tools,profile))
                            .put("request",++requestNo)
                        try { graph.models.generateRequest(profile,messages,tools,forceStream,options).collect { event ->
                            if(event is ModelEvent.Thinking && firstThinking==null) firstThinking=(System.nanoTime()-start)/1_000_000
                            if(event is ModelEvent.Delta && firstText==null) firstText=(System.nanoTime()-start)/1_000_000
                            if(event is ModelEvent.Diagnostics) for(k in listOf("finishReason","firstByteMs","lastByteMs","elapsedMs","httpStatus")) if(event.value.has(k)) sample.put(k,event.value.get(k))
                            emit(event)
                        } } finally { samples.put(sample.put("totalMs",(System.nanoTime()-start)/1_000_000).put("firstTextMs",firstText).put("firstThinkingMs",firstThinking)) }
                    }
                }
                val search=object: WebSearchClient { override suspend fun search(config: ServiceConfig,query: String): List<SourceChunk> {
                    synchronized(this) { queries++ }; return graph.webSearch.search(config,query)
                } }
                val agent=LocalAgent(dao,MailRepositoryImpl(db,graph.secrets,context.filesDir),AndroidAttachmentProcessor(context),client,search,webStorage=File(context.cacheDir,"agent34-web-$tag"))
                val results=JSONArray(); var prior=history
                for((n,kind) in listOf("cold","warm","retry").withIndex()) {
                    val id="run$n"; val q=if(n==0) "总结所选邮件和五张卡片，并联网搜索USB-C及USB Power Delivery相关资料。保留姓名日期预算。回答控制在200字，不起草。" else "沿用此前卡片分析，结合已知资料简述USB-C与USB Power Delivery的区别，不重新核对图片。"
                    dao.putTurn(TurnSnapshot(id,"bench","bench","INBOX",JsonCodec.selections(listOf(Selection("mail",emptyList()))),n+1,localJson=JSONArray(materials.map { it.fields() }).toString()))
                    val beforeRequests=requestNo; val beforeQueries=queries; val start=System.nanoTime()
                    val activities=mutableListOf<AgentEvent.ToolActivity>()
                    val opts=ChatRequestOptions(thinking="enabled",webSearch=true,fastCompression=true)
                    suspend fun ask()=agent.run("bench","INBOX",listOf(Selection("mail",emptyList())),q,profile,helper,prior,conversationId="bench",requestId=id,localMaterials=materials,options=opts,searchConfig=settings.search,onEvent={ if(it is AgentEvent.ToolActivity) activities+=it })
                    var failure=""; var answer: AnalysisResult?=null
                    try {
                        if(kind=="retry") { inject=true; val error=runCatching { ask() }.exceptionOrNull(); if(error !is IOException) throw IllegalStateException("retry_preflight_"+(error?.javaClass?.simpleName ?: "no_failure")) }
                        answer=withTimeout(600000) { ask() }
                    } catch(e: Exception) { failure=if(e is ModelFailure) e.info.type else e.javaClass.simpleName+":"+e.message?.take(160) }
                    results.put(JSONObject().put("case",kind).put("totalMs",(System.nanoTime()-start)/1_000_000).put("requests",requestNo-beforeRequests).put("searchQueries",queries-beforeQueries).put("failure",failure).put("answerCharacters",answer?.text?.length ?: 0).put("pagesRead",activities.filter { it.kind=="read_web_page" && it.state=="completed" }.sumOf { it.count }).put("reusedOperations",activities.count { it.kind=="reuse" && it.state=="completed" }).put("partial",answer?.partial ?: false))
                    if(answer!=null) prior=prior+ChatEntry(conversationId="bench",role="user",text=q)+ChatEntry(conversationId="bench",role="assistant",text=answer.text,sourcesJson=JsonCodec.sources(answer.sources))
                }
                assertTrue(dao.allDrafts().isEmpty())
                report.put(JSONObject().put("model",profile.model).put("context",profile.contextTokens).put("cases",results).put("requests",samples))
                output.writeText(JSONObject().put("tag",tag).put("realModel",true).put("realSearch",true).put("syntheticData",true).put("models",report).toString(2))
            } finally { db.close(); files.forEach { it.delete() }; File(context.cacheDir,"agent34-web-$tag").deleteRecursively() }
        }
        assertTrue(profiles.isNotEmpty())
    }
    @Test fun realPublicPageCache(): Unit=runBlocking {
        assumeTrue(InstrumentationRegistry.getArguments().getString("realProvider34")=="true")
        val context=InstrumentationRegistry.getInstrumentation().targetContext
        val db=Room.inMemoryDatabaseBuilder(context,MailDatabase::class.java).build()
        val root=File(context.cacheDir,"agent34-page-cache"); var requests=0
        val started=System.nanoTime()
        try {
            val store=WebEvidenceStore(root,"fixture","fixture")
            val reader=app.mailpilot.services.PublicWebReader()
            val workflow=WebReadWorkflow(db.dao(),app.mailpilot.services.WebPageReader { requests++; reader.read(it) },store)
            val progress=ResearchProgress(JSONObject())
            var sources=listOf(SourceChunk(id="S1",messageId="",title="Example domains",location="public source",kind="web",url="https://www.iana.org/help/example-domains",text="IANA example domains"))
            val first=workflow.run(listOf("S1"),sources,progress,2048,"example domains","") { sources=it }
            assertEquals(1,first.count); assertTrue(sources.single().contentKey.isNotBlank())
            sources=JsonCodec.sources(JsonCodec.sources(sources))
            val second=workflow.run(listOf("S1"),sources,progress,2048,"example domains","") { sources=it }
            assertEquals(0,second.count); assertEquals(1,requests)
            File(context.getExternalFilesDir(null),"agent34-page-cache.json").writeText(JSONObject().put("realHttp",true).put("networkRequests",requests).put("pagesRead",first.count).put("restoredWithoutNetwork",true).put("elapsedMs",(System.nanoTime()-started)/1_000_000).toString(2))
        } finally { db.close(); root.deleteRecursively() }
    }
}
