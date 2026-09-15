package app.mailpilot

import android.app.Application
import androidx.room.Room
import app.mailpilot.ai.*
import app.mailpilot.data.*
import app.mailpilot.services.WebSearchClient
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
import java.util.concurrent.atomic.AtomicInteger

@RunWith(RobolectricTestRunner::class)
@Config(sdk=[28],application=Application::class)
class Agent33Test {
    private lateinit var db: MailDatabase
    @Before fun setup() { db=Room.inMemoryDatabaseBuilder(RuntimeEnvironment.getApplication(),MailDatabase::class.java).allowMainThreadQueries().build() }
    @After fun close() { db.close() }
    private suspend fun turn() { db.dao().putConversation(Conversation(id="c",accountId="a")); db.dao().putTurn(TurnSnapshot("r","c","a","INBOX","[]",1)) }
    @Test fun reasoningRetainsSegmentsAndPreviousAttempts() {
        var now=0L; val trace=ReasoningTrace(attemptId="one") { now }
        trace.begin("req1","answer"); trace.append("第一段😀"); now=1000; trace.finish()
        assertFalse(trace.snapshot().runComplete)
        trace.begin("req2","answer"); trace.append("第二段"); now=2500; trace.end()
        val snap=trace.snapshot(); assertEquals("第一段😀\n\n第二段",snap.text); assertEquals(2,snap.segments.size)
        assertEquals(2500,snap.elapsedMs); assertTrue(snap.runComplete)
        trace.append("迟到内容"); assertEquals(snap.text,trace.snapshot().text)
        val retry=ReasoningTrace(attemptId="two",previous=ReasoningSnapshot.from(JSONObject(snap.fields()))) { now }
        retry.append("新尝试"); retry.end("interrupted")
        assertEquals(snap.text,retry.snapshot().previous.single().text)
        assertEquals("新尝试",retry.snapshot().text)
    }
    @Test fun failureAfterThinkingDoesNotRenameCompletedThoughts() {
        val trace=ReasoningTrace(); trace.append("完成的思考"); trace.finish(); trace.end("interrupted")
        assertEquals("completed",trace.snapshot().state); assertTrue(trace.snapshot().runComplete)
    }
    @Test fun sourceBudgetIncludesMetadataAndPreservesHandles() {
        val sources=(1..8).map { SourceChunk(id="T1:S$it",messageId="",kind="web",title="标题".repeat(200),url="https://example.test/"+"long".repeat(300),location="网页",text="文字😀".repeat(500)) }
        val view=EvidenceView { sources }
        for(budget in listOf(1536,4096,6000)) {
            val result=view.index(sources,budget)
            assertTrue("index ${ContextBudgetPlanner.estimate(result)} > $budget",ContextBudgetPlanner.estimate(result)<=budget)
            sources.forEach { assertTrue(result.contains("[${it.id}]")) }
            assertTrue(result.contains("未完整"))
        }
        val read=view.read("T1:S1",0,4000,1024)
        assertTrue(ContextBudgetPlanner.estimate(read)<=1024); assertFalse(read.contains("\uFFFD"))
    }
    @Test fun completedSearchViewReusesCacheWithoutTouchingPendingOrReceipts() {
        val source=SourceChunk(id="T1:S1",messageId="",kind="web",title="规范",url="https://example.test",location="网页",text="事实".repeat(3000))
        val original=JSONArray().put(roleMessage("system","keep"))
            .put(roleMessage("assistant","""{"mailpilot_action":"web_search","arguments":{"queries":["规范"]}}"""))
            .put(roleMessage("user","应用动作执行结果\n动作 web_search：\n[T1:S1] "+source.text))
            .put(roleMessage("tool","最新必要读取结果").put("tool_call_id","read1"))
        val cache=JSONObject(); val first=ToolContextView.compact(original,1,listOf(source),cache)
        assertEquals(1,cache.length()); assertTrue(ContextBudgetPlanner.estimate(first)<ContextBudgetPlanner.estimate(original))
        assertEquals(original.getJSONObject(3).toString(),first.getJSONObject(3).toString())
        assertTrue(original.getJSONObject(2).getString("content").contains(source.text))
        assertEquals(first.toString(),ToolContextView.compact(original,1,listOf(source),cache).toString())
    }
    @Test fun parallelSearchCheckpointsSuccessfulSibling()=runBlocking {
        turn(); val active=AtomicInteger(); val peak=AtomicInteger(); val calls=AtomicInteger(); var fail=true
        val service=object: WebSearchClient { override suspend fun search(config: ServiceConfig,query: String): List<SourceChunk> {
            calls.incrementAndGet(); val n=active.incrementAndGet(); peak.updateAndGet { maxOf(it,n) }
            try { delay(30); if(query=="第二主题" && fail) throw IOException("offline")
                return listOf(SourceChunk(messageId="",title=query,kind="web",url="https://example.test/$query",location="网页",text="已取得结果"))
            } finally { active.decrementAndGet() }
        } }
        suspend fun search()=SearchWorkflow(db.dao(),service).run(JSONArray(listOf("第一主题","第二主题")),"scope",ServiceConfig(),"r",{}, {})
        assertTrue(runCatching { search() }.exceptionOrNull() is WebSearchFailure)
        assertEquals(2,peak.get()); fail=false
        assertEquals(2,search().size); assertEquals(3,calls.get())
    }
    @Test fun quickDefaultMigratesOnceAndRespectsLaterChoice()=runBlocking {
        val prefs=Preferences(RuntimeEnvironment.getApplication())
        prefs.set("fastCompression","false"); prefs.upgradeCompressionDefault()
        assertTrue(prefs.flow.first().fastCompression)
        prefs.set("fastCompression","false"); prefs.upgradeCompressionDefault()
        assertFalse(prefs.flow.first().fastCompression)
    }
    @Test fun legacyFastJournalKeepsItsSearchScopeButRejectsUnrelatedScopes()=runBlocking {
        turn(); val old=AgentActionCheckpoint.open(db.dao(),"r","legacy-enabled")
        old.state.put("round",2); old.save()
        val restored=AgentActionCheckpoint.open(db.dao(),"r","new-key",setOf("legacy-enabled"))
        assertEquals(2,restored.round); assertEquals("legacy-enabled",restored.state.getString("key"))
        assertEquals(0,AgentActionCheckpoint.open(db.dao(),"r","different-account").round)
    }
    @Test fun restartMarksOnlyUnfinishedThinkingAndPreservesOldAttempts()=runBlocking {
        turn(); val previous=ReasoningSnapshot("上次思考",10,"completed",attemptId="previous",runComplete=true)
        val trace=ReasoningTrace(attemptId="current",previous=previous)
        trace.begin("first","answer"); trace.append("第一段"); trace.finish()
        trace.begin("second","answer"); trace.append("第二段")
        db.dao().putEntry(trace.snapshot().attach(ChatEntry(id="r",conversationId="c",role="assistant",text="",resultStatus="running")))
        AgentCheckpoints.update(db.dao(),"r") { it.put("phase","generating").put("reasoningTrace",JSONObject(trace.snapshot().fields())) }
        recoverAgentRuns(db.dao())
        val restored=ReasoningSnapshot.from(AgentRunCheckpoint.from(db.dao().turn("r")).data.getJSONObject("reasoningTrace"))
        assertTrue(restored.runComplete); assertEquals(listOf("completed","interrupted"),restored.segments.map { it.state })
        assertEquals("上次思考",restored.previous.single().text); assertEquals(trace.snapshot().text,restored.text)
    }
    @Test fun timingsAreSavedPerAttemptIncludingFailure()=runBlocking {
        turn(); RunTelemetry.begin(db.dao(),"r","attempt1")
        val base=object: ModelClient {
            override suspend fun test(profile: ModelProfile)=profile
            override fun generate(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?)=flow<ModelEvent> { emit(ModelEvent.Thinking("secret body")); throw IOException("not logged") }
        }
        val client=RecordingModelClient(db.dao(),base)
        assertTrue(runCatching { client.generateRequest(ModelProfile(model="fixture"),JSONArray(),options=ModelRequestOptions(requestId="r")).collect() }.isFailure)
        RunTelemetry.end(db.dao(),"r","failed"); RunTelemetry.begin(db.dao(),"r","attempt2")
        val runs=AgentRunCheckpoint.from(db.dao().turn("r")).data.getJSONArray("runAttempts")
        assertEquals(1,runs.getJSONObject(0).getJSONArray("requests").length()); assertEquals(0,runs.getJSONObject(1).getJSONArray("requests").length())
        assertFalse(runs.toString().contains("secret body")); assertFalse(runs.toString().contains("not logged"))
    }
}
