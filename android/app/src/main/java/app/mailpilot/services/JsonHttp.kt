package app.mailpilot.services

import kotlinx.coroutines.suspendCancellableCoroutine
import okhttp3.*
import okhttp3.HttpUrl.Companion.toHttpUrlOrNull
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.io.IOException
import java.util.concurrent.TimeUnit
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

class JsonHttp(private val http: OkHttpClient=OkHttpClient.Builder().connectTimeout(20,TimeUnit.SECONDS).readTimeout(90,TimeUnit.SECONDS).callTimeout(120,TimeUnit.SECONDS).followRedirects(false).followSslRedirects(false).build(),private val allowHttpForTests: Boolean=false) {
    suspend fun post(url: String,key: String,body: JSONObject): JSONObject = suspendCancellableCoroutine { cont ->
        val endpoint=url.toHttpUrlOrNull()
        if(endpoint==null || (!endpoint.isHttps && !allowHttpForTests) || endpoint.username.isNotEmpty() || endpoint.password.isNotEmpty() || endpoint.fragment!=null || endpoint.query!=null) {
            cont.resumeWithException(IllegalArgumentException("请输入不含账号、查询参数的 HTTPS 接口地址")); return@suspendCancellableCoroutine
        }
        val call=http.newCall(Request.Builder().url(endpoint).header("Authorization","Bearer $key").post(body.toString().toRequestBody("application/json".toMediaType())).build())
        cont.invokeOnCancellation { call.cancel() }
        call.enqueue(object: Callback {
            override fun onFailure(call: Call,e: IOException) { if(cont.isActive) cont.resumeWithException(IllegalStateException("服务连接失败，请检查网络或接口地址")) }
            override fun onResponse(call: Call,response: Response) {
                try {
                    val value=response.use { r ->
                        require(r.isSuccessful) { when(r.code) { 401,403 -> "服务认证失败，请检查密钥和权限"; 429 -> "服务限流，请稍后重试或检查额度"; else -> "服务请求失败（${r.code}），请检查配置" } }
                        val source=requireNotNull(r.body).source(); source.request(4L*1024*1024+1)
                        require(source.buffer.size<=4L*1024*1024) { "服务响应超过大小限制" }
                        JSONObject(source.readUtf8())
                    }
                    if(cont.isActive) cont.resume(value)
                } catch(e: Exception) { if(cont.isActive) cont.resumeWithException(e) }
            }
        })
    }
}
