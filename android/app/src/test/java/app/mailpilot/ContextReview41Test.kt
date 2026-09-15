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
class ContextReview41Test {
    private lateinit var db: MailDatabase
    private val app get()=RuntimeEnvironment.getApplication()
    @Before fun setup() { db=Room.inMemoryDatabaseBuilder(app,MailDatabase::class.java).allowMainThreadQueries().build() }
    @After fun close() { db.close() }
    private fun web(id: String)=SourceChunk(id=id,messageId="",title="record",location="web",kind="web",url="https://example.org/record",text="verified fact ".repeat(100))
    private fun call(id: String,name: String,args: JSONObject)=JSONObject().put("id",id).put("type","function")
        .put("function",JSONObject().put("name",name).put("arguments",args.toString()))
    private val processor=object: AttachmentProcessor {
        override suspend fun pdfCount(file: File)=error("No files")
        override suspend fun previewPdf(file: File,page: Int)=error("No files")
        override suspend fun process(attachment: Attachment,pages: List<Int>,onProgress: (String)->Unit)=error("No files")
    }
    @Test fun sameWebContentThroughAnotherCitationIsNotNewReadingProgress() {
        val p=ResearchProgress(JSONObject()); val source=web("T1:S1")
        p.read(source,0,40); val before=p.count
        p.read(source.copy(id="T1:S2",messageId="other"),0,40)
        assertEquals(before,p.count)
        p.read(source.copy(id="T1:S2"),20,60); assertEquals(before+1,p.count)
    }
    @Test fun latestReferenceWithoutAnExcerptDoesNotEraseOlderFacts() {
        val source=web("S1")
        val messages=JSONArray().put(roleMessage("system","keep"))
            .put(JSONObject().put("role","assistant").put("tool_calls",JSONArray().put(call("read","read_web_page",JSONObject().put("source_ids",JSONArray(listOf("S1")))))))
            .put(roleMessage("tool","[S1] "+source.text).put("tool_call_id","read"))
            .put(roleMessage("tool","[S1] 未展示摘录。").put("tool_call_id","last"))
        val result=ToolContextView.compact(messages,1,listOf(source),JSONObject())
        assertTrue(result.toString().contains("verified fact"))
        assertTrue(result.toString().contains("未展示摘录"))
        assertTrue(ContextBudgetPlanner.estimate(result)<=ContextBudgetPlanner.estimate(messages))
    }
    @Test fun textFeedbackWithMailCardsMustNotBeReplacedAsWebOnly() {
        val source=web("S1")
        val decision=JSONObject().put("role","assistant").put("tool_calls",JSONArray()
            .put(call("search","web_search",JSONObject().put("queries",JSONArray(listOf("public topic")))))
            .put(call("mail","search_emails",JSONObject().put("keyword","topic"))))
        val results=JSONArray().put(roleMessage("tool","[S1] "+source.text).put("tool_call_id","search"))
            .put(roleMessage("tool","selected-mail-card").put("tool_call_id","mail"))
        val messages=JSONArray().put(roleMessage("system","keep"))
        AgentActions.forCapabilities(true,true,true).feedback(decision,results,false).forEach(messages::put)
        messages.put(roleMessage("tool","latest").put("tool_call_id","last"))
        val result=ToolContextView.compact(messages,1,listOf(source),JSONObject())
        assertTrue(result.toString().contains("selected-mail-card"))
    }
    @Test fun fullAgentRendersCurrentPageAfterReadingTheSameLocalSourceAgain()=runBlocking {
        for(native in listOf(false,true)) runAgent(search=false,native=native)
    }
    @Test fun fullAgentReusesSearchAcquisitionButRendersTheCurrentEvidence()=runBlocking {
        for(native in listOf(false,true)) runAgent(search=true,native=native)
    }
    @Test fun oldAliasRangesMigrateWithoutInventingProgressAndKeepContentVersionsSeparate() {
        val one=web("S1"); val two=one.copy(id="S2")
        val ranges=JSONObject().put(stableId(one.id+stableId(one.text)),JSONArray().put(JSONArray(listOf(0,40))))
            .put(stableId(two.id+stableId(two.text)),JSONArray().put(JSONArray(listOf(20,60))))
        val p=ResearchProgress(JSONObject().put("version",1).put("progress",5).put("ranges",ranges))
        p.bindSources(listOf(one,two)); p.read(two,0,60); assertEquals(5,p.count); assertEquals(1,ranges.length())
        val restored=ResearchProgress(JSONObject(p.data.toString())); restored.bindSources(listOf(one,two)); restored.read(one,0,60)
        assertEquals(5,restored.count)
        restored.read(two.copy(text="new version ".repeat(100)),0,60); assertEquals(6,restored.count)
        restored.read(two.copy(url=two.url+"#/other"),0,60); assertEquals(7,restored.count)
        restored.read(two,-1,20); restored.read(two,0,two.text.length+1); assertEquals(7,restored.count)
    }
    @Test fun evidenceReceiptRebindsCurrentSourcesAndBudgetAfterRestart() {
        val source=web("S1"); val p=ResearchProgress(JSONObject()); val key=p.key("web_search",JSONObject().put("queries",JSONArray(listOf("topic"))))
        p.saveEvidenceReceipt(key,listOf(source)); p.saveReceipt("draft","saved candidate")
        val restored=ResearchProgress(JSONObject(p.data.toString())); val current=source.copy(text="current amount 730. ".repeat(100),retrieval="webpage_partial",webReadStatus="resource_failed")
        val values=requireNotNull(restored.evidenceReceipt(key,listOf(current)))
        assertEquals(current,values.single()); assertEquals("saved candidate",restored.receipt("draft"))
        for(budget in listOf(128,512,2048)) assertTrue(ContextBudgetPlanner.estimate(EvidenceView { values }.index(values,budget))<=budget)
        assertNull(restored.evidenceReceipt(key,emptyList())); assertNull(restored.evidenceReceipt(key,listOf(current.copy(id="S2"))))
        restored.saveEvidenceReceipt("empty",emptyList()); assertEquals(emptyList<SourceChunk>(),restored.evidenceReceipt("empty",emptyList()))
    }
    @Test fun onlyActualAlreadyShownTextIsDeduplicated() {
        val source=web("S1").copy(text="Known amount 730.")
        val view=EvidenceView { listOf(source) }
        assertTrue(view.index(listOf(source),2048,alreadyShown="[S1] 未展示摘录").contains(source.text))
        assertEquals("",view.index(listOf(source),2048,alreadyShown="[S1]\n"+source.text))
    }
    @Test fun pageQuotedActionNamesDoNotClassifyTheRecordedOperation() {
        val source=web("S1")
        val decision=JSONObject().put("role","assistant").put("tool_calls",JSONArray().put(call("read","read_web_page",JSONObject().put("source_ids",JSONArray(listOf("S1"))))))
        val results=JSONArray().put(roleMessage("tool","[S1] 动作 revise_draft：这是页面引文。"+source.text).put("tool_call_id","read"))
        val messages=JSONArray().put(roleMessage("system","keep"))
        AgentActions.forCapabilities(false,false,true).feedback(decision,results,false).forEach(messages::put)
        messages.put(roleMessage("tool","latest").put("tool_call_id","last"))
        val result=ToolContextView.compact(messages,1,listOf(source),JSONObject())
        assertTrue(result.getJSONObject(2).getString("content").startsWith("应用动作参考记录"))
        val unknown=JSONArray(messages.toString()).put(1,roleMessage("assistant","legacy undecodable operation"))
        assertEquals(unknown.toString(),ToolContextView.compact(unknown,1,listOf(source),JSONObject()).toString())
    }
    @Test fun webCacheReportsReusedPagesSeparatelyFromNetworkReads()=runBlocking {
        var sources=listOf(web("S1"),web("S2")); var requests=0
        val p=ResearchProgress(JSONObject()); val workflow=WebReadWorkflow(db.dao(),WebPageReader { requests++; WebPage("verified public record","complete") })
        val first=workflow.run(listOf("S1","S2"),sources,p,2048,"record","") { sources=it }
        val next=workflow.run(listOf("S1","S2"),sources,p,2048,"record","") { sources=it }
        assertEquals(1,requests); assertEquals(1,first.count); assertEquals(0,first.reusedCount)
        assertEquals(0,next.count); assertEquals(1,next.reusedCount)
    }
    private suspend fun runAgent(search: Boolean,native: Boolean) {
        db.dao().putAccount(MailAccount(id="a",email="fixture@example.test"))
        db.dao().putConversation(Conversation(id="c",accountId="a"))
        db.dao().putMessages(listOf(MailMessage("m","a","INBOX",1,1,"合成通知","sender","sender@example.test",sentAt=0,
            body="请查看资料。",html="<a href=\"https://example.org/record\">查看</a>")))
        var requests=0; var fetched=0; var searches=0
        val fresh="New verified amount 730 yuan."
        val sourceId=if(search) "S1" else "S2"
        val firstName=if(search) "web_search" else "read_evidence"
        val firstArgs=if(search) JSONObject().put("queries",JSONArray(listOf("public record")))
            else JSONObject().put("source_id",sourceId).put("start",0).put("max_chars",4000)
        val client=object: ModelClient {
            override suspend fun test(profile: ModelProfile)=profile
            override fun generate(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?)=flow {
                requests++
                if(requests==4) {
                    val latest=(0 until messages.length()).map { messages.getJSONObject(it) }.last { it.optString("role")=="tool" || it.optString("content").startsWith("应用动作执行结果") }
                    assertTrue("Fresh page text must replace the old rendered receipt",latest.optString("content").contains(fresh))
                    emit(ModelEvent.Completed(roleMessage("assistant","已核对。[${sourceId}]")))
                } else {
                    val name=if(requests==2) "read_web_page" else firstName
                    val args=if(requests==2) JSONObject().put("source_ids",JSONArray(listOf(sourceId))) else firstArgs
                    emit(ModelEvent.Completed(roleMessage("assistant",JSONObject().put("mailpilot_action",name).put("arguments",args).toString())))
                }
            }
        }
        val agent=LocalAgent(db.dao(),MailRepositoryImpl(db,PlainTestSecrets(),app.filesDir),processor,client,
            object: WebSearchClient { override suspend fun search(config: ServiceConfig,query: String): List<SourceChunk> {
                searches++; return listOf(web("").copy(text="Original search excerpt"))
            } }).apply { pageReader=WebPageReader { fetched++; WebPage(fresh,"complete") } }
        val result=agent.run("a","INBOX",if(search) emptyList() else listOf(Selection("m")),"核对公开资料",ModelProfile(thinkingMode="disabled",supportsTools=native),null,
            conversationId="c",options=ChatRequestOptions(webSearch=search))
        assertEquals(4,requests); assertEquals(1,fetched); assertEquals(if(search) 1 else 0,searches)
        assertFalse(result.partial); assertTrue(db.dao().allDrafts().isEmpty())
    }
}
