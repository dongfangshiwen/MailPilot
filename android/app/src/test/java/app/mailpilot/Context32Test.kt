package app.mailpilot

import android.app.Application
import androidx.room.Room
import app.mailpilot.ai.*
import app.mailpilot.attachments.AttachmentProcessor
import app.mailpilot.data.*
import app.mailpilot.mail.MailRepositoryImpl
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import org.json.*
import org.junit.*
import org.junit.Assert.*
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import java.io.File
import java.io.IOException
import okhttp3.mockwebserver.MockWebServer
import okhttp3.mockwebserver.MockResponse

@RunWith(RobolectricTestRunner::class)
@Config(sdk=[28],application=Application::class)
class Context32Test {
    private lateinit var db: MailDatabase
    private val model=ModelProfile(model="fixture",contextTokens=16384,outputTokens=4096,thinkingMode="disabled")
    private val facts="姓名李明；日期2026-09-10；金额500元；修正交付日期为周六；[MATERIAL]。"
    @Before fun setup() { db=Room.inMemoryDatabaseBuilder(RuntimeEnvironment.getApplication(),MailDatabase::class.java).allowMainThreadQueries().build() }
    @After fun close() { db.close() }
    private class Client(val answer: (Int)->String): ModelClient {
        val inputs=mutableListOf<JSONArray>(); val options=mutableListOf<ModelRequestOptions>(); val models=mutableListOf<ModelProfile>()
        override suspend fun test(profile: ModelProfile)=profile
        override fun generate(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?)=error("typed")
        override fun generateRequest(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?,options: ModelRequestOptions)=flow {
            ContextBudgetPlanner.requireFits(profile,messages,tools)
            inputs+=messages; this@Client.options+=options; models+=profile
            emit(ModelEvent.Completed(roleMessage("assistant",answer(inputs.size))))
        }
    }
    private suspend fun turn(id: String="r",conversation: String="c",account: String="a") {
        if(db.dao().conversation(conversation)==null) db.dao().putConversation(Conversation(id=conversation,accountId=account))
        db.dao().putTurn(TurnSnapshot(id,conversation,account,"INBOX","[]",db.dao().turns(conversation).size+1))
    }
    @Test fun screenshot570FitsRealSpaceEvenWhenPreferredIs512()=runBlocking {
        turn(); val text="a".repeat(285); val client=Client { text }
        val result=ContextReducer(db.dao(),client).reduce(listOf("source"),"",1200,model,"r",preferredTokens=512)
        assertEquals(570,ContextBudgetPlanner.estimate(result)); assertEquals(1,client.inputs.size)
        assertEquals(0,AgentRunCheckpoint.from(db.dao().turn("r")).data.getJSONObject("compressionRepair").getInt("attempts"))
        val sample=AgentRunCheckpoint.from(db.dao().turn("r")).data.getJSONArray("compressionLog").getJSONObject(0)
        assertTrue(sample.has("generationMillis")); assertTrue(sample.has("estimatedInputTokens")); assertFalse(sample.toString().contains(text))
    }
    @Test fun largerBudgetAcceptsDurableCandidateWithoutRegenerating()=runBlocking {
        turn(); val client=Client { "a".repeat(285) }
        suspend fun reduce(budget: Int)=ContextReducer(db.dao(),client).reduce(listOf("same"),"",budget,model,"r")
        val error=runCatching { reduce(512) }.exceptionOrNull() as ModelFailure
        assertEquals(3,client.inputs.size); assertFalse(error.info.diagnostics.getBoolean("canResume"))
        assertEquals(570,ContextBudgetPlanner.estimate(reduce(1200))); assertEquals(3,client.inputs.size)
    }
    @Test fun repairNetworkFailuresDoNotConsumeLengthAttempts()=runBlocking {
        turn(); val client=Client { when(it) { 1 -> "a".repeat(900); 2,3 -> throw IOException("offline"); else -> facts } }
        suspend fun reduce()=ContextReducer(db.dao(),client).reduce(listOf("source"),"",600,model,"r")
        repeat(2) { assertTrue(runCatching { reduce() }.exceptionOrNull() is IOException) }
        assertEquals(0,AgentRunCheckpoint.from(db.dao().turn("r")).data.getJSONObject("compressionRepair").getInt("attempts"))
        assertEquals(facts,reduce()); assertEquals(4,client.inputs.size)
    }
    @Test fun rebudgetingInitialSummaryCannotSkipAChangedSourceLayout()=runBlocking {
        turn(); val initial="I".repeat(400); val source="B".repeat(10000)
        val first=Client { if(it==2) throw IOException("interrupted") else facts }
        assertTrue(runCatching { ContextReducer(db.dao(),first).reduce(listOf(source),initial,512,model,"r") }.isFailure)
        val resumed=Client { facts }
        ContextReducer(db.dao(),resumed).reduce(listOf(source),initial,1200,model,"r")
        val received=resumed.inputs.joinToString("") { JSONObject(it.getJSONObject(1).getString("content")).getString("new_history") }
        assertEquals(source,received)
        assertTrue(resumed.inputs.first().toString().contains(initial))
    }
    @Test fun materialNotesReuseAcrossQuestionsRebindSourcesAndIsolateScopes()=runBlocking {
        turn(); val client=Client { facts }
        val source=SourceChunk(id="T1:S1",messageId="",kind="document",title="合同",location="正文",text="原文".repeat(1800))
        suspend fun prepare(id: String,conversation: String="c",account: String="a",sources: List<SourceChunk> = listOf(source))=
            MaterialNotes(db.dao(),client).prepare(sources,6000,2000,model,id,account,conversation,{}, {})
        val first=prepare("r"); assertTrue(first.contains("李明")); assertEquals(1,client.inputs.size)
        turn("r2"); val rebound=prepare("r2",sources=listOf(source.copy(id="T2:S4")))
        assertTrue(rebound.contains("[T2:S4]")); assertFalse(rebound.contains("[T1:S1]")); assertEquals(1,client.inputs.size)
        turn("r3"); prepare("r3",sources=listOf(source,source.copy(id="T3:S2",text="修改内容"+source.text)))
        assertEquals(2,client.inputs.size)
        turn("other","other"); prepare("other","other"); assertEquals(3,client.inputs.size)
        turn("account","account","b"); prepare("account","account","b"); assertEquals(4,client.inputs.size)
        assertTrue(runCatching { prepare("r","other") }.exceptionOrNull() is IllegalArgumentException)
        assertTrue(db.dao().allDrafts().isEmpty())
    }
    @Test fun completedMaterialNotesSurviveHousekeepingThinkingChanges()=runBlocking {
        turn(); val client=Client { facts }
        val main=model.copy(provider="deepseek",thinkingMode="enabled")
        val source=SourceChunk(id="T1:S1",messageId="",kind="document",title="合同",location="正文",text="原文".repeat(1800))
        MaterialNotes(db.dao(),client).prepare(listOf(source),6000,2000,main,"r","a","c",{}, {})
        val count=client.inputs.size
        turn("r2")
        val result=MaterialNotes(db.dao(),client).prepare(listOf(source.copy(id="T2:S1")),6000,2000,CompressionPolicy.model(main,true),"r2","a","c",{}, {})
        assertEquals(count,client.inputs.size); assertTrue(result.contains("李明")); assertTrue(result.contains("T2:S1"))
    }
    @Test fun failedMergeRetainsAllValidatedLeaves()=runBlocking {
        turn(); val client=Client { facts+"额外确认事项。" }
        val sources=(1..2).map { SourceChunk(id="T1:S$it",messageId="",kind="document",title="材料$it",location="正文",text="事实$it".repeat(1500)) }
        suspend fun prepare(budget: Int)=MaterialNotes(db.dao(),client).prepare(sources,budget,128,model,"r","a","c",{}, {})
        val outcome=runCatching { prepare(96) }; val failure=outcome.exceptionOrNull()
        assertTrue("Unexpected merge failure: $failure; outputEstimate=${outcome.getOrNull()?.let(ContextBudgetPlanner::estimate)}; calls=${client.inputs.size}",failure is ModelFailure)
        val before=client.inputs.size
        val result=prepare(4000); assertEquals(before,client.inputs.size)
        assertTrue(result.contains("[T1:S1]")); assertTrue(result.contains("[T1:S2]"))
        assertEquals(4,AgentRunCheckpoint.from(db.dao().turn("r")).data.getJSONObject("materialNotes").length())
    }
    @Test fun quickCompressionIsTaskLocalAndDoesNotChangeAnswerOrCombinedThinkingQuota() {
        for(provider in listOf("deepseek","aliyun","volcengine")) {
            val main=model.copy(provider=provider,thinkingMode="enabled",reasoningEffort="high")
            assertEquals(main,CompressionPolicy.model(main,false))
            val fast=CompressionPolicy.model(main,true); assertEquals("disabled",fast.thinkingMode)
            val payload=ReasoningOptions.apply(fast,JSONObject())
            if(provider=="aliyun") assertFalse(payload.getBoolean("enable_thinking")) else assertEquals("disabled",payload.getJSONObject("thinking").getString("type"))
            assertEquals(1024,CompressionPolicy.outputLimit(fast,512))
            assertEquals("enabled",main.thinkingMode)
        }
        val unknown=model.copy(provider="compatible",thinkingMode="enabled")
        assertEquals(unknown,CompressionPolicy.model(unknown,true)); assertNull(CompressionPolicy.outputLimit(unknown,512))
        val options=ChatRequestOptions(fastCompression=true).freeze(model)
        assertTrue(ChatRequestOptions.parse(JSONObject(options.json())).fastCompression)
        assertFalse(ChatRequestOptions.parse(JSONObject("{}")).fastCompression)
    }
    @Test fun quickSettingSurvivesRestart()=runBlocking {
        val app=RuntimeEnvironment.getApplication()
        val prefs=Preferences(app); prefs.set("fastCompression","true")
        try { assertTrue(Preferences(app).flow.first().fastCompression) } finally { prefs.set("fastCompression","false") }
    }
    @Test fun summaryWireCapAndThinkingAreTaskLocal(): Unit=runBlocking {
        MockWebServer().use { server ->
            server.start()
            val client=CompatibleModelClient(PlainTestSecrets(),allowHttpForTests=true)
            for(provider in listOf("deepseek","aliyun","volcengine")) {
                val main=model.copy(provider=provider,baseUrl=server.url("/v1").toString(),thinkingMode="enabled")
                val fast=CompressionPolicy.model(main,true)
                repeat(2) { server.enqueue(MockResponse().setHeader("Content-Type","application/json").setBody("""{"choices":[{"message":{"role":"assistant","content":"完整结果"},"finish_reason":"stop"}]}""")) }
                client.generateRequest(fast,JSONArray().put(roleMessage("user","整理")),forceStream=false,
                    options=ModelRequestOptions(stage="compression",outputTokenLimit=CompressionPolicy.outputLimit(fast,512))).toList()
                val summary=JSONObject(server.takeRequest().body.readUtf8())
                assertEquals(1024,summary.getInt("max_tokens"))
                if(provider=="aliyun") assertFalse(summary.getBoolean("enable_thinking")) else assertEquals("disabled",summary.getJSONObject("thinking").getString("type"))
                client.generateRequest(main,JSONArray().put(roleMessage("user","回答")),forceStream=false).toList()
                val answer=JSONObject(server.takeRequest().body.readUtf8())
                assertEquals(4096,answer.getInt("max_tokens"))
                if(provider=="aliyun") assertTrue(answer.getBoolean("enable_thinking")) else assertEquals("enabled",answer.getJSONObject("thinking").getString("type"))
            }
        }
    }
    @Test fun eachConversationBuildsItsOwnIndependentRequestWindow(): Unit=runBlocking {
        val app=RuntimeEnvironment.getApplication()
        val processor=object: AttachmentProcessor {
            override suspend fun pdfCount(file: File): Int=error("not selected")
            override suspend fun previewPdf(file: File,page: Int): File=error("not selected")
            override suspend fun process(attachment: Attachment,pages: List<Int>,onProgress: (String)->Unit)=error("not selected")
        }
        val client=Client { "回答" }
        val agent=LocalAgent(db.dao(),MailRepositoryImpl(db,PlainTestSecrets(),app.filesDir),processor,client)
        for(id in listOf("alpha","beta")) {
            val history=listOf(ChatEntry(id="old-$id",conversationId=id,role="user",text="old-$id"),ChatEntry(conversationId=id,role="user",text="recent-$id"))
            db.dao().putConversation(Conversation(id=id,contextSummary="summary-$id",summaryThroughId="old-$id"))
            agent.run("","INBOX",emptyList(),"继续",model,null,conversationId=id,history=history)
            val wire=client.inputs.last().toString(); val other=if(id=="alpha") "beta" else "alpha"
            assertTrue(wire.contains("summary-$id")); assertTrue(wire.contains("recent-$id")); assertFalse(wire.contains(other))
        }
        val scope=db.dao().conversation("alpha")!!
        assertTrue(runCatching { ConversationCompressor(db.dao(),client).reference(scope,listOf(ChatEntry(conversationId="beta",role="user",text="secret"))) }.isFailure)
        assertEquals(2,client.inputs.size)
    }
}
