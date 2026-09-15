package app.mailpilot

import androidx.room.Room
import android.graphics.Bitmap
import android.view.accessibility.AccessibilityNodeInfo
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import app.mailpilot.ai.*
import app.mailpilot.data.*
import app.mailpilot.platform.*
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import org.json.*
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File

/** Real Android storage/recreation; model timing is deliberately synthetic, not a vendor benchmark. */
@RunWith(AndroidJUnit4::class)
class Context32DeviceTest {
    @Test fun quickCompressionSettingsLayout(): Unit=runBlocking {
        val instrumentation=InstrumentationRegistry.getInstrumentation(); val context=instrumentation.targetContext
        ActivityScenario.launch(MainActivity::class.java).use { scenario ->
            lateinit var state: MutableStateFlow<MailState>; lateinit var coordinator: MailCoordinator
            scenario.onActivity { activity ->
                coordinator=MainActivity::class.java.getDeclaredField("vm").apply { isAccessible=true }.get(activity) as MailCoordinator
                @Suppress("UNCHECKED_CAST")
                val flow=MailCoordinator::class.java.getDeclaredField("_state").apply { isAccessible=true }.get(coordinator) as MutableStateFlow<MailState>
                state=flow
            }
            coordinator.graph.ready.await(); instrumentation.waitForIdleSync(); delay(500)
            val before=state.value; assertFalse(before.busy || before.analyzing)
            try {
                scenario.onActivity { state.value=before.copy(tab=3,accounts=emptyList(),models=emptyList(),settings=before.settings.copy(fastCompression=true),source=null,detail=null,editor=null,sendPreview=null,pdfChoice=null) }
                fun find(node: AccessibilityNodeInfo?): AccessibilityNodeInfo? {
                    if(node==null) return null
                    if(node.text?.contains("上下文整理")==true || node.contentDescription?.contains("上下文整理")==true) return node
                    for(i in 0 until node.childCount) find(node.getChild(i))?.let { return it }
                    return null
                }
                var row: AccessibilityNodeInfo?=null; val end=System.nanoTime()+12_000_000_000L
                while(row==null && System.nanoTime()<end) { row=find(instrumentation.uiAutomation.rootInActiveWindow); if(row==null) delay(100) }
                assertNotNull(row); delay(300)
                val image=instrumentation.uiAutomation.takeScreenshot()
                File(context.getExternalFilesDir(null),"context32-settings.png").outputStream().use { image.compress(Bitmap.CompressFormat.PNG,100,it) }; image.recycle()
            } finally { scenario.onActivity { state.value=before } }
        }
    }
    @Test fun summaryRecoveryReuseAndSessionIsolation(): Unit=runBlocking {
        val context=InstrumentationRegistry.getInstrumentation().targetContext
        val db=Room.inMemoryDatabaseBuilder(context,MailDatabase::class.java).build()
        try {
            val dao=db.dao(); val p=ModelProfile(model="doubao-seed-evolving",baseUrl="https://ark.cn-beijing.volces.com/api/plan/v3",contextTokens=32768)
            for(id in listOf("a","b")) { dao.putConversation(Conversation(id=id,accountId="account")); dao.putTurn(TurnSnapshot("run-$id",id,"account","INBOX","[]",1)) }
            var calls=0
            val client=object: ModelClient {
                override suspend fun test(profile: ModelProfile)=profile
                override fun generate(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?)=error("typed")
                override fun generateRequest(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?,options: ModelRequestOptions)=flow {
                    calls++; delay(20); ContextBudgetPlanner.requireFits(profile,messages,tools)
                    emit(ModelEvent.Completed(roleMessage("assistant","a".repeat(285))))
                }
            }
            val summary=ContextReducer(dao,client).reduce(listOf("source"),"",1200,p,"run-a",preferredTokens=512)
            assertEquals(570,ContextBudgetPlanner.estimate(summary)); assertEquals(1,calls)
            val sources=(1..2).map { SourceChunk(id="T1:S$it",messageId="",kind="document",title="文档$it",location="正文",text="日期2026-09-10 金额500元\n".repeat(650)) }
            suspend fun prepare(id: String,conversation: String,values: List<SourceChunk>)=
                MaterialNotes(dao,client).prepare(values,16000,6000,CompressionPolicy.model(p,true),id,"account",conversation,{}, {})
            val baseline=calls; val coldStart=System.nanoTime(); prepare("run-a","a",sources)
            val coldMillis=(System.nanoTime()-coldStart)/1_000_000; val coldCalls=calls-baseline
            dao.putTurn(TurnSnapshot("restart","a","account","INBOX","[]",2))
            val hitStart=System.nanoTime(); prepare("restart","a",sources.map { it.copy(id=it.id.replace("T1","T2")) })
            val warmMillis=(System.nanoTime()-hitStart)/1_000_000
            assertTrue(coldCalls>0); assertEquals(baseline+coldCalls,calls)
            val beforeOther=calls; prepare("run-b","b",sources); assertTrue(calls>beforeOther)
            assertTrue(dao.allDrafts().isEmpty()); assertEquals(9,db.openHelper.readableDatabase.version)
            val report=JSONObject().put("syntheticModelDelayMillis",20).put("coldModelCalls",coldCalls).put("warmModelCalls",0)
                .put("coldMillis",coldMillis).put("warmMillis",warmMillis).put("otherConversationReused",false)
                .put("summaryEstimate",570).put("preferredBudget",512).put("actualBudget",1200).put("realProviderRequests",false)
            File(context.getExternalFilesDir(null),"context32-metrics.json").writeText(report.toString(2))
        } finally { db.close() }
    }
}
