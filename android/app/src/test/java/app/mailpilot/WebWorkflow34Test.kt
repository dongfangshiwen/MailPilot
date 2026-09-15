package app.mailpilot

import android.app.Application
import androidx.room.Room
import app.mailpilot.ai.*
import app.mailpilot.data.*
import app.mailpilot.services.*
import kotlinx.coroutines.*
import org.json.JSONObject
import org.junit.*
import org.junit.Assert.*
import org.junit.runner.RunWith
import org.robolectric.*
import org.robolectric.annotation.Config
import java.util.concurrent.atomic.AtomicInteger

@RunWith(RobolectricTestRunner::class)
@Config(sdk=[28],application=Application::class)
class WebWorkflow34Test {
    private lateinit var db: MailDatabase
    @Before fun setup() { db=Room.inMemoryDatabaseBuilder(RuntimeEnvironment.getApplication(),MailDatabase::class.java).allowMainThreadQueries().build() }
    @After fun close() { db.close() }
    private fun sources(n: Int)=(1..n).map { SourceChunk(id="S$it",messageId="",title="page $it",kind="web",url="https://example.org/$it",location="search",text="excerpt") }
    @Test fun renderedControlsDoNotBecomeCompleteCachedEvidence()=runBlocking {
        var current=sources(1); var calls=0
        val flow=WebReadWorkflow(db.dao(),WebPageReader { calls++; WebPage("下载到手机","limited_content",true) })
        val progress=ResearchProgress(JSONObject())
        val first=flow.run(listOf("S1"),current,progress,4096,"record","") { current=it }
        assertFalse(first.cacheable); assertEquals(1,first.count)
        assertTrue(first.text.contains("不代表已读取图片或文件")); assertTrue(first.text.contains("下载到手机"))
        assertEquals("webpage_partial",current.single().retrieval); assertTrue(current.single().contentKey.isBlank())
        flow.run(listOf("S1"),current,progress,4096,"record","") { current=it }
        assertEquals(1,calls)
    }
    @Test fun olderFailedPolicyIsRetriedOnceAndCurrentFailureIsReused()=runBlocking {
        val current=sources(1); var calls=0
        val progress=ResearchProgress(JSONObject())
        progress.pages.put(stableId(current.single().url),JSONObject().put("status","empty_or_dynamic"))
        val flow=WebReadWorkflow(db.dao(),WebPageReader { calls++; WebPage(status="interaction_required") })
        repeat(2) { flow.run(listOf("S1"),current,progress,4096,"read","") {} }
        assertEquals(1,calls)
        assertEquals(WebReadWorkflow.READ_POLICY_VERSION,progress.pages.getJSONObject(stableId(current.single().url)).getInt("policyVersion"))
    }
    @Test fun explicitNewAttemptCanRetryFailedPageWithoutRepeatingWithinAttempt()=runBlocking {
        db.dao().putConversation(Conversation(id="web-c"))
        db.dao().putTurn(TurnSnapshot("web-run","web-c","","INBOX","[]",1))
        val current=sources(1); var calls=0; val progress=ResearchProgress(JSONObject())
        val flow=WebReadWorkflow(db.dao(),WebPageReader { calls++; WebPage(status="connection_failed") })
        RunTelemetry.begin(db.dao(),"web-run","first")
        repeat(2) { flow.run(listOf("S1"),current,progress,4096,"read","web-run") {} }
        assertEquals(1,calls)
        RunTelemetry.begin(db.dao(),"web-run","second")
        flow.run(listOf("S1"),current,progress,4096,"read","web-run") {}
        assertEquals(2,calls)
    }
    @Test fun pagesBoundedToEightAndTwoConcurrent()=runBlocking {
        var current=sources(10); val active=AtomicInteger(); val peak=AtomicInteger(); val calls=AtomicInteger()
        val flow=WebReadWorkflow(db.dao(),WebPageReader {
            calls.incrementAndGet(); val n=active.incrementAndGet(); peak.updateAndGet { maxOf(it,n) }
            try { delay(20); WebPage("verified public information".repeat(5),"complete") } finally { active.decrementAndGet() }
        })
        val progress=ResearchProgress(JSONObject())
        for(group in current.chunked(4)) flow.run(group.map { it.id },current,progress,4096,"information","") { current=it }
        assertEquals(8,calls.get()); assertEquals(2,peak.get()); assertEquals(8,current.count { it.retrieval=="webpage" })
    }
    @Test fun cancelPreservesSuccessfulSiblingAndRestartOnlyReadsMissingPage()=runBlocking {
        var current=sources(2); var slow=true; val completed=CompletableDeferred<Unit>(); val calls=mutableListOf<String>()
        val progress=ResearchProgress(JSONObject())
        val flow=WebReadWorkflow(db.dao(),WebPageReader { url ->
            synchronized(calls) { calls+=url }
            if(url.endsWith("/2") && slow) delay(10000)
            WebPage("verified facts for $url","complete")
        })
        val pending=launch { flow.run(listOf("S1","S2"),current,progress,4096,"facts","") { current=it; completed.complete(Unit) } }
        withTimeout(3000) { completed.await() }; pending.cancelAndJoin()
        assertEquals("webpage",current.first().retrieval); slow=false
        flow.run(listOf("S1","S2"),current,ResearchProgress(JSONObject(progress.data.toString())),4096,"facts","") { current=it }
        assertEquals(1,calls.count { it.endsWith("/1") }); assertEquals(2,calls.count { it.endsWith("/2") })
    }
    @Test fun persistedPageRestoresWithoutNetworkAndMissingFileCanBeFetchedAgain()=runBlocking {
        val root=java.nio.file.Files.createTempDirectory("web-flow34-").toFile()
        try {
            val store=WebEvidenceStore(root,"a","c"); var calls=0; var current=sources(1)
            val flow=WebReadWorkflow(db.dao(),WebPageReader { calls++; WebPage("verified public facts".repeat(1000),"complete") },store)
            val progress=ResearchProgress(JSONObject())
            flow.run(listOf("S1"),current,progress,4096,"facts","") { current=it }
            assertTrue(current.single().contentKey.isNotBlank())
            current=JsonCodec.sources(JsonCodec.sources(current))
            flow.run(listOf("S1"),current,progress,4096,"facts","") { current=it }
            assertEquals(1,calls); assertTrue(current.single().text.length>4000); assertTrue(current.single().contentKey.isNotBlank())
            current=JsonCodec.sources(JsonCodec.sources(current)); store.clear()
            flow.run(listOf("S1"),current,progress,4096,"facts","") { current=it }
            assertEquals(2,calls); assertEquals("webpage",current.single().retrieval)
        } finally { root.deleteRecursively() }
    }
}
