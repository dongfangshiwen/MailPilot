package app.mailpilot

import android.app.Application
import app.mailpilot.ai.*
import app.mailpilot.data.*
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import okhttp3.mockwebserver.*
import org.json.*
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.*
import org.robolectric.annotation.Config
import java.io.File

@RunWith(RobolectricTestRunner::class)
@Config(sdk=[28],application=Application::class)
class Vision25HttpTest {
    private val dir get()=RuntimeEnvironment.getApplication().filesDir
    private fun image(n: Int)=SourceChunk(id="S$n",messageId="",title="image$n",location="image",imagePath=File(dir,"http25-$n.jpg").apply { writeBytes(ByteArray(600) { n.toByte() }) }.path)
    private fun client()=CompatibleModelClient(PlainTestSecrets(),allowHttpForTests=true)
    @Test fun bodyDiagnosticsCountActualRequestsAndLimitsNeverRetrySilently(): Unit=runBlocking {
        val server=MockWebServer(); server.start()
        try {
            val p=ModelProfile(model="doubao-seed-evolving",provider="volcengine",baseUrl=server.url("/api/plan/v3").toString(),thinkingMode="disabled")
            val messages=JSONArray().put(roleMessage("system","短提示")).put(VisionRequestPlanner.message("问题和所选正文 ORDER-25",(1..5).map(::image)))
            for(status in listOf(413,401,403,429,400)) {
                val body=if(status==400) "{\"error\":{\"message\":\"maximum context length exceeded\"}}" else "{}"
                server.enqueue(MockResponse().setResponseCode(status).setBody(body))
                val events=mutableListOf<ModelEvent>()
                val failure=runCatching { client().generate(p,messages).collect { events+=it } }.exceptionOrNull() as ModelFailure
                assertEquals(status in listOf(413,400),failure.info.action=="multimodal_choice")
                val sent=events.filterIsInstance<ModelEvent.Diagnostics>().single().value
                assertEquals(5,sent.getInt("imagesInRequest")); assertEquals("request_body_sent",sent.getString("event"))
                val request=server.takeRequest(); val raw=request.body.readUtf8()
                assertEquals(sent.getLong("bodyBytes"),raw.toByteArray().size.toLong())
                assertTrue(raw.contains("ORDER-25")); assertEquals(5,Regex("data:image/jpeg;base64").findAll(raw).count())
            }
            assertEquals(5,server.requestCount)
        } finally { server.shutdown() }
    }
    @Test fun exactRequestBodyGuardStopsBeforeNetworkAndPreservesUnknownTokenTrial(): Unit=runBlocking {
        val server=MockWebServer(); server.start()
        try {
            val p=ModelProfile(model="unknown-vision",baseUrl=server.url("/v1").toString(),thinkingMode="disabled")
            val images=(1..5).map(::image)
            val messages=JSONArray().put(VisionRequestPlanner.message("说明这些图",images))
            assertTrue(ContextBudgetPlanner.estimate(messages,profile=p,includeUncertainImages=true)>ContextBudgetPlanner.limits(p).input)
            ContextBudgetPlanner.requireFits(p,messages)
            val large=images.map { s -> java.io.RandomAccessFile(s.imagePath,"rw").use { it.setLength(6L*1024*1024) }; s }
            val failure=runCatching { client().generate(p,JSONArray().put(VisionRequestPlanner.message("完整问题",large))).toList() }.exceptionOrNull() as ModelFailure
            assertEquals("multimodal_choice",failure.info.action); assertEquals(0,server.requestCount)
            assertTrue(large.all { File(it.imagePath).isFile })
            large.forEach { File(it.imagePath).delete() }
        } finally { server.shutdown() }
    }
}
