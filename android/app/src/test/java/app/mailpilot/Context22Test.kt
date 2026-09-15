package app.mailpilot

import android.app.Application
import androidx.room.Room
import app.mailpilot.ai.*
import app.mailpilot.data.*
import app.mailpilot.attachments.*
import app.mailpilot.mail.*
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import org.json.*
import org.junit.*
import org.junit.Assert.*
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import java.io.IOException
import java.io.File

@RunWith(RobolectricTestRunner::class)
@Config(sdk=[28],application=Application::class)
class Context22Test {
    private lateinit var db: MailDatabase
    private val profile=ModelProfile(model="fixture",contextTokens=16384,outputTokens=1024,thinkingMode="disabled")
    private val facts="目标：周五交付；预算 500 元。修正：收件人改为 li@example.test。待办：确认日期。[T1:S1]"
    @Before fun setup() { db=Room.inMemoryDatabaseBuilder(RuntimeEnvironment.getApplication(),MailDatabase::class.java).allowMainThreadQueries().build() }
    @After fun close() { db.close() }
    private class Client(val answer: (Int)->String): ModelClient {
        val requests=mutableListOf<String>()
        override fun generate(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?)=flow {
            assertNull(tools); requests+=messages.toString(); ContextBudgetPlanner.requireFits(profile,messages)
            emit(ModelEvent.Completed(roleMessage("assistant",answer(requests.size))))
        }
        override suspend fun test(profile: ModelProfile)=profile
    }
    private suspend fun turn() {
        db.dao().putConversation(Conversation(id="c"))
        db.dao().putTurn(TurnSnapshot("run","c","","INBOX","[]",1))
    }
    @Test fun thresholdUses95PercentOfInputAndTarget60() {
        val limit=ContextBudgetPlanner.Limits(10000,8000)
        assertEquals(7600,limit.trigger); assertEquals(4800,limit.target)
        assertFalse(limit.needsCompression(7599)); assertTrue(limit.needsCompression(7600)); assertTrue(limit.needsCompression(7601))
        assertEquals(15360,ContextBudgetPlanner.limits(profile).input)
    }
    @Test fun catalogMatchesOfficialEndpointAndRespectsManualValue() {
        val evolving=profile.copy(baseUrl="https://ark.cn-beijing.volces.com/api/v3",model="doubao-seed-evolving",contextTokens=32768)
        assertEquals(1048576,ModelContextPolicy.resolve(evolving).contextTokens)
        assertEquals(32768,ModelContextPolicy.resolve(evolving,"custom").contextTokens)
        assertEquals(65536,ModelContextPolicy.resolve(evolving.copy(contextTokens=65536)).contextTokens)
        for(url in listOf("https://proxy.test/v1","https://ark.cn-beijing.volces.com/api/coding/v3","https://ark.cn-beijing.volces.com.evil.test/api/v3")) {
            assertNull(ModelCapabilityResolver.contextEntry(evolving.copy(baseUrl=url)))
            assertEquals(32768,ModelContextPolicy.resolve(evolving.copy(baseUrl=url)).contextTokens)
        }
        assertEquals(262144,ModelCapabilityResolver.defaultHelper(ModelContextPolicy.resolve(evolving))!!.contextTokens)
        assertEquals("unsupported",ModelCapabilityResolver.vision(evolving.copy(provider="deepseek",model="deepseek-v4-pro")))
    }
    @Test fun aliyunInputDependsOnModeAndContextIsNotBinaryMillion() {
        val q=profile.copy(baseUrl="https://dashscope.aliyuncs.com/compatible-mode/v1",model="qwen3.8-max",contextTokens=1000000)
        assertEquals(991808,ContextBudgetPlanner.limits(q).input)
        assertEquals(983616,ContextBudgetPlanner.limits(q.copy(thinkingMode="enabled")).input)
        assertEquals(1000000,ModelCapabilityResolver.contextEntry(q)!!.context)
    }
    @Test fun unicodeSplitsLosslesslyAndBinaryImagesAreNotText() {
        val text="中😀e\n\"".repeat(50)
        val chunks=ContextBudgetPlanner.chunks(text,31)
        assertEquals(text,chunks.joinToString("")); assertTrue(chunks.all { ContextBudgetPlanner.estimate(it)<=31 })
        assertTrue(chunks.none { it.first().isLowSurrogate() || it.last().isHighSurrogate() })
        val m=JSONArray().put(JSONObject().put("role","user").put("content",JSONArray().put(JSONObject().put("type","image_url").put("image_url",JSONObject().put("url","data:image/png;base64,"+"A".repeat(100000))))))
        assertTrue(ContextBudgetPlanner.estimate(m,includeUncertainImages=true) in 8192..10000)
        assertTrue(ContextBudgetPlanner.estimate(m)<1000)
    }
    @Test fun oversizedSummaryRepairsAndRetainsFacts()=runBlocking {
        turn(); val client=Client { if(it==1) "长".repeat(900) else facts }
        val result=ContextReducer(db.dao(),client).reduce(listOf("完整历史"),"",700,profile,"run")
        assertEquals(facts,result); assertEquals(2,client.requests.size)
        assertTrue(client.requests[1].contains("长")); assertTrue(db.dao().conversation("c")!!.contextSummary.isEmpty())
    }
    @Test fun slightOvershootOfSuggestedSizeFitsHardBudget()=runBlocking {
        val client=Client { "a".repeat(300) }
        assertEquals(300,ContextReducer(db.dao(),client).reduce(listOf("history"),"",800,profile).length)
        assertEquals(1,client.requests.size)
    }
    @Test fun twoExtraAttemptsAreSharedAcrossTheTurn()=runBlocking {
        turn(); val client=Client { "长".repeat(600) }
        val failure=runCatching { ContextReducer(db.dao(),client).reduce(listOf("old"),"",500,profile,"run") }.exceptionOrNull()!!
        assertEquals("compression_too_long",FailureInfo.from(failure).type); assertEquals(3,client.requests.size)
        runCatching { ContextReducer(db.dao(),client).reduce(listOf("material"),"",500,profile,"run","materials") }
        assertEquals(4,client.requests.size)
        assertEquals(2,AgentRunCheckpoint.from(db.dao().turn("run")).data.getJSONObject("compressionRepair").getInt("attempts"))
    }
    @Test fun emptyAndNullAreTypedWithoutBlindRetries()=runBlocking {
        for(answer in listOf("","null","  ")) {
            val client=Client { answer }
            val failure=runCatching { ContextReducer(db.dao(),client).reduce(listOf("history"),"",500,profile) }.exceptionOrNull()!!
            assertEquals("compression_empty",FailureInfo.from(failure).type); assertEquals(1,client.requests.size)
        }
    }
    @Test fun resumeSkipsValidatedBatchesAndChangedInputInvalidatesCache()=runBlocking {
        turn(); val blocks=listOf("A".repeat(4500),"B".repeat(4500),"C".repeat(4500))
        val first=Client { if(it==2) throw IOException("offline") else facts }
        assertTrue(runCatching { ContextReducer(db.dao(),first).reduce(blocks,"",600,profile,"run") }.isFailure)
        val saved=AgentRunCheckpoint.from(db.dao().turn("run")).data.getJSONObject("compression").getJSONObject("history")
        assertEquals(1,saved.getInt("batch"))
        val resumed=Client { facts }; ContextReducer(db.dao(),resumed).reduce(blocks,"",600,profile,"run")
        assertFalse(resumed.requests.first().contains("A".repeat(100)))
        val changed=Client { facts }; ContextReducer(db.dao(),changed).reduce(blocks,"",600,profile.copy(outputTokens=2048),"run")
        assertTrue(changed.requests.first().contains("A".repeat(100)))
    }
    @Test fun cancellationAndOutputLimitNeverAdvanceCursor()=runBlocking {
        turn()
        for(error in listOf(CancellationException("stop"),ModelFailure(FailureInfo("output_limit","limit")))) {
            val failure=runCatching { ContextReducer(db.dao(),Client { throw error }).reduce(listOf("history"),"",600,profile,"run") }.exceptionOrNull()!!
            if(error is ModelFailure) assertEquals("compression_output_limit",FailureInfo.from(failure).type)
            assertFalse(AgentRunCheckpoint.from(db.dao().turn("run")).data.has("compression"))
        }
    }
    @Test fun atomicSummaryDoesNotOverwriteConcurrentMemory()=runBlocking {
        db.dao().putConversation(Conversation(id="c",contextSummary="updated",summaryThroughId="e2"))
        assertEquals(0,db.dao().commitContext("c","","old","e1","new","e3",3))
        assertEquals("updated",db.dao().conversation("c")!!.contextSummary)
    }
    @Test fun explicitServerContextErrorsHaveCorrectRecoveryAction() {
        assertEquals("context_limit",FailureInfo.http(400,"""{"error":{"code":"context_length_exceeded"}}""").type)
        assertEquals("model_config",FailureInfo.http(400,"""{"error":{"message":"maximum context length exceeded"}}""").action)
    }
    @Test fun datastoreModesSurviveRecreationWithoutChangingOtherSettings()=runBlocking {
        val app=RuntimeEnvironment.getApplication()
        val preferences=Preferences(app)
        val p=profile.copy(id="context22-auto",baseUrl="https://ark.cn-beijing.volces.com/api/v3",model="doubao-seed-evolving",contextTokens=32768)
        preferences.set("theme","dark"); preferences.ensureContextModes(listOf(p,p.copy(id="context22-custom",contextTokens=65536)))
        assertEquals("auto",Preferences(app).flow.first().contextModes[p.id])
        assertEquals("custom",Preferences(app).flow.first().contextModes["context22-custom"])
        preferences.contextMode(p.id,"custom"); preferences.ensureContextModes(listOf(p))
        assertEquals("custom",Preferences(app).flow.first().contextModes[p.id]); assertEquals("dark",Preferences(app).flow.first().theme)
        preferences.contextMode(p.id,null); preferences.contextMode("context22-custom",null)
    }
    private fun agent(client: ModelClient): LocalAgent {
        val processor=object: AttachmentProcessor {
            override suspend fun pdfCount(file: File): Int=error("No file access allowed")
            override suspend fun previewPdf(file: File,page: Int): File=error("No preview allowed")
            override suspend fun process(attachment: Attachment,pages: List<Int>,onProgress: (String)->Unit): List<SourceChunk> =error("Unselected files must not be accessed")
        }
        return LocalAgent(db.dao(),MailRepositoryImpl(db,PlainTestSecrets(),RuntimeEnvironment.getApplication().filesDir),processor,client)
    }
    @Test fun agentPreflightsHistoryAndRetainsTwoRecentTurns(): Unit=runBlocking {
        turn()
        val history=(0..11).map { ChatEntry(id="e$it",conversationId="c",role=if(it%2==0) "user" else "assistant",text=if(it<8) "old-$it "+"事实".repeat(1000) else "recent-$it 周五预算500元") }
        history.forEach { db.dao().putEntry(it) }
        var summaries=0; var answers=0
        val client=object: ModelClient {
            override suspend fun test(profile: ModelProfile)=profile
            override fun generate(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?)=error("Typed request required")
            override fun generateRequest(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?,options: ModelRequestOptions)=flow {
                ContextBudgetPlanner.requireFits(profile,messages,tools)
                if(options.stage=="compression") { summaries++; emit(ModelEvent.Completed(roleMessage("assistant",facts))) }
                else {
                    answers++; assertTrue(ContextBudgetPlanner.estimate(messages,tools)<=ContextBudgetPlanner.limits(profile).target)
                    (8..11).forEach { assertTrue(messages.toString().contains("recent-$it")) }
                    assertFalse(messages.toString().contains("事实".repeat(200)))
                    emit(ModelEvent.Completed(roleMessage("assistant","继续完成周五任务")))
                }
            }
        }
        agent(client).run("","INBOX",emptyList(),"继续核对",profile,null,history=history,conversationId="c",requestId="run")
        assertTrue(summaries>0); assertEquals(1,answers); assertEquals(history,db.dao().history("c")); assertTrue(db.dao().allDrafts().isEmpty())
        assertEquals("e7",db.dao().conversation("c")!!.summaryThroughId)
    }
    @Test fun recentTurnsMayExceed60PercentTargetWithoutFailingAValidRequest(): Unit=runBlocking {
        turn()
        val history=(0..7).map { ChatEntry(id="soft$it",conversationId="c",role=if(it%2==0) "user" else "assistant",text=if(it<4) "older"+"a".repeat(2500) else "recent$it "+"b".repeat(1100)) }
        history.forEach { db.dao().putEntry(it) }
        var answers=0
        val client=object: ModelClient {
            override suspend fun test(profile: ModelProfile)=profile
            override fun generate(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?)=error("typed")
            override fun generateRequest(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?,options: ModelRequestOptions)=flow {
                ContextBudgetPlanner.requireFits(profile,messages,tools)
                if(options.stage=="compression") emit(ModelEvent.Completed(roleMessage("assistant",facts))) else {
                    answers++; (4..7).forEach { assertTrue(messages.toString().contains("recent$it "+"b".repeat(1100))) }
                    assertTrue(ContextBudgetPlanner.estimate(messages,tools)>ContextBudgetPlanner.limits(profile).target)
                    emit(ModelEvent.Completed(roleMessage("assistant","已完成")))
                }
            }
        }
        agent(client).run("","INBOX",emptyList(),"继续核对",profile,null,history=history,conversationId="c",requestId="run")
        assertEquals(1,answers)
    }
    @Test fun growingToolResultsCompactBaseAndNeverSubmitMail(): Unit=runBlocking {
        val history=(0..9).map { ChatEntry(id="t$it",conversationId="c",role=if(it%2==0) "user" else "assistant",text=if(it<6) "old-$it "+"a".repeat(1200) else "recent-$it") }
        val m=profile.copy(contextTokens=32768,outputTokens=4096,supportsTools=true)
        var summaries=0; var answers=0
        val client=object: ModelClient {
            override suspend fun test(profile: ModelProfile)=profile
            override fun generate(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?)=error("Typed request required")
            override fun generateRequest(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?,options: ModelRequestOptions)=flow {
                ContextBudgetPlanner.requireFits(profile,messages,tools)
                if(options.stage=="compression") { summaries++; emit(ModelEvent.Completed(roleMessage("assistant",facts))) }
                else if(++answers==1) {
                    val args=JSONObject().put("to","").put("subject","周五").put("body","mail-body "+"b".repeat(9000))
                    emit(ModelEvent.Completed(roleMessage("assistant","").put("tool_calls",JSONArray().put(JSONObject().put("id","draftcall").put("type","function").put("function",JSONObject().put("name","create_draft").put("arguments",args.toString()))))))
                } else {
                    assertTrue(ContextBudgetPlanner.estimate(messages,tools)<=ContextBudgetPlanner.limits(profile).input)
                    assertTrue(messages.toString().contains("recent-9")); assertFalse(messages.toString().contains("tool_call_id"))
                    emit(ModelEvent.Completed(roleMessage("assistant","请核对草稿")))
                }
            }
        }
        val result=agent(client).run("a","INBOX",emptyList(),"起草周五计划邮件",m,null,history=history)
        assertTrue(summaries>0); assertEquals(2,answers); assertTrue(result.candidate!!.draft.body.startsWith("mail-body")); assertTrue(db.dao().allDrafts().isEmpty())
    }
}

