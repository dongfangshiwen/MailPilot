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
import app.mailpilot.platform.MailCoordinator
import app.mailpilot.platform.MailState
import app.mailpilot.services.WebSearchClient
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import org.json.*
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File

/** Real Android extraction, Room, Agent, bridge and Flutter; model/search responses are synthetic. */
@RunWith(AndroidJUnit4::class)
class Search30DeviceTest {
    @Test fun selectedMailAndThreeDocumentsResolveFollowupsOnApi36(): Unit=runBlocking {
        val instrumentation=InstrumentationRegistry.getInstrumentation()
        val context=instrumentation.targetContext
        val db=Room.inMemoryDatabaseBuilder(context,MailDatabase::class.java).build()
        val fixtures=mutableListOf<File>()
        try {
            val dao=db.dao()
            dao.putAccount(MailAccount(id="a",email="fixture@example.test"))
            dao.putConversation(Conversation(id="c",accountId="a"))
            dao.putMessages(listOf(MailMessage("m","a","INBOX",1,1,"Makito M30 设备咨询","sender","sender@example.test",sentAt=0,body="请根据附件核对产品技术规范。")))
            val attachments=(1..3).map { n ->
                val file=File.createTempFile("search30-$n-",".txt",context.cacheDir).also { it.writeText("附件$n：Makito M30 产品技术规范，核对接口、压力等级和适用范围。"); fixtures+=it }
                Attachment(id="attachment$n",messageId="m",name="技术资料$n.txt",mimeType="text/plain",size=file.length(),partPath="fixture-$n",localPath=file.path)
            }
            dao.putAttachments(attachments)
            val selected=listOf(Selection("m",attachments.map { it.id }))
            val stages=mutableListOf<String>(); val queries=mutableListOf<String>()
            val client=object: ModelClient {
                override suspend fun test(profile: ModelProfile)=profile
                override fun generate(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?)=error("Use typed stages")
                override fun generateRequest(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?,options: ModelRequestOptions)=flow {
                    stages+=options.stage
                    val raw=messages.toString()
                    if(!(0 until messages.length()).any { messages.getJSONObject(it).optString("role")=="tool" || messages.getJSONObject(it).optString("content").startsWith("应用动作执行结果") }) {
                        (1..3).forEach { assertTrue(raw.contains("技术资料$it.txt")) }
                        assertTrue(raw.contains("Makito M30")); assertEquals(profile.supportsTools,tools!=null)
                        val action=roleMessage("assistant","{\"mailpilot_action\":\"web_search\",\"arguments\":{\"queries\":[\"Makito M30 产品技术规范\"]}}")
                        emit(ModelEvent.Completed(if(profile.supportsTools) AgentActions(requireNotNull(tools)).normalize(action,false) else action))
                    } else {
                        assertTrue(raw.contains("合成网页片段"))
                        emit(ModelEvent.Completed(roleMessage("assistant","已根据邮件和三份附件中的 Makito M30，检索产品技术规范。\n\n可对照接口、压力等级和适用范围逐项核验。")))
                    }
                }
            }
            val search=object: WebSearchClient { override suspend fun search(config: ServiceConfig,query: String): List<SourceChunk> {
                queries+=query
                return listOf(SourceChunk(messageId="",title="产品规范（合成测试）",location="网页",text="合成网页片段：接口、压力等级与适用范围。",kind="web",url="https://example.test/spec"))
            } }
            val agent=LocalAgent(dao,MailRepositoryImpl(db,AndroidSecrets(),context.filesDir),AndroidAttachmentProcessor(context),client,search)
            val history=mutableListOf<ChatEntry>()
            for(native in listOf(false,true)) for(q in listOf("搜索一下网络上有没有相关的资料","关于邮件里面的内容","就这封邮件里面的附件相关信息")) {
                val result=agent.run("a","INBOX",selected,q,ModelProfile(thinkingMode="disabled",supportsTools=native),null,history=history,conversationId="c",options=ChatRequestOptions(webSearch=true))
                history+=ChatEntry(conversationId="c",role="user",text=q)
                history+=ChatEntry(conversationId="c",role="assistant",text=result.text,sourcesJson=JsonCodec.sources(result.sources))
                assertEquals(1,result.sources.count { it.kind=="web" })
                assertFalse(result.text.contains("具体关键词"))
            }
            assertEquals(6,queries.size); assertEquals(12,stages.count { it=="answer" })
            assertTrue(dao.allDrafts().isEmpty())
            ActivityScenario.launch(MainActivity::class.java).use { scenario ->
                lateinit var flow: MutableStateFlow<MailState>; lateinit var coordinator: MailCoordinator
                scenario.onActivity { activity ->
                    coordinator=MainActivity::class.java.getDeclaredField("vm").apply { isAccessible=true }.get(activity) as MailCoordinator
                    @Suppress("UNCHECKED_CAST")
                    val state=MailCoordinator::class.java.getDeclaredField("_state").apply { isAccessible=true }.get(coordinator) as MutableStateFlow<MailState>
                    flow=state
                }
                coordinator.graph.ready.await(); instrumentation.waitForIdleSync(); Thread.sleep(500)
                val before=flow.value
                assertFalse("Do not replace an active user generation",before.analyzing || before.busy)
                try {
                    scenario.onActivity { flow.value=before.copy(tab=1,source=null,detail=null,editor=null,sendPreview=null,pdfChoice=null,entries=history.takeLast(2),streaming="",reasoning=ReasoningSnapshot(),status="",agentStage="") }
                    fun contains(node: AccessibilityNodeInfo?): Boolean = node!=null && (node.text?.contains("可对照接口")==true || node.contentDescription?.contains("可对照接口")==true || (0 until node.childCount).any { contains(node.getChild(it)) })
                    val deadline=System.nanoTime()+15_000_000_000L
                    while(!contains(instrumentation.uiAutomation.rootInActiveWindow) && System.nanoTime()<deadline) Thread.sleep(100)
                    assertTrue(contains(instrumentation.uiAutomation.rootInActiveWindow)); Thread.sleep(250)
                    val image=instrumentation.uiAutomation.takeScreenshot()
                    File(context.getExternalFilesDir(null),"search30-completed.png").outputStream().use { image.compress(Bitmap.CompressFormat.PNG,100,it) }; image.recycle()
                } finally { scenario.onActivity { flow.value=before } }
            }
        } finally { db.close(); fixtures.forEach { it.delete() } }
    }
}
