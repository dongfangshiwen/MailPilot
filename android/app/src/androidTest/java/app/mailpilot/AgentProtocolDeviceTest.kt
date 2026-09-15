package app.mailpilot

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

/** Opt-in public query only. Original mail and model settings remain read-only. */
@RunWith(AndroidJUnit4::class)
class AgentProtocolDeviceTest {
    @Test fun dsmlReplayUsesAgentAndKeepsProtocolOutOfDisplay(): Unit=runBlocking {
        val context=InstrumentationRegistry.getInstrumentation().targetContext
        val db=Room.inMemoryDatabaseBuilder(context,MailDatabase::class.java).build()
        try {
            val dao=db.dao(); dao.putConversation(Conversation(id="protocol-fixture"))
            for(native in listOf(false,true)) for(nonBreakingSpace in listOf(false,true)) {
                var requests=0
                val queries=java.util.Collections.synchronizedList(mutableListOf<String>())
                val frames=mutableListOf<String>(); val thoughts=mutableListOf<String>()
                val raw="""<｜｜DSML｜｜ calls><｜｜DSML｜｜ invoke name="web\_search"><｜｜DSML｜｜ parameter name="queries" string="false">["GitHub Trending 今日热榜","GitHub trending repositories 2026年9月"]\</｜｜DSML｜｜ parameter>\</｜｜DSML｜｜ invoke>\</｜｜DSML｜｜ calls>"""
                val wire=if(nonBreakingSpace) raw.replace("｜｜ ","｜｜\u00a0").replace("invoke name","invoke\u00a0name").replace("parameter name","parameter\u00a0name") else raw
                val client=object: ModelClient {
                    override suspend fun test(profile: ModelProfile)=profile
                    override fun generate(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?)=flow {
                        requests++
                        val answer=if(requests==1) "准备查询。$wire" else "根据实际返回的公开来源整理。[S1]"
                        ("正在核对。"+wire).chunked(1).forEach { emit(ModelEvent.Thinking(it)) }
                        answer.chunked(1).forEach { emit(ModelEvent.Delta(it)) }
                        emit(ModelEvent.Completed(roleMessage("assistant",answer)))
                    }
                }
                val search=object: WebSearchClient {
                    override suspend fun search(config: ServiceConfig,query: String): List<SourceChunk> {
                        queries+=query
                        return listOf(SourceChunk(messageId="",title="合成搜索结果",location="网页",text="公开项目资料（固定测试数据）。",kind="web",url="https://example.test/projects"))
                    }
                }
                val agent=LocalAgent(dao,MailRepositoryImpl(db,AndroidSecrets(),context.cacheDir),AndroidAttachmentProcessor(context),client,search)
                val result=agent.run("","INBOX",emptyList(),"检索公开项目热榜",ModelProfile(supportsTools=native,thinkingMode="disabled"),null,
                    conversationId="protocol-fixture",options=ChatRequestOptions(webSearch=true),onDelta={ frames+=it },onThinking={ thoughts+=it })
                assertEquals(2,requests); assertEquals(2,queries.size); assertFalse(result.partial)
                assertFalse((frames+thoughts).joinToString("").contains("DSML")); assertTrue(dao.allDrafts().isEmpty())
            }
        } finally { db.close() }
    }

