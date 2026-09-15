package app.mailpilot

import android.graphics.Bitmap
import android.view.accessibility.AccessibilityNodeInfo
import androidx.room.Room
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import app.mailpilot.ai.*
import app.mailpilot.attachments.AndroidAttachmentProcessor
import app.mailpilot.data.*
import app.mailpilot.mail.MailRepositoryImpl
import app.mailpilot.platform.*
import app.mailpilot.services.WebSearchClient
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import org.json.*
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File
import java.io.IOException

/** Real API36 image processing/Room/Agent/bridge; all external responses are synthetic. */
@RunWith(AndroidJUnit4::class)
class Context31DeviceTest {
    @Test fun fiveCachedImagesAndTwoLongSearchesStayWithinArk32k(): Unit=runBlocking {
        val instrumentation=InstrumentationRegistry.getInstrumentation(); val context=instrumentation.targetContext
        val db=Room.inMemoryDatabaseBuilder(context,MailDatabase::class.java).build(); val fixtures=mutableListOf<File>()
        try {
            val dao=db.dao(); dao.putAccount(MailAccount(id="a",email="fixture@example.test")); dao.putConversation(Conversation(id="c",accountId="a"))
            val files=(1..5).map { n ->
                val file=File.createTempFile("context31-$n-",".png",context.cacheDir).also { fixtures+=it }
                val bitmap=Bitmap.createBitmap(96,96,Bitmap.Config.ARGB_8888); bitmap.eraseColor(0xff000000.toInt()+n*1000)
                file.outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG,100,it) }; bitmap.recycle()
                LocalMaterial(id="file$n",conversationId="c",name="图片$n.png",mime="image/png",path=file.path,size=file.length()).also { dao.putMaterial(it) }
            }
            val profile=ModelProfile(model="doubao-seed-evolving",baseUrl="https://ark.cn-beijing.volces.com/api/plan/v3",contextTokens=32768)
            assertEquals(24576,ContextBudgetPlanner.limits(profile).input)
            var images=0; var queries=0; var fail=false; var answers=0
            val client=object: ModelClient {
                override suspend fun test(profile: ModelProfile)=profile
                override fun generate(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?)=error("typed")
                override fun generateRequest(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?,options: ModelRequestOptions)=flow {
                    ContextBudgetPlanner.requireFits(profile,messages,tools)
                    val count=VisionRequestPlanner.imageCount(messages); images+=count
                    val hasResult=(0 until messages.length()).any { messages.getJSONObject(it).optString("role")=="tool" || messages.getJSONObject(it).optString("content").startsWith("应用动作执行结果") }
                    val answer=when {
                        options.stage=="compression" -> roleMessage("assistant","资料总结：日期2026-09-10，金额500元，产品规格需按来源核对。")
                        count>0 -> roleMessage("assistant","五张图片展示测试产品的不同接口。日期2026-09-10，预算500元。")
                        !hasResult -> {
                            val action=roleMessage("assistant","""{"mailpilot_action":"web_search","arguments":{"queries":["测试产品接口规范","测试产品规格说明"]}}""")
                            if(profile.supportsTools) AgentActions(requireNotNull(tools)).normalize(action,false) else action
                        }
                        fail -> throw IOException("fixture final response")
                        else -> { answers++; assertTrue(messages.toString().contains("未完整")); roleMessage("assistant","已复用 5 张图片此前分析，并完成两项检索。\n\n图文资料与搜索摘录已合并处理。更深细节可继续按来源读取。\n\n本轮未重复上传图片，也未发送邮件。") }
                    }
                    emit(ModelEvent.Completed(answer))
                }
            }
            val search=object: WebSearchClient { override suspend fun search(config: ServiceConfig,query: String): List<SourceChunk> {
                synchronized(this) { queries++ }; return (1..5).map { n -> SourceChunk(messageId="",title="产品规范$n（合成）",location="网页",kind="web",url="https://example.test/${stableId(query)}/$n",text="规范\"值\"\\路径 😀\n|参数|值|\n".repeat(900)) }
            } }
            val agent=LocalAgent(dao,MailRepositoryImpl(db,AndroidSecrets(),context.filesDir),AndroidAttachmentProcessor(context),client,search)
            agent.run("a","INBOX",emptyList(),"总结图片",profile,null,conversationId="c",localMaterials=files)
            assertEquals(5,images)
            var result: AnalysisResult?=null
            for(native in listOf(false,true)) {
                val run="run-$native"; dao.putTurn(TurnSnapshot(run,"c","a","INBOX","[]",1,localJson=JSONArray(files.map { it.fields() }).toString()))
                suspend fun ask()=agent.run("a","INBOX",emptyList(),"总结所选邮件，并联网搜索一下相关资料",profile.copy(supportsTools=native),null,conversationId="c",requestId=run,localMaterials=files,options=ChatRequestOptions(webSearch=true))
                fail=true; assertTrue(runCatching { ask() }.exceptionOrNull() is IOException)
                val searched=queries; fail=false; result=ask(); assertEquals(searched,queries)
            }
            assertEquals(4,queries); assertEquals(5,images); assertEquals(2,answers); assertTrue(dao.allDrafts().isEmpty())
            val completed=requireNotNull(result)
            ActivityScenario.launch(MainActivity::class.java).use { scenario ->
                lateinit var flow: MutableStateFlow<MailState>; lateinit var coordinator: MailCoordinator
                scenario.onActivity { activity ->
                    coordinator=MainActivity::class.java.getDeclaredField("vm").apply { isAccessible=true }.get(activity) as MailCoordinator
                    @Suppress("UNCHECKED_CAST")
                    val state=MailCoordinator::class.java.getDeclaredField("_state").apply { isAccessible=true }.get(coordinator) as MutableStateFlow<MailState>; flow=state
                }
                coordinator.graph.ready.await(); instrumentation.waitForIdleSync(); Thread.sleep(500)
                val before=flow.value; assertFalse(before.analyzing || before.busy)
                try {
                    val entries=listOf(ChatEntry(conversationId="c",role="user",text="总结图片，并联网核对相关资料"),ChatEntry(conversationId="c",role="assistant",text=completed.text))
                    scenario.onActivity { flow.value=before.copy(tab=1,source=null,detail=null,editor=null,sendPreview=null,pdfChoice=null,entries=entries,streaming="",reasoning=ReasoningSnapshot(),status="",agentStage="") }
                    fun contains(node: AccessibilityNodeInfo?): Boolean=node!=null && (node.text?.contains("未重复上传")==true || node.contentDescription?.contains("未重复上传")==true || (0 until node.childCount).any { contains(node.getChild(it)) })
                    val deadline=System.nanoTime()+15_000_000_000L
                    while(!contains(instrumentation.uiAutomation.rootInActiveWindow) && System.nanoTime()<deadline) Thread.sleep(100)
                    assertTrue(contains(instrumentation.uiAutomation.rootInActiveWindow)); Thread.sleep(250)
                    val image=instrumentation.uiAutomation.takeScreenshot()
                    File(context.getExternalFilesDir(null),"context31-completed.png").outputStream().use { image.compress(Bitmap.CompressFormat.PNG,100,it) }; image.recycle()
                    val report=ContextBudgetPlanner.report(profile,JSONArray().put(roleMessage("user",""))).put("stage","compression").put("model",profile.model).put("estimatedInputTokens",27541)
                    val failure=FailureInfo("context_limit","合成预算边界示例：已完成资料保留，请调整资料。","budget",profile.model,report)
                    scenario.onActivity { flow.value=flow.value.copy(entries=listOf(entries.first(),ChatEntry(conversationId="c",role="assistant",text="本轮资料已保留，请查看预算。",resultStatus="failed",failureJson=failure.json()))) }
                    fun find(node: AccessibilityNodeInfo?,text: String): AccessibilityNodeInfo? {
                        if(node==null) return null
                        if(node.text?.toString()==text || node.contentDescription?.toString()==text) return node
                        for(i in 0 until node.childCount) find(node.getChild(i),text)?.let { return it }
                        return null
                    }
                    val buttonDeadline=System.nanoTime()+10_000_000_000L; var button: AccessibilityNodeInfo?=null
                    while(button==null && System.nanoTime()<buttonDeadline) { button=find(instrumentation.uiAutomation.rootInActiveWindow,"查看预算"); if(button==null) Thread.sleep(100) }
                    var target=requireNotNull(button)
                    while(!target.isClickable && target.parent!=null) target=target.parent
                    assertTrue(target.performAction(AccessibilityNodeInfo.ACTION_CLICK))
                    val sheetDeadline=System.nanoTime()+10_000_000_000L
                    while(find(instrumentation.uiAutomation.rootInActiveWindow,"本轮预算与诊断")==null && System.nanoTime()<sheetDeadline) Thread.sleep(100)
                    assertNotNull(find(instrumentation.uiAutomation.rootInActiveWindow,"本轮预算与诊断")); Thread.sleep(350)
                    val budgetImage=instrumentation.uiAutomation.takeScreenshot()
                    File(context.getExternalFilesDir(null),"context31-budget.png").outputStream().use { budgetImage.compress(Bitmap.CompressFormat.PNG,100,it) }; budgetImage.recycle()
                    instrumentation.uiAutomation.performGlobalAction(android.accessibilityservice.AccessibilityService.GLOBAL_ACTION_BACK)
                } finally { scenario.onActivity { flow.value=before } }
            }
        } finally { db.close(); fixtures.forEach { it.delete() } }
    }
    @Test fun finalEncodedSummaryRequestsResumeAcrossInterruption(): Unit=runBlocking {
        val context=InstrumentationRegistry.getInstrumentation().targetContext; val db=Room.inMemoryDatabaseBuilder(context,MailDatabase::class.java).build()
        try {
            val dao=db.dao(); dao.putConversation(Conversation(id="c",contextSummary="保留原记忆")); dao.putTurn(TurnSnapshot("r","c","","INBOX","[]",1))
            val p=ModelProfile(baseUrl="https://ark.cn-beijing.volces.com/api/plan/v3",model="doubao-seed-evolving",contextTokens=32768)
            var calls=0; var fail=true; val inputs=mutableListOf<String>()
            val client=object: ModelClient {
                override suspend fun test(profile: ModelProfile)=profile
                override fun generate(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?)=flow {
                    ContextBudgetPlanner.requireFits(profile,messages); if(++calls==2 && fail) throw IOException("batch two")
                    inputs+=JSONObject(messages.getJSONObject(1).getString("content")).getString("new_history")
                    emit(ModelEvent.Completed(roleMessage("assistant","姓名李明，日期2026-09-10，金额500元。[T1:S1]")))
                }
            }
            val source="长资料\\\"😀".repeat(14000)
            suspend fun reduce()=ContextReducer(dao,client).reduce(listOf(source),"",1200,p,"r")
            assertTrue(runCatching { reduce() }.exceptionOrNull() is IOException)
            fail=false; reduce(); assertEquals(source,inputs.joinToString("")); assertEquals("保留原记忆",dao.conversation("c")!!.contextSummary)
        } finally { db.close() }
    }
}
