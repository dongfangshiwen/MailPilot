package app.mailpilot

import app.mailpilot.services.*
import kotlinx.coroutines.*
import okhttp3.*
import okhttp3.mockwebserver.*
import org.junit.*
import org.junit.Assert.*
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk=[28],application=android.app.Application::class)
class WebReader38Test {
    private lateinit var server: MockWebServer
    private lateinit var client: OkHttpClient
    @Before fun before() {
        server=MockWebServer(); server.start()
        client=OkHttpClient.Builder().followRedirects(false).addInterceptor { chain ->
            chain.proceed(chain.request().newBuilder().url(server.url(chain.request().url.encodedPath)).build())
        }.build()
    }
    @After fun after() { server.shutdown() }
    @Test fun htmlShellUsesFinalAddressAndOnlyOneRender()=runBlocking {
        server.enqueue(MockResponse().setResponseCode(302).setHeader("Location","https://example.org/app?record=opaque#/view"))
        server.enqueue(MockResponse().setHeader("Content-Type","text/html").setBody("<div id=app></div><script src='/app.js'></script>"))
        var renders=0
        val reader=PublicWebReader(client,WebPageRenderer { doc ->
            renders++; assertEquals("/view",doc.url.fragment); assertEquals("record=opaque",doc.url.query)
            WebPage("A rendered record.","complete",true)
        })
        assertTrue(reader.read("https://example.org/link").rendered); assertEquals(1,renders)
        repeat(2) {
            val req=server.takeRequest(); assertTrue(req.getHeader("User-Agent")!!.contains("MailPilot"))
            assertTrue(req.getHeader("Accept")!!.contains("application/xhtml+xml")); assertNull(req.getHeader("Authorization")); assertNull(req.getHeader("Cookie"))
        }
    }
    @Test fun denialsAndStaticDocumentsDoNotRenderOrRetry()=runBlocking {
        var renders=0; val reader=PublicWebReader(client,WebPageRenderer { renders++; error("unexpected") })
        for(code in listOf(401,403,406,429)) {
            server.enqueue(MockResponse().setResponseCode(code)); assertEquals("http_$code",reader.read("https://example.org").status)
        }
        server.enqueue(MockResponse().setHeader("Content-Type","text/html").setBody("<main>"+"Real document. ".repeat(10)+"</main>"))
        assertEquals("complete",reader.read("https://example.org").status); assertEquals(0,renders); assertEquals(5,server.requestCount)
    }
    @Test fun charsetIsDetectedFromDocumentWhenHttpDoesNotDeclareIt()=runBlocking {
        val content="<meta charset=gb18030><main>"+"中文页面信息。".repeat(20)+"</main>"
        server.enqueue(MockResponse().setHeader("Content-Type","text/html").setBody(okio.Buffer().write(content.toByteArray(charset("GB18030")))))
        assertTrue(PublicWebReader(client).read("https://example.org").text.contains("中文页面信息"))
    }
    @Test fun renderTransportCannotExpandOriginsSendCredentialsOrSubmit() {
        val doc=WebDocument(PublicWebReader.endpoint("https://example.org/view?token=secret"),"<script src='https://cdn.example.org/static.js'></script>")
        val transport=WebRenderTransport(doc,client)
        try {
            assertNull(transport.load("https://example.org/submit","POST")); assertEquals("interaction_required",transport.failureStatus)
            assertNull(transport.load("http://127.0.0.1/","GET")); assertNull(transport.load("file:///data/local/test","GET"))
            assertNull(transport.load("https://evil.example.org/pixel","GET")); assertEquals(0,server.requestCount)
            server.enqueue(MockResponse().setHeader("Content-Type","application/javascript").setBody("window.ready=true"))
            assertNotNull(transport.load("https://cdn.example.org/static.js","GET"))
            val req=server.takeRequest(); assertNull(req.getHeader("Referer")); assertNull(req.getHeader("Cookie")); assertNull(req.getHeader("Authorization"))
            assertNotNull(transport.load("https://cdn.example.org/static.js","GET")); assertEquals(1,server.requestCount)
            server.enqueue(MockResponse().setResponseCode(302).setHeader("Location","https://evil.example.org/get"))
            assertNull(transport.load("https://example.org/next","GET")); assertEquals(2,server.requestCount)
        } finally { transport.close() }
        assertNull(transport.load("https://example.org/again","GET"))
    }
    @Test fun nonGetMethodsNeverOpenAConnection() {
        val transport=WebRenderTransport(WebDocument(PublicWebReader.endpoint("https://example.org/app"),""),client)
        try {
            for(method in listOf("POST","PUT","PATCH","DELETE","OPTIONS","HEAD")) assertNull(transport.load("https://example.org/record/cancel",method))
            assertEquals(0,server.requestCount); assertEquals("interaction_required",transport.failureStatus)
        } finally { transport.close() }
    }
}
