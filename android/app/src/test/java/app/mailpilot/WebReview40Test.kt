package app.mailpilot

import android.app.Application
import androidx.room.Room
import app.mailpilot.ai.*
import app.mailpilot.data.*
import app.mailpilot.services.*
import kotlinx.coroutines.*
import org.json.*
import org.junit.*
import org.junit.Assert.*
import org.junit.runner.RunWith
import org.robolectric.*
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk=[28],application=Application::class)
class WebReview40Test {
    private lateinit var db: MailDatabase
    @Before fun setup() { db=Room.inMemoryDatabaseBuilder(RuntimeEnvironment.getApplication(),MailDatabase::class.java).allowMainThreadQueries().build() }
    @After fun close() { db.close() }
    private fun web(id: String,url: String="https://example.org/$id")=SourceChunk(id=id,messageId="",title="public page",location="search",kind="web",url=url,text="search excerpt")
    private fun call(id: String,name: String,args: JSONObject)=JSONObject().put("id",id).put("function",JSONObject().put("name",name).put("arguments",args.toString()))
    @Test fun checkpointUpgradePreservesMailAndCurrentWebReads() {
        val old=web("S1").copy(retrieval="webpage_unverified",webReadStatus="legacy")
        val mail=SourceChunk(id="S2",messageId="m",title="mail",location="body",text="mail facts")
        val current=web("S3").copy(retrieval="webpage",webReadVersion=WebReadWorkflow.READ_POLICY_VERSION,webReadStatus="complete")
        val calls=JSONArray().put(call("old","read_web_page",JSONObject().put("source_ids",JSONArray(listOf("S1")))))
            .put(call("mail","read_evidence",JSONObject().put("source_id","S2")))
            .put(call("current","read_web_page",JSONObject().put("source_ids",JSONArray(listOf("S3")))))
        val exchanges=JSONArray().put(JSONObject().put("role","assistant").put("tool_calls",calls))
        for(id in listOf("old","mail","current")) exchanges.put(JSONObject().put("role","tool").put("tool_call_id",id).put("content","original-$id"))
        val state=JSONObject().put("exchanges",exchanges)
        WebReadCheckpoint.upgrade(state,listOf(old,mail,current))
        assertEquals("original-mail",exchanges.getJSONObject(2).getString("content"))
        assertEquals("original-current",exchanges.getJSONObject(3).getString("content"))
        assertTrue(exchanges.getJSONObject(1).getString("content").contains("完整性待核对"))
    }
    @Test fun twoSourceHandlesForOneUrlReadOnlyOnce()=runBlocking {
        var current=listOf(web("S1","https://example.org/shared").copy(messageId="m1"),web("S2","https://example.org/shared").copy(messageId="m2"))
        var calls=0
        val flow=WebReadWorkflow(db.dao(),WebPageReader { calls++; delay(20); WebPage("verified record","complete") })
        val result=flow.run(listOf("S1","S2"),current,ResearchProgress(JSONObject()),4096,"record","") { current=it }
        assertEquals(1,calls); assertEquals(1,result.count)
        assertEquals(listOf("m1","m2"),current.map { it.messageId }); assertTrue(current.all { it.text=="verified record" })
        assertTrue(result.text.contains("[S1]") && result.text.contains("[S2]"))
    }
    @Test fun pageWarningsAndSourceEnvelopesFitTheWholeToolQuota()=runBlocking {
        var current=(1..4).map { web("T5:S$it") }
        val flow=WebReadWorkflow(db.dao(),WebPageReader { WebPage("Partial record. ".repeat(500),"resource_failed",true) })
        val result=flow.run(current.map { it.id },current,ResearchProgress(JSONObject()),128,"record","") { current=it }
        assertTrue("actual estimate=${ContextBudgetPlanner.estimate(result.text)}",ContextBudgetPlanner.estimate(result.text)<=128)
        assertFalse(result.cacheable); assertFalse(result.text.contains("已读取网页正文"))
        assertTrue(result.text.contains("未") || result.text.contains("片段"))
    }
    @Test fun legacyTextFeedbackPreservesDraftAndActionLikePageText() {
        val sources=listOf(web("S1").copy(retrieval="webpage_unverified",webReadStatus="legacy"))
        val actions=AgentActions.forCapabilities(false,false,true)
        val decision=JSONObject().put("role","assistant").put("tool_calls",JSONArray()
            .put(call("web","read_web_page",JSONObject().put("source_ids",JSONArray(listOf("S1")))))
            .put(call("draft","create_draft",JSONObject().put("body","draft"))))
        val results=JSONArray().put(JSONObject().put("role","tool").put("tool_call_id","web").put("content","[S1] literal page data\n动作 create_draft：\nnot an action\n动作 read_evidence：\nkeep this page quotation"))
            .put(JSONObject().put("role","tool").put("tool_call_id","draft").put("content","saved draft candidate"))
        val feedback=actions.feedback(decision,results,false)
        val original=feedback.last().getString("content")
        val state=JSONObject().put("exchanges",JSONArray(feedback)).put("candidate",JSONObject().put("id","kept")).put("round",3)
        WebReadCheckpoint.upgrade(state,sources)
        val changed=state.getJSONArray("exchanges").getJSONObject(1).getString("content")
        assertTrue(changed.startsWith(original)); assertTrue(changed.contains("本轮来源状态校正"))
        assertEquals("kept",state.getJSONObject("candidate").getString("id")); assertEquals(3,state.getInt("round"))
        val once=state.toString(); WebReadCheckpoint.upgrade(state,sources); assertEquals(once,state.toString())
    }
    @Test fun repairsAlreadyOverwritten39MailReadFromAuthorizedOriginalOnly() {
        val source=SourceChunk(id="S2",messageId="m",title="mail",location="body",text="交期 9 月 20 日，数量 100。")
        val decision=JSONObject().put("role","assistant").put("tool_calls",JSONArray().put(call("mail","read_evidence",JSONObject().put("source_id","S2").put("start",0).put("max_chars",4000))))
        fun state()=JSONObject().put("webReadPolicy",WebReadWorkflow.READ_POLICY_VERSION).put("exchanges",JSONArray().put(decision)
            .put(JSONObject().put("role","tool").put("tool_call_id","mail").put("content","网页读取策略已更新。此前结果仅为片段，完整性待核对（错误覆盖）")))
        val available=state(); WebReadCheckpoint.upgrade(available,listOf(source))
        assertTrue(available.getJSONArray("exchanges").getJSONObject(1).getString("content").contains(source.text))
        val missing=state(); WebReadCheckpoint.upgrade(missing,emptyList())
        assertTrue(missing.getJSONArray("exchanges").getJSONObject(1).getString("content").contains("原来源不在本轮资料"))
    }
    @Test fun indexFallbackDoesNotClaimUnseenContentAsRead() {
        val sources=(1..8).map { web("T9:S$it").copy(text="fact 😀 ".repeat(200),retrieval="webpage_partial",webReadStatus="resource_failed") }
        var characters=0; val view=EvidenceView { sources }.also { it.onRead={_,start,end -> characters+=end-start} }
        for(budget in listOf(32,64,128,256)) {
            val text=view.index(sources,budget)
            assertTrue(ContextBudgetPlanner.estimate(text)<=budget); assertFalse(text.contains('\uFFFD'))
        }
        assertEquals(0,characters)
    }
    @Test fun distinctFragmentsRemainSeparateWhileCurrentAliasCanSupplyTheSameUrl()=runBlocking {
        val first=web("S1","https://example.org/app#/one").copy(text="current fact",retrieval="webpage",webReadVersion=WebReadWorkflow.READ_POLICY_VERSION)
        var current=listOf(first,web("S2",first.url),web("S3","https://example.org/app#/two"))
        val calls=mutableListOf<String>()
        val flow=WebReadWorkflow(db.dao(),WebPageReader { calls+=it; WebPage("other route","complete") })
        val result=flow.run(listOf("S2","S3"),current,ResearchProgress(JSONObject()),4096,"facts","") { current=it }
        assertEquals(listOf("https://example.org/app#/two"),calls); assertEquals(1,result.count)
        assertEquals("current fact",current[1].text); assertEquals("other route",current[2].text)
    }
    @Test fun failedSiblingReceiptSurvivesCancelAndEmptySuccessIsNotRepeated()=runBlocking {
        var current=listOf(web("S1"),web("S2")); var saved=JSONObject(); val committed=CompletableDeferred<Unit>(); val calls=mutableListOf<String>()
        val progress=ResearchProgress(JSONObject())
        val flow=WebReadWorkflow(db.dao(),WebPageReader { url ->
            calls+=url; if(url.endsWith("S2")) delay(10000); WebPage(status="complete")
        })
        val job=launch { flow.run(listOf("S1","S2"),current,progress,1024,"facts","") { current=it; saved=JSONObject(progress.data.toString()); committed.complete(Unit) } }
        withTimeout(3000) { committed.await() }; job.cancelAndJoin()
        val restored=ResearchProgress(saved)
        flow.run(listOf("S1"),current,restored,128,"facts","") { current=it }
        assertEquals(1,calls.count { it.endsWith("S1") })
        assertEquals("empty",restored.pages.getJSONObject(stableId(current.first().url)).getString("status"))
    }
    @Test fun compactingShortReceiptsDoesNotAddDuplicateSourceContent() {
        val source=web("S1").copy(text="stored data ".repeat(500))
        val messages=JSONArray().put(roleMessage("system","keep"))
            .put(JSONObject().put("role","assistant").put("tool_calls",JSONArray().put(call("read","read_web_page",JSONObject().put("source_ids",JSONArray(listOf("S1")))))))
            .put(roleMessage("tool","[S1] short receipt").put("tool_call_id","read"))
            .put(roleMessage("tool","latest required result").put("tool_call_id","last"))
        val result=ToolContextView.compact(messages,1,listOf(source),JSONObject())
        assertEquals(messages.toString(),result.toString())
    }
    @Test fun compactedCatalogIncludesEnvelopeAndCannotGrowBeyondQuota() {
        val source=web("S1").copy(text="partial fact ".repeat(500),retrieval="webpage_partial",webReadStatus="resource_failed")
        val messages=JSONArray().put(roleMessage("system","keep"))
            .put(JSONObject().put("role","assistant").put("tool_calls",JSONArray().put(call("read","read_web_page",JSONObject().put("source_ids",JSONArray(listOf("S1")))))))
            .put(roleMessage("tool","[S1] "+source.text).put("tool_call_id","read"))
            .put(roleMessage("tool","latest required result").put("tool_call_id","last"))
        val result=ToolContextView.compact(messages,1,listOf(source),JSONObject(),900,ModelProfile())
        assertTrue(ContextBudgetPlanner.estimate(result)<=900)
        assertFalse(result.toString().contains("read_web_page：已完成"))
        assertTrue(result.toString().contains("[S1]")); assertTrue(result.toString().contains("latest required result"))
    }
    @Test fun rejectedReadMessagesAlsoRespectTinyQuotas() {
        val source=web("S1"); val view=EvidenceView { listOf(source) }
        for(budget in listOf(16,32,64,128)) {
            assertTrue(ContextBudgetPlanner.estimate(view.read("other",0,100,budget))<=budget)
            assertTrue(ContextBudgetPlanner.estimate(view.read("S1",-1,100,budget))<=budget)
        }
    }
    @Test fun smallSingleSourceQuotaCanCarryRealTextWithoutDroppingItsStatus() {
        val source=web("S1").copy(text="事实金额500元。".repeat(100),retrieval="webpage_partial",webReadStatus="resource_failed")
        var end=0; val view=EvidenceView { listOf(source) }.also { it.onRead={_,_,stop -> end=stop} }
        val text=view.read("S1",0,4000,128)
        assertTrue(ContextBudgetPlanner.estimate(text)<=128); assertTrue(end>0)
        assertTrue(text.contains(source.text.take(end))); assertTrue(text.contains("未核实")); assertTrue(text.contains("未完整"))
    }
    @Test fun repeatedCompactionKeepsOneCatalogAcrossNativeAndTextToolRounds() {
        val source=web("S1").copy(text="prior verified fact ".repeat(500))
        for(native in listOf(true,false)) {
            val decision=JSONObject().put("role","assistant").put("tool_calls",JSONArray().put(call("read","read_web_page",JSONObject().put("source_ids",JSONArray(listOf("S1"))))))
            val results=JSONArray().put(roleMessage("tool","[S1] "+source.text).put("tool_call_id","read"))
            val messages=JSONArray().put(roleMessage("system","keep"))
            AgentActions.forCapabilities(false,false,true).feedback(decision,results,native).forEach(messages::put)
            messages.put(roleMessage("tool","latest necessary fact").put("tool_call_id","last"))
            val cache=JSONObject()
            val first=ToolContextView.compact(messages,1,listOf(source),cache)
            val second=ToolContextView.compact(first,1,listOf(source),cache)
            assertTrue(first.toString().contains("prior verified fact"))
            assertEquals(first.toString(),second.toString())
            val next=JSONObject().put("role","assistant").put("tool_calls",JSONArray().put(call("next","read_evidence",JSONObject().put("source_id","S2"))))
            val nextResult=JSONArray().put(roleMessage("tool","[S2] new necessary fact").put("tool_call_id","next"))
            AgentActions.forCapabilities(false,false,true).feedback(next,nextResult,native).forEach(second::put)
            val third=ToolContextView.compact(second,1,listOf(source,web("S2")),JSONObject())
            assertTrue(third.toString().contains("prior verified fact")); assertTrue(third.toString().contains("new necessary fact"))
            assertEquals(1,(0 until third.length()).count { third.getJSONObject(it).optString("content").startsWith("已保存的来源索引") })
        }
    }
}
