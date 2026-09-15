package app.mailpilot

import android.app.Application
import androidx.room.Room
import app.mailpilot.ai.*
import app.mailpilot.data.*
import app.mailpilot.services.*
import kotlinx.coroutines.runBlocking
import org.json.*
import org.junit.*
import org.junit.Assert.*
import org.junit.runner.RunWith
import org.robolectric.*
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk=[28],application=Application::class)
class WebCache39Test {
    private lateinit var db: MailDatabase
    @Before fun setup() { db=Room.inMemoryDatabaseBuilder(RuntimeEnvironment.getApplication(),MailDatabase::class.java).allowMainThreadQueries().build() }
    @After fun close() { db.close() }
    private fun source()=SourceChunk(id="S1",messageId="",kind="web",url="https://example.org/page",title="record",location="web",text="Loading record ".repeat(100),retrieval="webpage")
    @Test fun legacyCompleteCacheIsPreservedButRevalidatedAndThenReused()=runBlocking {
        val root=java.nio.file.Files.createTempDirectory("web39-").toFile()
        try {
            val store=WebEvidenceStore(root,"a","c")
            val old=store.save(source()).copy(webReadVersion=0,webReadStatus="")
            var current=listOf(store.restore(JsonCodec.sources(JsonCodec.sources(listOf(old))).single()))
            assertEquals("webpage_unverified",current.single().retrieval); assertEquals(old.text,current.single().text)
            var calls=0
            val flow=WebReadWorkflow(db.dao(),WebPageReader { calls++; WebPage("verified data","complete") },store)
            repeat(2) { flow.run(listOf("S1"),current,ResearchProgress(JSONObject()),4096,"data","") { current=it } }
            assertEquals(1,calls); assertEquals("verified data",current.single().text)
            assertEquals(WebReadWorkflow.READ_POLICY_VERSION,current.single().webReadVersion)
            assertEquals("complete",JsonCodec.sources(JsonCodec.sources(current)).single().webReadStatus)
        } finally { root.deleteRecursively() }
    }
    @Test fun everyPartialStatusStaysPartialAcrossRetryAndRestart()=runBlocking {
        for(status in listOf("loading_incomplete","resource_failed","resource_limit","interaction_required","limited_content")) {
            var current=listOf(source().copy(retrieval="excerpt")); var calls=0
            val flow=WebReadWorkflow(db.dao(),WebPageReader { calls++; WebPage("partial facts ".repeat(1000),status,true) })
            var progress=ResearchProgress(JSONObject())
            repeat(2) {
                val read=flow.run(listOf("S1"),current,progress,4096,"facts","") { current=it }
                assertFalse(read.cacheable); assertTrue(read.text.contains("完整性未核实"))
                current=JsonCodec.sources(JsonCodec.sources(current)); progress=ResearchProgress(JSONObject(progress.data.toString()))
            }
            assertEquals(1,calls); assertEquals("webpage_partial",current.single().retrieval)
            assertEquals(status,current.single().webReadStatus); assertEquals(4000,current.single().text.length); assertEquals("",current.single().contentKey)
        }
    }
    @Test fun oldReceiptsAndSummaryCannotOverrideUpdatedEvidenceOrReplayDraft() {
        val progress=ResearchProgress(JSONObject()); val args=JSONObject().put("source_ids",JSONArray(listOf("S1")))
        val oldKey=stableId("read_web_page{\"source_ids\":[\"S1\"]}")
        progress.saveReceipt(oldKey,"old complete"); assertNull(progress.receipt(progress.key("read_web_page",args)))
        val decision=JSONObject("""{"role":"assistant","tool_calls":[{"id":"read","function":{"name":"read_web_page"}},{"id":"draft","function":{"name":"create_draft"}}]}""")
        val draft=JSONObject().put("role","tool").put("tool_call_id","draft").put("content","saved candidate")
        val exchange=JSONArray().put(decision).put(JSONObject().put("role","tool").put("tool_call_id","read").put("content","fully loaded")).put(draft)
        val state=JSONObject().put("exchanges",exchange).put("candidate",JSONObject().put("id","kept")).put("round",6).put("toolSummary",JSONObject().put("text","fully loaded")).put("toolViews",JSONObject())
        WebReadCheckpoint.upgrade(state,listOf(WebEvidenceStore.normalize(source())))
        assertTrue(exchange.getJSONObject(1).getString("content").contains("完整性待核对"))
        assertEquals("saved candidate",draft.getString("content")); assertEquals("kept",state.getJSONObject("candidate").getString("id"))
        assertEquals(6,state.getInt("round")); assertFalse(state.has("toolSummary")); assertFalse(state.has("toolViews"))
    }
}
