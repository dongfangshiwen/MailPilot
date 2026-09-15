package app.mailpilot

import android.app.Application
import androidx.room.Room
import app.mailpilot.ai.*
import app.mailpilot.data.*
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import org.json.*
import org.junit.*
import org.junit.Assert.*
import org.junit.runner.RunWith
import org.robolectric.*
import org.robolectric.annotation.Config
import java.io.IOException

@RunWith(RobolectricTestRunner::class)
@Config(sdk=[28],application=Application::class)
class Context31Test {
    private lateinit var db: MailDatabase
    private val profile=ModelProfile(baseUrl="https://ark.cn-beijing.volces.com/api/plan/v3",model="doubao-seed-evolving",contextTokens=32768,outputTokens=0)
    @Before fun setup() { db=Room.inMemoryDatabaseBuilder(RuntimeEnvironment.getApplication(),MailDatabase::class.java).allowMainThreadQueries().build() }
    @After fun close() { db.close() }
    @Test fun wireEscapesDoNotCountAsModelTextButLiteralEscapesDo() {
        val plain=JSONArray().put(roleMessage("user","a".repeat(4000)))
        val slashes=JSONArray().put(roleMessage("user","\\".repeat(4000)))
        assertEquals(ContextBudgetPlanner.estimate(plain),ContextBudgetPlanner.estimate(slashes))
        assertTrue(slashes.toString().length>plain.toString().length)
        val nested=JSONArray().put(roleMessage("user",JSONObject().put("text","\\".repeat(4000)).toString()))
        assertTrue(ContextBudgetPlanner.estimate(nested)>ContextBudgetPlanner.estimate(slashes))
        assertEquals(24576,ContextBudgetPlanner.limits(profile).input)
    }
    @Test fun packFitsFinalEnvelopeAndPreservesEveryUnicodeCharacter() {
        val text="中😀\\\"\n|value|日期2026年9月|https://example.test/a?b=1|".repeat(800)
        var cursor=SourceCursor(); val all=StringBuilder(); var count=0
        fun request(value: String)=JSONArray().put(roleMessage("system","摘要规则".repeat(20)))
            .put(roleMessage("user",JSONObject().put("previous_summary","姓名 李明 金额500元".repeat(30)).put("new_history",value).toString()))
        while(cursor.block==0) {
            val batch=CompressionPacker.pack(listOf(text),cursor,3500,::request)
            assertTrue(batch.end!=cursor); assertTrue(ContextBudgetPlanner.estimate(request(batch.text))<=3500)
            assertFalse(batch.text.last().isHighSurrogate()); all.append(if(count==0) batch.text else batch.text.removePrefix(text.substringBefore('\n')+"（续）\n")); cursor=batch.end; count++
        }
        assertEquals(text,all.toString()); assertTrue(count>10)
    }
    @Test fun packingShrinksWhenPreviousSummaryGrows() {
        fun pack(summary: String)=CompressionPacker.pack(listOf("\\\"中😀".repeat(4000)),SourceCursor(),24576) {
            JSONArray().put(roleMessage("user",JSONObject().put("previous_summary",summary).put("new_history",it).toString()))
        }
        assertTrue(pack("旧记忆".repeat(300)).end.offset<pack("").end.offset)
    }
    @Test fun preparedRequestIsolatedFromCallerMutationsAndReportsLocalFailure() {
        val messages=JSONArray().put(roleMessage("user","first")); val tools=JSONArray().put(JSONObject().put("name","safe"))
        val frozen=PreparedModelRequest.prepare(profile,messages,tools,ModelRequestOptions(stage="compression"))
        messages.getJSONObject(0).put("content","changed"); tools.getJSONObject(0).put("name","unsafe")
        assertEquals("first",frozen.messages.getJSONObject(0).getString("content")); assertEquals("safe",frozen.tools!!.getJSONObject(0).getString("name"))
        val failure=runCatching { PreparedModelRequest.prepare(profile,JSONArray().put(roleMessage("user","中".repeat(18000))),null,ModelRequestOptions(stage="compression")) }.exceptionOrNull() as ModelFailure
        assertEquals("local_preflight",failure.info.diagnostics.getString("origin")); assertFalse(failure.info.diagnostics.has("finishReason"))
        assertEquals("compression",failure.info.diagnostics.getString("stage")); assertEquals("budget",failure.info.action)
    }
    @Test fun reducerResumesExactOffsetAfterSecondBatchFails()=runBlocking {
        db.dao().putConversation(Conversation(id="c",contextSummary="原记忆"))
        db.dao().putTurn(TurnSnapshot("r","c","","INBOX","[]",1))
        val text="长文片段 😀 \\\" 日期2026-09-10 金额500元\n".repeat(1800)
        val received=mutableListOf<String>(); var fail=true; var count=0
        val client=object: ModelClient {
            override suspend fun test(profile: ModelProfile)=profile
            override fun generate(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?)=flow {
                ContextBudgetPlanner.requireFits(profile,messages,tools)
                if(++count==2 && fail) throw IOException("fixture")
                received+=JSONObject(messages.getJSONObject(1).getString("content")).getString("new_history")
                emit(ModelEvent.Completed(roleMessage("assistant","日期2026-09-10，金额500元，[T1:S1]。")))
            }
        }
        suspend fun reduce()=ContextReducer(db.dao(),client).reduce(listOf(text),"",1000,profile,"r")
        assertTrue(runCatching { reduce() }.exceptionOrNull() is IOException)
        val saved=AgentRunCheckpoint.from(db.dao().turn("r")).data.getJSONObject("compression").getJSONObject("history")
        assertEquals(1,saved.getInt("batch")); assertTrue(saved.getInt("offset")>0)
        fail=false; reduce()
        // Continuation labels repeat only the short first line; actual source coverage never skips.
        val heading=text.substringBefore('\n')+"（续）\n"
        assertEquals(text,received.mapIndexed { i,s -> if(i==0) s else s.removePrefix(heading) }.joinToString(""))
        assertEquals("原记忆",db.dao().conversation("c")!!.contextSummary)
        assertTrue(db.dao().allDrafts().isEmpty())
    }
    @Test fun completedCandidateSurvivesRepairConnectionFailure()=runBlocking {
        db.dao().putConversation(Conversation(id="c")); db.dao().putTurn(TurnSnapshot("r","c","","INBOX","[]",1))
        var calls=0
        val client=object: ModelClient {
            override suspend fun test(profile: ModelProfile)=profile
            override fun generate(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?)=flow {
                when(++calls) { 1 -> emit(ModelEvent.Completed(roleMessage("assistant","长".repeat(1000)))); 2 -> throw IOException("repair"); else -> emit(ModelEvent.Completed(roleMessage("assistant","关键日期及500元"))) }
            }
        }
        suspend fun reduce()=ContextReducer(db.dao(),client).reduce(listOf("source"),"",600,profile,"r")
        assertTrue(runCatching { reduce() }.isFailure); assertEquals("关键日期及500元",reduce()); assertEquals(3,calls)
    }
    @Test fun evidenceOnlyExposesCurrentAuthorizedSourcesWithExplicitCoverage() {
        val source=SourceChunk(id="T1:S1",messageId="private",title="规范",location="web",kind="web",text="首段".repeat(1000)+"尾部金额500元",url="https://example.test",imagePath="PRIVATE_PATH",assetKey="SECRET_CACHE_KEY")
        val view=EvidenceView { listOf(source) }; val index=view.index(listOf(source),900)
        assertTrue(index.contains("未完整")); assertFalse(index.contains("PRIVATE_PATH")); assertFalse(index.contains("SECRET_CACHE_KEY")); assertFalse(index.contains("尾部金额"))
        assertTrue(view.read(source.id,2000,4000,2000).contains("尾部金额500元"))
        assertTrue(view.read("other-session",0,4000,2000).contains("未读取任何内容"))
        assertTrue(view.read(source.id,-1,4000,2000).contains("位置无效"))
    }
    @Test fun textAdapterFeedbackHasNoJsonOfJsonAndNativePairsRemainValid() {
        val actions=AgentActions.forCapabilities(false,false,true)
        val answer=actions.normalize(roleMessage("assistant","""{"mailpilot_action":"web_search","arguments":{"queries":["公开主题"]}}"""),false)
        val result=JSONObject().put("role","tool").put("tool_call_id",answer.getJSONArray("tool_calls").getJSONObject(0).getString("id")).put("content","标题\n\"引用\"\\细节")
        val feedback=actions.feedback(answer,JSONArray().put(result),false)
        assertTrue(feedback.last().getString("content").contains("标题\n\"引用\"\\细节")); assertFalse(feedback.last().getString("content").contains("tool_call_id"))
        assertEquals(result,actions.feedback(answer,JSONArray().put(result),true).last())
    }
}