    @Test fun configuredPublicSearch(): Unit=runBlocking {
        val args=InstrumentationRegistry.getArguments()
        assumeTrue(args.getString("realProvider")=="true")
        val context=InstrumentationRegistry.getInstrumentation().targetContext
        val graph=(context.applicationContext as MailPilotApp).graph; graph.ready.await()
        val settings=graph.preferences.flow.first()
        val modelName=args.getString("modelName") ?: "doubao-seed-evolving"
        val saved=graph.dao.models().first().first { it.model==modelName && it.apiKeyCipher.isNotBlank() }
        val model=ModelOutputPolicy.resolve(ModelContextPolicy.resolve(saved,settings.contextModes[saved.id]),settings.outputModes[saved.id])
        val db=Room.inMemoryDatabaseBuilder(context,MailDatabase::class.java).build()
        val root=File(context.cacheDir,"agent-protocol-fixture")
        val requests=JSONArray(); var searches=0; val activities=mutableListOf<AgentEvent.ToolActivity>()
        val started=System.nanoTime()
        val readPage=args.getString("readPage")=="true"
        val selectedLink=args.getString("selectedLink")=="true"
        val linkFixture=if(args.getString("fixturePage")=="dynamic") "https://www.nuonuo.com/nuonuo/web/aboutone/index/index.html" else "https://jsoup.org/"
        val account=if(selectedLink) "link-fixture-account" else ""
        val selection=if(selectedLink) listOf(Selection("link-fixture-mail")) else emptyList()
        try {
            val dao=db.dao()
            if(selectedLink) {
                dao.putAccount(MailAccount(id=account,email="fixture@example.test"))
                dao.putMessages(listOf(MailMessage("link-fixture-mail",account,"INBOX",1,1,"网页资料通知（合成）","测试","fixture@example.test",sentAt=0,
                    body="请查看产品资料页面，介绍其用途。按钮：查看资料。",html="<p>产品资料</p><a href=\"$linkFixture\">查看资料</a>")))
            }
            dao.putConversation(Conversation(id="protocol-fixture",accountId=account))
            dao.putTurn(TurnSnapshot("protocol-run","protocol-fixture",account,"INBOX",JsonCodec.selections(selection),1))
            val client=object: ModelClient {
                override suspend fun test(profile: ModelProfile)=profile
                override fun generate(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?)=error("typed requests only")
                override fun generateRequest(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?,options: ModelRequestOptions)=flow {
                    val begin=System.nanoTime(); val row=JSONObject().put("stage",options.stage)
                    try { graph.models.generateRequest(profile,messages,tools,forceStream,options).collect { event ->
                        if(event is ModelEvent.Completed) {
                            val envelope=runCatching { ActionJson.parse(event.message.optString("content")) }
                            row.put("textCalls",envelope.getOrNull()?.calls?.length() ?: 0).put("textWithProse",envelope.getOrNull()?.bare==false).put("invalidEnvelope",envelope.isFailure)
                            val inline=runCatching { InlineToolCalls.parse(event.message.optString("content")) }
                            row.put("inlineCalls",inline.getOrNull()?.length() ?: 0).put("invalidInline",inline.isFailure)
                            // Record only control tag names, never attributes, arguments or answer text.
                            val tags=Regex("""</?(?:seed:tool_call|function|parameter|[｜|]{1,2}DSML[｜|]{1,2}\s*(?:tool_calls|function_calls|calls|invoke|parameter))(?=[\s>]|$)""")
                                .findAll(event.message.optString("content")).take(40).map { it.value }.toList()
                            row.put("controlTags",JSONArray(tags))
                        }
                        if(event is ModelEvent.Diagnostics) row.put("finishReason",event.value.optString("finishReason"))
                        emit(event)
                    } } finally { requests.put(row.put("elapsedMs",(System.nanoTime()-begin)/1_000_000)) }
                }
            }
            val search=object: WebSearchClient { override suspend fun search(config: ServiceConfig,query: String)=graph.webSearch.search(config,query).also { synchronized(requests) { searches++ } } }
            val agent=LocalAgent(dao,MailRepositoryImpl(db,graph.secrets,root),AndroidAttachmentProcessor(context),client,search,webStorage=File(root,"web"))
                .apply { pageReader=app.mailpilot.services.PublicWebReader(app.mailpilot.services.AndroidWebRenderer(context)) }
            val query=args.getString("publicQuery") ?: if(selectedLink) "总结所选邮件，并查看里面的链接内容，简短介绍产品用途，不起草或发送邮件。" else if(readPage) "搜 OpenAI，必须打开一个官网来源核对原文后再简短介绍，不起草或发送邮件。" else "搜 OpenAI，核对需要的公开来源后简短介绍，不起草或发送邮件。"
            val visible=StringBuilder()
            val result=withTimeout(600000) { agent.run(account,"INBOX",selection,query,model,null,conversationId="protocol-fixture",requestId="protocol-run",searchConfig=settings.search,
                options=ChatRequestOptions(webSearch=!selectedLink,fastCompression=true),onDelta={ visible.append(it) },onEvent={ if(it is AgentEvent.ToolActivity) activities+=it }) }
            val leaked=visible.contains("DSML")
            val report=JSONObject().put("realProvider",true).put("realSearch",!selectedLink).put("selectedMailLink",selectedLink).put("model",model.model).put("elapsedMs",(System.nanoTime()-started)/1_000_000)
                .put("searchQueries",searches).put("requests",requests).put("answerCharacters",result.text.length).put("partial",result.partial)
                .put("pagesRead",activities.filter { it.kind=="read_web_page" && it.state=="completed" }.sumOf { it.count })
                .put("sources",result.sources.count { it.kind=="web" }).put("drafts",dao.allDrafts().size).put("protocolLeaked",leaked)
                .put("pageStates",JSONArray(result.sources.filter { it.kind=="web" }.map { it.webReadStatus }))
                .put("incompletePageDisclosed",Regex("未完整|不完整|未确认完整|未核实|部分资源|加载失败|片段|不保证|未能完整|未完全").containsMatchIn(result.text))
            val filename=if(selectedLink) "agent-selected-mail-link.json" else if(readPage) "agent-protocol-public-search-read.json" else "agent-protocol-public-search.json"
            File(context.getExternalFilesDir(null),filename).writeText(report.toString(2))
            if(selectedLink) {
                assertEquals(0,searches); assertTrue(report.getInt("pagesRead")>0)
                val page=result.sources.single { it.messageId=="link-fixture-mail" && it.kind=="web" }
                assertTrue(page.text.length>300); assertTrue(page.retrieval in listOf("webpage","webpage_partial"))
                if(page.retrieval=="webpage_partial") assertTrue(report.getBoolean("incompletePageDisclosed"))
            }
            else assertTrue(searches>0)
            assertTrue(result.text.isNotBlank()); assertFalse(result.text.contains("mailpilot_action")); assertFalse(result.text.contains("DSML")); assertFalse(leaked); assertTrue(dao.allDrafts().isEmpty())
        } catch(e: Exception) {
            File(context.getExternalFilesDir(null),"agent-protocol-failed.json").writeText(JSONObject().put("realProvider",true).put("model",model.model)
                .put("elapsedMs",(System.nanoTime()-started)/1_000_000).put("searchQueries",searches).put("requests",requests)
                .put("status","failed").put("failureType",(e as? ModelFailure)?.info?.type ?: e.javaClass.simpleName).toString(2))
            throw e
        } finally { db.close(); root.deleteRecursively() }
    }
}
