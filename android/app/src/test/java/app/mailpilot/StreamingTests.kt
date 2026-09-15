package app.mailpilot

import android.app.Application
import app.mailpilot.ai.*
import app.mailpilot.data.ModelProfile
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import java.util.concurrent.TimeUnit

@RunWith(RobolectricTestRunner::class)
@Config(sdk=[28],application=Application::class)
class StreamingTests {
    private fun chunk(delta: String,finish: String?=null) = "data: "+JSONObject().put("choices",JSONArray().put(
        JSONObject().put("index",0).put("delta",JSONObject(delta)).put("finish_reason",finish ?: JSONObject.NULL)))+"\r\n\r\n"
    private val end = chunk("{}","stop")+"data: [DONE]\r\n\r\n"
    private fun profile(server: MockWebServer)=ModelProfile(baseUrl=server.url("/v1").toString(),model="test",supportsStreaming=false)
    private fun client()=CompatibleModelClient(PlainTestSecrets(),allowHttpForTests=true)

    @Test fun untestedModelDeliversChineseDeltaBeforeDelayedResponseCompletes()=runBlocking {
        val server=MockWebServer(); server.start()
        try {
            val first=chunk("""{"content":"你好，**预算**"}""")
            server.enqueue(MockResponse().setHeader("Content-Type","text/event-stream; charset=utf-8")
                .setBody(first+chunk("""{"content":"需要确认。"}""")+end)
                .throttleBody(first.toByteArray().size.toLong(),500,TimeUnit.MILLISECONDS))
            val firstReceived=CompletableDeferred<String>(); val events=mutableListOf<ModelEvent>()
            val job=launch { client().generate(profile(server),JSONArray()).collect {
                events+=it; if(it is ModelEvent.Delta) firstReceived.complete(it.text)
            } }
            assertEquals("你好，**预算**",withTimeout(4000) { firstReceived.await() })
            assertTrue("Delta must arrive before completion, not a fake typing animation",job.isActive)
            assertFalse(events.any { it is ModelEvent.Completed })
            withTimeout(5000) { job.join() }
            val request=server.takeRequest()
            assertTrue(JSONObject(request.body.readUtf8()).getBoolean("stream"))
            assertEquals("text/event-stream",request.getHeader("Accept"))
            assertEquals("你好，**预算**需要确认。",(events.last() as ModelEvent.Completed).message.getString("content"))
        } finally { server.shutdown() }
    }

    @Test fun reasoningAndEncryptedMetadataSurviveNullDeltasAndUsageOnlyTail()=runBlocking {
        val server=MockWebServer(); server.start()
        try {
            val body="\uFEFF: keep-alive\r\n\r\n"+
                chunk("""{"role":"assistant","content":null,"reasoning_content":"检查"}""")+
                chunk("""{"reasoning_content":"资料","encrypted_content":"opaque"}""")+
                chunk("""{"content":"答复","reasoning_content":null}""")+
                chunk("{}","stop")+"data: {\"choices\":[],\"usage\":{\"total_tokens\":42}}\r\n\r\ndata: [DONE]\r\n\r\n"
            server.enqueue(MockResponse().setHeader("Content-Type","text/event-stream").setBody(body))
            val events=client().generate(profile(server),JSONArray()).toList()
            assertEquals(listOf("检查","资料"),events.filterIsInstance<ModelEvent.Thinking>().map { it.text })
            assertEquals(listOf("答复"),events.filterIsInstance<ModelEvent.Delta>().map { it.text })
            val message=(events.last() as ModelEvent.Completed).message
            assertEquals("检查资料",message.getString("reasoning_content"))
            assertEquals("opaque",message.getString("encrypted_content"))
        } finally { server.shutdown() }
    }

    @Test fun nullToolFragmentsDoNotCorruptArgumentsOrReasoning() {
        val a=StreamAccumulator()
        a.accept(JSONObject("""{"choices":[{"delta":{"reasoning_content":"先检索","tool_calls":[{"index":0,"id":"call1","function":{"name":"search_emails","arguments":"{"}}]}}]}"""))
        a.accept(JSONObject("""{"choices":[{"delta":{"content":null,"tool_calls":[{"index":0,"id":null,"function":{"name":null,"arguments":"}"}}]},"finish_reason":"tool_calls"}]}"""))
        val message=a.message(); val call=message.getJSONArray("tool_calls").getJSONObject(0)
        assertEquals("call1",call.getString("id"))
        assertEquals("{}",call.getJSONObject("function").getString("arguments"))
        assertEquals("search_emails",call.getJSONObject("function").getString("name"))
        assertEquals("先检索",message.getString("reasoning_content"))
    }

