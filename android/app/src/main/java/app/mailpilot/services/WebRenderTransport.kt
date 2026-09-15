package app.mailpilot.services

import okhttp3.*
import java.io.ByteArrayOutputStream
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicReference

/** Isolated GET-only transport. A page cannot grant itself write permissions. */
internal class WebRenderTransport(private val document: WebDocument,private val http: OkHttpClient=PublicWebReader.defaultClient()) {
    data class Resource(val bytes: ByteArray,val type: String,val encoding: String)
    private val calls=ConcurrentHashMap.newKeySet<Call>()
    private val closed=AtomicBoolean()
    private val requests=AtomicInteger()
    private val budget=WebBodyBudget(MAX_TOTAL_BYTES)
    private val cached=ConcurrentHashMap<String,Resource>()
    private val failure=AtomicReference("")
    private val cause=AtomicReference("")
    val failureStatus get()=failure.get()
    val failureCause get()=cause.get()
    val downloadedBytes get()=budget.used
    val idle get()=calls.isEmpty()
    private val scriptUrls=org.jsoup.Jsoup.parse(document.html,document.url.toString()).select("script[src]")
        .mapNotNull { runCatching { PublicWebReader.endpoint(it.absUrl("src")).toString() }.getOrNull() }.toSet()
    fun rejectInteraction() { failure.set("interaction_required"); cause.set("unsupported_method") }
    private fun fail(status: String,reason: String=status) { if(failure.compareAndSet("",status)) cause.compareAndSet("",reason) }
    private fun limit(except: Call?=null) { fail("resource_limit"); calls.filter { it!==except }.forEach { it.cancel() } }

    fun load(raw: String,method: String): Resource? {
        if(closed.get()) return null
        if(method!="GET") { rejectInteraction(); return null }
        var call: Call?=null
        try {
            var target=PublicWebReader.endpoint(raw)
            val sameOrigin=target.scheme==document.url.scheme && target.host==document.url.host && target.port==document.url.port
            if(!sameOrigin && target.toString() !in scriptUrls) { fail("resource_failed","origin_scope"); return null }
            val key=target.newBuilder().fragment(null).build().toString()
            cached[key]?.let { return it }
            repeat(4) { hop ->
                if(closed.get()) return null
                if(budget.exhausted || requests.incrementAndGet()>MAX_REQUESTS) { limit(); return null }
                val request=Request.Builder().url(target).header("User-Agent",PublicWebReader.USER_AGENT)
                    .header("Accept","*/*").header("Accept-Language","zh-CN,zh;q=0.9,en;q=0.5").build()
                val current=http.newCall(request); call=current; calls+=current
                if(closed.get()) { current.cancel(); return null }
                try { current.execute().use { response ->
                    if(response.code in setOf(301,302,303,307,308)) {
                        if(hop==3) { fail("resource_failed","redirect_limit"); return null }
                        val next=PublicWebReader.endpoint(target.resolve(response.header("Location").orEmpty()).toString())
                        if(next.scheme!=target.scheme || next.host!=target.host || next.port!=target.port) { fail("resource_failed","redirect_scope"); return null }
                        target=next
                    } else {
                        if(!response.isSuccessful) { fail("resource_failed","http_${response.code}"); return null }
                        val body=response.body ?: run { fail("resource_failed"); return null }
                        val media=body.contentType()
                        val type=media?.let { "${it.type}/${it.subtype}" }.orEmpty()
                        if(type !in TYPES) { fail("resource_failed","unsupported_type"); return null }
                        val declared=body.contentLength()
                        if(declared>PublicWebReader.MAX_BYTES) { fail("resource_limit"); return null }
                        val output=ByteArrayOutputStream()
                        val buffer=ByteArray(8192)
                        val input=body.byteStream()
                        while(true) {
                            if(closed.get()) return null
                            if(declared>=0 && output.size().toLong()==declared) break
                            val localRemaining=PublicWebReader.MAX_BYTES-output.size()
                            if(localRemaining==0) { fail("resource_limit"); return null }
                            val allowance=budget.reserve(minOf(buffer.size,localRemaining))
                            if(allowance==0) { if(!closed.get()) limit(current); return null }
                            var count=0
                            val read=try { input.read(buffer,0,allowance).also { count=maxOf(0,it) } }
                                finally { budget.finish(allowance,count) }
                            if(budget.exhausted && calls.any { it!==current }) limit(current)
                            if(read<0) break
                            output.write(buffer,0,read)
                        }
                        if(declared>=0 && output.size().toLong()!=declared) { fail("resource_failed"); return null }
                        if(closed.get()) return null
                        return Resource(output.toByteArray(),type,media?.charset()?.name() ?: "UTF-8").also { cached[key]=it }
                    }
                } } finally { calls-=current; call=null }
            }
        } catch(e: Exception) { if(!closed.get()) fail("resource_failed",e.javaClass.simpleName) }
        finally { call?.let { calls-=it; it.cancel() } }
        return null
    }
    fun close() { closed.set(true); budget.close(); calls.forEach { it.cancel() }; cached.clear() }
    companion object {
        const val MAX_REQUESTS=48
        const val MAX_TOTAL_BYTES=12*1024*1024
        private val TYPES=setOf("text/html","application/xhtml+xml","text/plain","text/css","application/json","application/javascript","text/javascript","application/x-javascript")
    }
}
