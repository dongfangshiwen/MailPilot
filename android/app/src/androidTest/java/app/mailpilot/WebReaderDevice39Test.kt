package app.mailpilot

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import app.mailpilot.services.*
import kotlinx.coroutines.*
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.ResponseBody.Companion.toResponseBody
import org.json.*
import org.junit.*
import org.junit.Assert.*
import org.junit.runner.RunWith
import java.io.File

@RunWith(AndroidJUnit4::class)
class WebReaderDevice39Test {
    @Test fun getDataCompletesAndEverySubmissionStaysLocal()=runBlocking {
        val requests=java.util.concurrent.atomic.AtomicInteger()
        val context=InstrumentationRegistry.getInstrumentation().targetContext
        val http=OkHttpClient.Builder().followRedirects(false).addInterceptor { chain ->
            requests.incrementAndGet(); assertEquals("GET",chain.request().method)
            assertNull(chain.request().header("Cookie")); assertNull(chain.request().header("Authorization"))
            Response.Builder().request(chain.request()).protocol(Protocol.HTTP_1_1).code(200).message("OK")
                .body(JSONObject().put("text","Verified amount 500.").toString().toResponseBody("application/json; charset=utf-8".toMediaType())).build()
        }.build()
        val renderer=AndroidWebRenderer(context) { WebRenderTransport(it,http) }
        val page=renderer.render(WebDocument(PublicWebReader.endpoint("https://example.org/app"),"<main id=app></main><script>fetch('/record').then(r=>r.json()).then(d=>document.getElementById('app').textContent=d.text)</script>"))
        assertEquals("complete",page.status); assertTrue(page.text.contains("500")); assertEquals(1,requests.get())
        val scripts=listOf(
            "fetch('/record/cancel',{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'})",
            "fetch('/record/cancel',{method:'POST',headers:{'Content-Type':'application/json; broken'},body:'{}'})",
            "fetch('/record/cancel',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:'action=cancel'})",
            "var x=new XMLHttpRequest();x.open('POST','/record/cancel');x.setRequestHeader('Content-Type','application/json');x.send('{}');"
        )
        for(script in scripts) {
            val blocked=renderer.render(WebDocument(PublicWebReader.endpoint("https://example.org/app"),"<main id=app>Reference only</main><script>$script</script>"))
            assertEquals("interaction_required",blocked.status); assertEquals(1,requests.get())
        }
        val limited=renderer.render(WebDocument(PublicWebReader.endpoint("https://example.org/app"),"<button>Download</button><button>Print</button>"))
        assertEquals("limited_content",limited.status)
    }
    @Test fun pendingDataAndBusyStateDoNotCompleteEarlyAndFailuresStayPartial()=runBlocking {
        val context=InstrumentationRegistry.getInstrumentation().targetContext
        val http=OkHttpClient.Builder().addInterceptor { chain ->
            if(chain.request().url.encodedPath=="/slow") Thread.sleep(2500)
            val code=if(chain.request().url.encodedPath=="/failed") 503 else 200
            Response.Builder().request(chain.request()).protocol(Protocol.HTTP_1_1).code(code).message("fixture")
                .body("actual short record".toResponseBody("text/plain".toMediaType())).build()
        }.build()
        val renderer=AndroidWebRenderer(context) { WebRenderTransport(it,http) }
        val shell="<main id=app aria-busy=true>"+"Loading reference. ".repeat(20)+"</main>"
        val start=System.nanoTime()
        val page=renderer.render(WebDocument(PublicWebReader.endpoint("https://example.org/app"),shell+"<script>fetch('/slow').then(r=>r.text()).then(d=>{app.textContent=d;app.setAttribute('aria-busy','false')})</script>"))
        assertEquals("complete",page.status); assertEquals("actual short record",page.text); assertTrue((System.nanoTime()-start)/1000000>=2500)
        val failed=renderer.render(WebDocument(PublicWebReader.endpoint("https://example.org/app"),shell+"<script>fetch('/failed').then(()=>app.setAttribute('aria-busy','false'))</script>"))
        assertEquals("resource_failed",failed.status); assertTrue(failed.text.contains("Loading reference"))
        val unchanged=renderer.render(WebDocument(PublicWebReader.endpoint("https://example.org/app"),"<main>"+"Pending record. ".repeat(20)+"</main><script>window.ready=true;</script>"))
        assertEquals("limited_content",unchanged.status)
        val formatted=renderer.render(WebDocument(PublicWebReader.endpoint("https://example.org/app"),"<header>Navigation</header><div><p>Pending</p><p>record</p></div><script>window.ready=true;</script>"))
        assertEquals("limited_content",formatted.status)
    }
    @Test fun publicAndUserProvidedPageMetadataOnly()=runBlocking {
        Assume.assumeTrue(InstrumentationRegistry.getArguments().getString("realWeb")=="true")
        val context=InstrumentationRegistry.getInstrumentation().targetContext
        val reader=PublicWebReader(AndroidWebRenderer(context))
        val report=JSONArray()
        val privateInput=File(context.getExternalFilesDir(null),"web39-input.txt")
        val urls=listOf("https://www.nuonuo.com/nuonuo/web/aboutone/index/index.html")+
            if(privateInput.isFile) privateInput.readLines().filter { it.startsWith("https://") }.take(1) else emptyList()
        for((index,url) in urls.withIndex()) {
            val start=System.nanoTime()
            val page=reader.read(url)
            val verified=if(index==0) page.text.contains("诺诺") && page.text.length>300 else
                page.text.contains("发票") && page.text.contains("下载")
            report.put(JSONObject().put("case",index).put("status",page.status).put("cause",page.cause).put("characters",page.text.length).put("rendered",page.rendered).put("contentVerified",verified)
                .put("recordDetailsVerified",index==1 && page.text.contains("500")).put("elapsedMs",(System.nanoTime()-start)/1_000_000))
        }
        File(context.getExternalFilesDir(null),"web39-result.json").writeText(report.toString(2))
        val publicStatus=report.getJSONObject(0).getString("status")
        assertTrue(publicStatus in listOf("complete","resource_failed"))
        if(publicStatus=="resource_failed") assertTrue(report.getJSONObject(0).getString("cause").isNotBlank())
        assertTrue(report.getJSONObject(0).getBoolean("contentVerified"))
    }
    @Test fun busyTimeoutStaysPartialAndCancelReleasesRenderer()=runBlocking {
        val context=InstrumentationRegistry.getInstrumentation().targetContext
        val renderer=AndroidWebRenderer(context)
        val doc=WebDocument(PublicWebReader.endpoint("https://example.org/app"),"<main aria-busy=true>"+"Loading record. ".repeat(20)+"</main>")
        val pending=async { renderer.render(doc) }
        delay(600); withTimeout(2500) { pending.cancelAndJoin() }
        val page=renderer.render(doc)
        assertEquals("loading_incomplete",page.status); assertTrue(page.text.contains("Loading record"))
        assertEquals("complete",renderer.render(WebDocument(doc.url,"<main>New readable record.</main>")).status)
    }
}