    @Test fun reasoningArrivesBeforeAnswerAndCancellationKeepsReceivedText()=runBlocking {
        val server=MockWebServer(); server.start()
        try {
            val first=chunk("""{"reasoning_content":"先核对资料"}""")
            server.enqueue(MockResponse().setHeader("Content-Type","text/event-stream").setBody(first+chunk("""{"content":"最终回答"}""")+end)
                .throttleBody(first.toByteArray().size.toLong(),800,TimeUnit.MILLISECONDS))
            val ready=CompletableDeferred<Unit>(); val events=mutableListOf<ModelEvent>(); val trace=ReasoningTrace()
            val job=launch { client().generate(profile(server),JSONArray()).collect { event ->
                events+=event; if(event is ModelEvent.Thinking) { trace.append(event.text); ready.complete(Unit) }
            } }
            withTimeout(5000) { ready.await() }
            assertTrue(job.isActive); assertFalse(events.any { it is ModelEvent.Delta || it is ModelEvent.Completed })
            job.cancelAndJoin(); trace.finish("stopped")
            assertEquals("先核对资料",trace.snapshot().text); assertEquals("stopped",trace.snapshot().state)
            assertEquals(1,server.requestCount)
        } finally { server.shutdown() }
    }

    @Test fun nonStreamingResponseSeparatesReadableReasoningFromOpaqueMetadata()=runBlocking {
        val server=MockWebServer(); server.start()
        try {
            server.enqueue(MockResponse().setHeader("Content-Type","application/json").setBody("""{"choices":[{"message":{"role":"assistant","reasoning_content":"核对完成","encrypted_content":"opaque-private","content":"答案"},"finish_reason":"stop"}]}"""))
            val events=client().generate(profile(server),JSONArray(),forceStream=false).toList()
            assertEquals("核对完成",events.filterIsInstance<ModelEvent.Thinking>().single().text)
            assertEquals("答案",events.filterIsInstance<ModelEvent.Delta>().single().text)
            assertEquals("opaque-private",events.filterIsInstance<ModelEvent.Completed>().single().message.getString("encrypted_content"))
        } finally { server.shutdown() }
    }

    @Test fun interruptedAndFilteredStreamsKeepDeltasButNeverReportSuccess()=runBlocking {
        val server=MockWebServer(); server.start()
        try {
            for(tail in listOf("", chunk("{}","length"),chunk("{}","content_filter"),chunk("{}","insufficient_system_resource"),"data: {\"error\":{\"message\":\"private diagnostic\"}}\n\n")) {
                server.enqueue(MockResponse().setHeader("Content-Type","text/event-stream").setBody(chunk("""{"content":"已收到"}""")+tail))
                val events=mutableListOf<ModelEvent>()
                val error=runCatching { client().generate(profile(server),JSONArray()).collect { events+=it } }.exceptionOrNull()
                assertNotNull(error); assertFalse(error!!.message.orEmpty().contains("private diagnostic"))
                assertEquals("已收到",events.filterIsInstance<ModelEvent.Delta>().single().text)
                assertFalse(events.any { it is ModelEvent.Completed })
            }
        } finally { server.shutdown() }
    }

    @Test fun cancellationStopsHttpWithoutAnotherRequest()=runBlocking {
        val server=MockWebServer(); server.start()
        try {
            val first=chunk("""{"content":"部分回答"}""")
            server.enqueue(MockResponse().setHeader("Content-Type","text/event-stream").setBody(first+end)
                .throttleBody(first.toByteArray().size.toLong(),500,TimeUnit.MILLISECONDS))
            val ready=CompletableDeferred<Unit>(); var completed=false
            val job=launch { client().generate(profile(server),JSONArray()).collect {
                if(it is ModelEvent.Delta) ready.complete(Unit)
                if(it is ModelEvent.Completed) completed=true
            } }
            withTimeout(4000) { ready.await() }; job.cancelAndJoin()
            assertFalse(completed); assertEquals(1,server.requestCount)
        } finally { server.shutdown() }
    }

    @Test fun jsonResponseIsNotSilentlyRetriedOrPretendedToBeStreaming()=runBlocking {
        val server=MockWebServer(); server.start()
        try {
            server.enqueue(MockResponse().setHeader("Content-Type","application/json")
                .setBody("""{"choices":[{"message":{"role":"assistant","content":"whole response"},"finish_reason":"stop"}]}"""))
            val error=runCatching { client().generate(profile(server),JSONArray()).toList() }.exceptionOrNull()
            assertTrue(error?.message.orEmpty().contains("SSE"))
            assertEquals(1,server.requestCount)
        } finally { server.shutdown() }
    }
}
