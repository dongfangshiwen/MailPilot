package app.mailpilot.services

import kotlinx.coroutines.*
import okhttp3.*
import okhttp3.HttpUrl.Companion.toHttpUrlOrNull
import org.jsoup.Jsoup
import java.net.InetAddress
import java.util.concurrent.TimeUnit

data class WebPage(val text: String="",val status: String="unavailable",val rendered: Boolean=false,val cause: String="")
data class WebDocument(val url: HttpUrl,val html: String)
fun interface WebPageRenderer { suspend fun render(document: WebDocument): WebPage }
fun interface WebPageReader { suspend fun read(url: String): WebPage }

/** Separate unauthenticated client: DNS is validated at the actual connection, including redirects. */
class PublicWebReader internal constructor(private val http: OkHttpClient,private val renderer: WebPageRenderer?=null): WebPageReader {
    constructor(renderer: WebPageRenderer?=null): this(defaultClient(),renderer)
    companion object {
        const val MAX_BYTES=2*1024*1024
        const val USER_AGENT="Mozilla/5.0 (Linux; Android 16) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36 MailPilot/1.0"
        const val DOCUMENT_ACCEPT="text/html,application/xhtml+xml,text/plain;q=0.9,*/*;q=0.5"
        fun publicAddress(ip: InetAddress): Boolean {
            if(ip.isAnyLocalAddress || ip.isLoopbackAddress || ip.isLinkLocalAddress || ip.isSiteLocalAddress || ip.isMulticastAddress) return false
            val b=ip.address.map { it.toInt() and 255 }
            if(b.size==4) return !(b[0]==0 || b[0]==10 || b[0]==127 || b[0]>=224 || b[0]==169 && b[1]==254 || b[0]==172 && b[1] in 16..31 || b[0]==192 && b[1]==168 || b[0]==100 && b[1] in 64..127 || b[0]==198 && b[1] in 18..19 || b[0]==192 && b[1]==0 || b[0]==198 && b[1]==51 || b[0]==203 && b[1]==0)
            // Only global unicast; reject mapped/transition, ULA, documentation and special-use ranges.
            return b.size==16 && b[0] in 0x20..0x3f && !(b[0]==0x20 && b[1]==0x01 && (b[2]<2 || b[2]==0x0d && b[3]==0xb8)) && !(b[0]==0x20 && b[1]==0x02)
        }
        fun endpoint(raw: String): HttpUrl {
            val u=raw.toHttpUrlOrNull() ?: error("网页地址无效")
            require(u.username.isEmpty() && u.password.isEmpty() && u.port in setOf(80,443) && u.host!="localhost" && !u.host.endsWith(".local")) { "网页地址不可访问" }
            if(':' in u.host || u.host.matches(Regex("[0-9.]+"))) require(publicAddress(InetAddress.getByName(u.host))) { "网页目标不是公网地址" }
            // OkHttp omits fragments on the wire; keep them for client-side routes.
            return u
        }
        fun extract(content: String,type: String): WebPage {
            if(type=="text/plain") return WebPage(content,"complete")
            if(type !in setOf("text/html","application/xhtml+xml")) return WebPage(status="unsupported_type")
            return WebContentPolicy.analyze(content).page
        }
        internal fun defaultClient()=OkHttpClient.Builder().connectTimeout(10,TimeUnit.SECONDS).readTimeout(20,TimeUnit.SECONDS).callTimeout(30,TimeUnit.SECONDS)
        .followRedirects(false).followSslRedirects(false).proxy(java.net.Proxy.NO_PROXY)
        .dns(object: Dns { override fun lookup(hostname: String)=Dns.SYSTEM.lookup(hostname).also { ips -> require(ips.isNotEmpty() && ips.all(::publicAddress)) { "网页目标不是公网地址" } } }).build()
    }
    override suspend fun read(url: String): WebPage=withTimeout(30000) {
        var target=endpoint(url)
        repeat(4) { hop ->
            val call=http.newCall(Request.Builder().url(target).header("Accept",DOCUMENT_ACCEPT).header("Accept-Language","zh-CN,zh;q=0.9,en;q=0.5").header("User-Agent",USER_AGENT).build())
            val response=kotlinx.coroutines.suspendCancellableCoroutine<Response> { cont ->
                cont.invokeOnCancellation { call.cancel() }
                call.enqueue(object: Callback {
                    override fun onFailure(call: Call,e: java.io.IOException) { if(cont.isActive) cont.resumeWith(Result.failure(e)) }
                    override fun onResponse(call: Call,response: Response) { if(cont.isActive) cont.resume(response) { _,value,_ -> value.close() } else response.close() }
                })
            }
            response.use { r ->
                if(r.code in setOf(301,302,303,307,308)) {
                    require(hop<3) { "网页重定向过多" }
                    val next=endpoint(target.resolve(r.header("Location").orEmpty())?.toString().orEmpty())
                    require(!target.isHttps || next.isHttps) { "网页重定向降低安全级别" }; target=next
                } else {
                    if(!r.isSuccessful) return@withTimeout WebPage(status="http_${r.code}")
                    val body=r.body ?: return@withTimeout WebPage(status="empty")
                    val type=body.contentType()?.let { "${it.type}/${it.subtype}" }.orEmpty()
                    if(type !in setOf("text/plain","text/html","application/xhtml+xml")) return@withTimeout WebPage(status="unsupported_type")
                    // Reads on IO; cancellation closes the body rather than waiting on a blocked socket.
                    val bytes=suspendCancellableCoroutine<ByteArray?> { cont ->
                        cont.invokeOnCancellation { call.cancel() }
                        CoroutineScope(cont.context+Dispatchers.IO).launch {
                            try {
                                val data=body.source().apply { request(MAX_BYTES+1L) }.let { s -> if(s.buffer.size>MAX_BYTES) null else s.readByteArray() }
                                if(cont.isActive) cont.resumeWith(Result.success(data))
                            } catch(e: Exception) { if(cont.isActive) cont.resumeWith(Result.failure(e)) }
                        }
                    }
                            ?: return@withTimeout WebPage(status="too_large")
                    val content=if(type=="text/plain") String(bytes,body.contentType()?.charset(Charsets.UTF_8) ?: Charsets.UTF_8)
                        else Jsoup.parse(bytes.inputStream(),body.contentType()?.charset()?.name(),target.toString()).html()
                    val page=extract(content,type)
                    // Only successful HTML shells enter the bounded renderer. Never retry a denial.
                    return@withTimeout if(page.status=="needs_render")
                        renderer?.render(WebDocument(target,content)) ?: page.copy(status="loading_incomplete") else page
                }
            }
        }
        WebPage(status="redirect_limit")
    }
}
