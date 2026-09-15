package app.mailpilot

import app.mailpilot.services.*
import kotlinx.coroutines.*
import okhttp3.*
import okhttp3.mockwebserver.*
import okio.Buffer
import okio.GzipSink
import okio.buffer
import org.junit.*
import org.junit.Assert.*
import java.util.concurrent.TimeUnit

class WebReader34Test {
    private lateinit var server: MockWebServer
    private lateinit var reader: PublicWebReader
    @Before fun setup() {
        server=MockWebServer(); server.start()
        // Test-only transport routing. Production uses the validated DNS client.
        reader=PublicWebReader(OkHttpClient.Builder().followRedirects(false).followSslRedirects(false)
            .addInterceptor { chain -> chain.proceed(chain.request().newBuilder().url(server.url(chain.request().url.encodedPath)).build()) }.build())
    }
    @After fun close() { server.shutdown() }
    @Test fun readsHtmlFollowsBoundedRedirectsWithoutCredentials()=runBlocking {
        server.enqueue(MockResponse().setResponseCode(302).setHeader("Location","https://example.org/page"))
        server.enqueue(MockResponse().setHeader("Content-Type","text/html").setBody("<main>"+"Verified fact. ".repeat(20)+"</main>"))
        assertEquals("complete",reader.read("https://example.org/start").status)
        repeat(2) { val req=server.takeRequest(); assertNull(req.getHeader("Authorization")); assertNull(req.getHeader("Cookie")) }
    }
    @Test fun privateRedirectNeverIssuesAnotherRequest()=runBlocking {
        server.enqueue(MockResponse().setResponseCode(302).setHeader("Location","http://127.0.0.1/"))
        assertTrue(runCatching { reader.read("https://example.org/") }.isFailure); assertEquals(1,server.requestCount)
    }
    @Test fun redirectLoopIsBounded()=runBlocking {
        repeat(4) { server.enqueue(MockResponse().setResponseCode(302).setHeader("Location","https://example.org/next")) }
        assertTrue(runCatching { reader.read("https://example.org/") }.isFailure); assertEquals(4,server.requestCount)
    }
    @Test fun decompressedSizeLimitAndUnsupportedBodies()=runBlocking {
        val data=Buffer(); GzipSink(data).buffer().use { it.writeUtf8("x".repeat(PublicWebReader.MAX_BYTES+1)) }
        server.enqueue(MockResponse().setHeader("Content-Type","text/plain").setHeader("Content-Encoding","gzip").setBody(data))
        assertEquals("too_large",reader.read("https://example.org/").status)
        server.enqueue(MockResponse().setHeader("Content-Type","application/pdf").setBody("%PDF"))
        assertEquals("unsupported_type",reader.read("https://example.org/").status)
    }
    @Test fun cancelClosesPendingConnectionPromptly()=runBlocking {
        server.enqueue(MockResponse().setSocketPolicy(SocketPolicy.NO_RESPONSE))
        val job=async { reader.read("https://example.org/") }
        withContext(Dispatchers.IO) { assertNotNull(server.takeRequest(3,TimeUnit.SECONDS)) }
        withTimeout(2000) { job.cancelAndJoin() }
    }
}
