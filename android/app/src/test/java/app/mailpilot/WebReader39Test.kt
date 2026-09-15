package app.mailpilot

import app.mailpilot.services.*
import kotlinx.coroutines.*
import okhttp3.*
import okhttp3.mockwebserver.*
import okio.*
import org.junit.*
import org.junit.Assert.*
import java.util.concurrent.*
import java.util.concurrent.atomic.AtomicInteger

class WebReader39Test {
    private lateinit var server: MockWebServer
    private lateinit var client: OkHttpClient
    @Before fun setup() {
        server=MockWebServer(); server.start()
        client=OkHttpClient.Builder().followRedirects(false).addInterceptor { chain -> chain.proceed(chain.request().newBuilder().url(server.url(chain.request().url.encodedPath)).build()) }.build()
    }
    @After fun close() { server.shutdown() }
    private fun transport(http: OkHttpClient=client)=WebRenderTransport(WebDocument(PublicWebReader.endpoint("https://example.org/page"),""),http)
    @Test fun aggregateBudgetStopsBeforeOpeningMoreConnections() {
        val t=transport()
        try {
            repeat(8) { i ->
                server.enqueue(MockResponse().setHeader("Content-Type","text/plain").setBody("x".repeat(PublicWebReader.MAX_BYTES)))
                val page=t.load("https://example.org/$i","GET")
                if(i<6) assertNotNull(page) else assertNull(page)
            }
            assertEquals(6,server.requestCount); assertEquals(WebRenderTransport.MAX_TOTAL_BYTES,t.downloadedBytes)
            assertNotNull(t.load("https://example.org/0","GET")); assertEquals(6,server.requestCount)
        } finally { t.close() }
    }
    @Test fun oversizedGzipAndConcurrentReadersShareActualDecodedBudget()=runBlocking {
        val connections=AtomicInteger()
        val t=transport(client.newBuilder().addInterceptor { chain -> connections.incrementAndGet(); chain.proceed(chain.request()) }.build())
        try {
            repeat(8) {
                val data=Buffer(); GzipSink(data).buffer().use { it.writeUtf8("x".repeat(PublicWebReader.MAX_BYTES+10000)) }
                server.enqueue(MockResponse().setHeader("Content-Type","text/plain").setHeader("Content-Encoding","gzip").setBody(data))
            }
            withTimeout(10000) { (0..7).map { i -> async(Dispatchers.IO) { t.load("https://example.org/$i","GET") } }.awaitAll() }
            assertTrue(t.downloadedBytes<=WebRenderTransport.MAX_TOTAL_BYTES)
            assertEquals("resource_limit",t.failureStatus)
            // Canceled requests may reach MockWebServer after the client completed.
            // Count at the client boundary to test whether this new load connected.
            val count=connections.get(); assertNull(t.load("https://example.org/later","GET")); assertEquals(count,connections.get())
        } finally { t.close() }
    }
    @Test fun malformedResponseMimeAndInvalidAddressReturnFailureWithoutThrowing() {
        val t=transport()
        try {
            server.enqueue(MockResponse().setHeader("Content-Type","application/json; broken").setBody("{}"))
            assertNull(t.load("https://example.org/page","GET")); assertEquals("resource_failed",t.failureStatus)
            assertNull(t.load("not a url","GET")); assertEquals(1,server.requestCount)
        } finally { t.close() }
    }
    @Test fun longLoadingShellIsRenderedAndShortStaticFactsAreComplete()=runBlocking {
        server.enqueue(MockResponse().setHeader("Content-Type","text/html").setBody("<main aria-busy=true>"+"Loading record. ".repeat(20)+"</main><script src='/record.js'></script>"))
        var renders=0
        val page=PublicWebReader(client,WebPageRenderer { renders++; WebPage("Verified fact","complete",true) }).read("https://example.org/page")
        assertEquals(1,renders); assertTrue(page.rendered); assertEquals("Verified fact",page.text)
        assertEquals("complete",PublicWebReader.extract("<main>金额 500 元。</main>","text/html").status)
        assertEquals("limited_content",PublicWebReader.extract("<button>"+"Print ".repeat(40)+"</button>","text/html").status)
        assertEquals("complete",PublicWebReader.extract("<main>fact</main><script type='application/ld+json'>{}</script>","text/html").status)
    }
    @Test fun canceledBudgetWakesWaitingReadersAndRefundsUnusedReservations() {
        val budget=WebBodyBudget(10); val pool=Executors.newSingleThreadExecutor()
        try {
            assertEquals(10,budget.reserve(20))
            val pending=pool.submit<Int> { budget.reserve(10) }
            budget.finish(10,4); assertEquals(6,pending.get(2,TimeUnit.SECONDS)); assertEquals(4,budget.used)
            val stopped=pool.submit<Int> { budget.reserve(10) }
            budget.close(); assertEquals(0,stopped.get(2,TimeUnit.SECONDS)); budget.finish(6,0)
        } finally { pool.shutdownNow() }
    }
    @Test fun cancelTransportClosesPendingBody()=runBlocking {
        val t=transport()
        try {
            server.enqueue(MockResponse().setSocketPolicy(SocketPolicy.NO_RESPONSE))
            val job=async(Dispatchers.IO) { t.load("https://example.org/hang","GET") }
            assertNotNull(withContext(Dispatchers.IO) { server.takeRequest(3,TimeUnit.SECONDS) })
            t.close(); withTimeout(2000) { assertNull(job.await()) }
        } finally { t.close() }
    }
}
