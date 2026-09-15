package app.mailpilot.ai

import app.mailpilot.data.*
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.channels.trySendBlocking
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.*
import okhttp3.HttpUrl.Companion.toHttpUrlOrNull
import org.json.JSONArray
import org.json.JSONObject
import okio.ForwardingSource
import okio.Buffer
import okio.buffer
import java.io.IOException
import java.util.concurrent.TimeUnit

sealed interface ModelEvent {
    data class Delta(val text: String): ModelEvent
    data class Thinking(val text: String): ModelEvent
    data class Completed(val message: JSONObject): ModelEvent
    data class Diagnostics(val value: JSONObject): ModelEvent
}
interface ModelClient {
    fun generate(profile: ModelProfile, messages: JSONArray, tools: JSONArray? = null, forceStream: Boolean? = null): Flow<ModelEvent>
    suspend fun test(profile: ModelProfile): ModelProfile
    fun generateRequest(profile: ModelProfile,messages: JSONArray,tools: JSONArray?=null,forceStream: Boolean?=null,options: ModelRequestOptions=ModelRequestOptions()): Flow<ModelEvent> = generate(profile,messages,tools,forceStream)
}

fun roleMessage(role: String,text: String)=JSONObject().put("role",role).put("content",text)

class CompatibleModelClient(private val secrets: SecretStore,
    private val http: OkHttpClient = OkHttpClient.Builder().connectTimeout(20,TimeUnit.SECONDS).readTimeout(120,TimeUnit.SECONDS)
        .callTimeout(600,TimeUnit.SECONDS).retryOnConnectionFailure(false).followRedirects(false).followSslRedirects(false).build(),
    private val allowHttpForTests: Boolean = false): ModelClient {
    private fun endpoint(profile: ModelProfile): HttpUrl {
        val base=profile.baseUrl.trim().trimEnd('/').toHttpUrlOrNull() ?: error("模型地址格式无效")
        require(base.username.isEmpty() && base.password.isEmpty() && base.query==null && base.fragment==null) { "模型地址不能包含密码、查询参数或片段" }
        require(base.isHttps || allowHttpForTests) { "模型服务必须使用 HTTPS" }
        return if(base.encodedPath.endsWith("/chat/completions")) base else base.newBuilder().addPathSegments("chat/completions").build()
    }
    override fun generate(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?) = generateRequest(profile,messages,tools,forceStream)
    override fun generateRequest(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?,options: ModelRequestOptions): Flow<ModelEvent> = flow {
        val request=PreparedModelRequest.prepare(profile,messages,tools,options)
        emitAll(generateFrozen(profile,request.messages,request.tools,forceStream,options))
    }
    private fun generateFrozen(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?,options: ModelRequestOptions): Flow<ModelEvent> = callbackFlow {
        require(profile.model.isNotBlank()) { "请填写模型名称" }
        ContextBudgetPlanner.validate(profile)
        VisionRequestPlanner.validateImages(profile,messages)
        val imageCount=VisionRequestPlanner.imageCount(messages)
        require(profile.tokenParameter in listOf("max_tokens","max_completion_tokens"))
        // Capability probes report observations, not a switch that disables live replies.
        val streaming=forceStream ?: true
        val outputTokens=ModelOutputPolicy.requestTokens(profile,messages,tools).let { maximum ->
            options.outputTokenLimit?.let { require(it>0); minOf(it,maximum) } ?: maximum
        }
        val payload=JSONObject().put("model",profile.model).put("messages",messages).put("stream",streaming).put(profile.tokenParameter,outputTokens)
        if(options.structuredDraft && ResponseFormatPolicy.jsonObject(profile)) payload.put("response_format",JSONObject().put("type","json_object"))
        try { ReasoningOptions.apply(profile,payload) } catch(e: IllegalArgumentException) { throw ModelFailure(FailureInfo("thinking",e.message ?: "请检查思考参数","thinking_default"),e) }
        if(tools!=null && tools.length()>0) payload.put("tools",tools).put("tool_choice",if(options.finalAnswer) "none" else "auto")
        val key=secrets.decrypt(profile.apiKeyCipher)
        val builder=Request.Builder().url(endpoint(profile)).header("Content-Type","application/json").header("Accept",if(streaming) "text/event-stream" else "application/json")
        if(key.isNotBlank()) builder.header("Authorization","Bearer $key")
        val body=try { ModelJsonBody(payload,VisionRequestPlanner.limits(profile).body).also { it.contentLength() } }
            catch(e: ModelFailure) { throw ModelFailure(VisionRequestPlanner.choice(e.info,imageCount),e) }
        val attemptId=newId()
        var connectionEstablished=false
        var bodySent=false
        val requestHttp=http.newBuilder().retryOnConnectionFailure(false).eventListener(object: EventListener() {
            override fun connectionAcquired(call: Call,connection: Connection) { connectionEstablished=true }
            override fun requestBodyEnd(call: Call,byteCount: Long) {
                bodySent=true
                trySendBlocking(ModelEvent.Diagnostics(JSONObject().put("requestId",options.requestId).put("attemptId",attemptId)
                    .put("event","request_body_sent").put("stage",options.stage).put("model",profile.model).put("host",endpoint(profile).host)
                    .put("imagesInRequest",imageCount).put("bodyBytes",byteCount))).getOrThrow()
            }
        }).build()
        val call=requestHttp.newCall(builder.post(body).build())
        val started=System.nanoTime(); var firstByteMs: Long?=null; var lastByteMs: Long?=null
        var httpStatus=0; var providerId=""; var finish=""
        fun elapsed()=(System.nanoTime()-started)/1_000_000
        fun diagnostics(cause: String="")=ContextBudgetPlanner.report(profile,messages,tools).put("origin","model_request").put("requestId",options.requestId).put("stage",options.stage)
            .put("attemptId",attemptId).put("bodySent",bodySent).put("imagesInRequest",imageCount).put("bodyBytes",body.contentLength())
            .put("imageEstimateReliable",VisionRequestPlanner.reliableImageEstimate(profile)).put("endpointKind",ModelCapabilityResolver.endpointKind(profile))
            .put("estimatedInputTokens",ContextBudgetPlanner.estimate(messages,tools,profile)).put("conservativeInputTokens",ContextBudgetPlanner.estimate(messages,tools,profile,true))
            .put("outputMode",if(profile.outputTokens==ModelOutputPolicy.AUTO) "auto" else "custom").put("requestedOutputTokens",outputTokens)
            .put("model",profile.model).put("host",endpoint(profile).host).put("elapsedMs",elapsed())
            .put("firstByteMs",firstByteMs ?: JSONObject.NULL).put("lastByteMs",lastByteMs ?: JSONObject.NULL)
            .put("httpStatus",httpStatus).put("providerRequestId",providerId).put("finishReason",finish).put("cause",cause)
        fun failure(e: Exception,connecting: Boolean=false): ModelFailure {
            val info=when {
                e is ModelFailure -> e.info
                call.isCanceled() -> FailureInfo("request_timeout","模型请求已中止或达到总时限，已收到内容保留")
                e is java.net.SocketTimeoutException -> FailureInfo(if(connecting) "connect_timeout" else "read_timeout",if(connecting) "连接模型超时，请检查地址与网络" else "等待模型数据超时，已收到内容保留，请重试")
                e is IOException -> FailureInfo(if(connecting) "connection" else "stream_interrupted",if(connecting) "连接模型失败，请检查地址与网络" else "接收模型数据时连接中断，已收到内容保留，请重试")
                else -> FailureInfo.from(e)
            }
            return ModelFailure(VisionRequestPlanner.choice(info,imageCount).copy(model=profile.model,diagnostics=diagnostics(e.javaClass.simpleName)),e)
        }
        call.enqueue(object: Callback {
            override fun onFailure(call: Call,e: IOException) { close(failure(e,!connectionEstablished)) }
            override fun onResponse(call: Call,response: Response) {
                var accepted=false
                try { response.use { r ->
                    httpStatus=r.code; providerId=(r.header("x-request-id") ?: r.header("x-tt-logid") ?: r.header("request-id") ?: "").take(160)
                    if(!r.isSuccessful) throw ModelFailure(FailureInfo.http(r.code,r.peekBody(16384).string()))
                    val body=r.body ?: error("模型返回空响应")
                    if(streaming) require(r.header("Content-Type","")!!.contains("text/event-stream",ignoreCase=true)) { "服务未返回 SSE 流式响应，请检查兼容接口地址或更换支持流式的模型。本次未自动重试。" }
                    if(!streaming) {
                        val source=body.source(); source.request(8L*1024*1024+1); require(source.buffer.size<=8L*1024*1024) { "模型响应过大" }
                        val json=JSONObject(source.readUtf8()); val choice=json.getJSONArray("choices").getJSONObject(0)
                        if(choice.optString("finish_reason")=="length") error("模型达到输出上限，请增加输出长度或缩小资料范围")
                        val message=choice.getJSONObject("message")
                        val reasoning=message.optString("reasoning_content","").takeUnless { it=="null" }.orEmpty()
                        if(reasoning.isNotEmpty()) trySendBlocking(ModelEvent.Thinking(reasoning)).getOrThrow()
                        val text=message.optString("content","").takeUnless { it=="null" }.orEmpty()
                        if(text.isNotBlank()) trySendBlocking(ModelEvent.Delta(text)).getOrThrow()
                        finish=choice.optString("finish_reason")
                        trySendBlocking(ModelEvent.Diagnostics(diagnostics())).getOrThrow()
                        trySendBlocking(ModelEvent.Completed(message)).getOrThrow(); accepted=true
                    } else {
                        val accumulator=StreamAccumulator()
                        val observed=object: ForwardingSource(body.source()) {
                            override fun read(sink: Buffer,byteCount: Long): Long = super.read(sink,byteCount).also { if(it>0) { lastByteMs=elapsed(); if(firstByteMs==null) firstByteMs=lastByteMs } }
                        }.buffer()
                        SseReader.consume(observed.inputStream().bufferedReader(Charsets.UTF_8)) { event ->
                            if(event=="[DONE]") { accumulator.done=true; false } else {
                                val reasoningLength=accumulator.reasoning.length
                                val delta=accumulator.accept(JSONObject(event))
                                if(accumulator.reasoning.length>reasoningLength) trySendBlocking(ModelEvent.Thinking(accumulator.reasoning.substring(reasoningLength))).getOrThrow()
                                if(delta.isNotEmpty()) trySendBlocking(ModelEvent.Delta(delta)).getOrThrow()
                                finish=accumulator.finishReason
                                !accumulator.finished && !call.isCanceled()
                            }
                        }
                        if(!accumulator.done && !accumulator.finished) throw ModelFailure(FailureInfo("stream_interrupted","模型连接提前结束，回答未完整接收，请重试"))
                        require(!accumulator.truncated) { "模型达到输出上限，请增加输出长度或缩小资料范围" }
                        if(accumulator.filtered) throw ModelFailure(FailureInfo("content_filter","模型服务终止了这次回答，请调整问题或资料范围"))
                        if(accumulator.failed) throw ModelFailure(FailureInfo("provider_terminated","模型服务提前终止了回答，请稍后手动重试"))
                        require(accumulator.content.isNotBlank() || accumulator.message().has("tool_calls")) { "模型未返回回答正文，请检查输出长度或更换模型" }
                        trySendBlocking(ModelEvent.Diagnostics(diagnostics())).getOrThrow()
                        trySendBlocking(ModelEvent.Completed(accumulator.message())).getOrThrow(); accepted=true
                    }
                }; close() } catch(e: Exception) { if(accepted) close() else close(failure(e)) }
            }
        })
        awaitClose { call.cancel() }
    }.buffer(Channel.BUFFERED)

    override suspend fun test(profile: ModelProfile): ModelProfile = withContext(Dispatchers.IO) {
        suspend fun invoke(messages: JSONArray,tools: JSONArray? = null,stream: Boolean=false): JSONObject {
            var result: JSONObject?=null
            generate(profile,messages,tools,stream).collect { if(it is ModelEvent.Completed) result=it.message }
            return requireNotNull(result)
        }
        val diagnostic=JSONObject(); val reports=mutableListOf<String>()
        suspend fun probe(name: String,block: suspend ()->Boolean): Boolean {
            return try {
                val ok=block()
                val note=if(ok) "请求通过" else "接口接受请求，但未取得预期结果；能力仍待确认"
                diagnostic.put(name,JSONObject().put("status",if(ok) "passed" else "unconfirmed").put("detail",note))
                reports+="$name：$note"; ok
            } catch(e: kotlinx.coroutines.CancellationException) { throw e } catch(e: Exception) {
                val failure=FailureInfo.from(e)
                diagnostic.put(name,JSONObject(failure.fields()).put("status","failed"))
                reports+="$name：${failure.message}"; false
            }
        }
        val textOk=probe("文字") { invoke(JSONArray().put(roleMessage("user","请只回复 OK"))).optString("content").let { it.isNotBlank() && it!="null" } }
        val streamOk=probe("流式") { invoke(JSONArray().put(roleMessage("user","请只回复 OK")),stream=true).optString("content").let { it.isNotBlank() && it!="null" } }
        val fn=JSONObject().put("type","function").put("function",JSONObject().put("name","connection_probe").put("description","连接诊断，无副作用").put("parameters",JSONObject().put("type","object").put("properties",JSONObject()).put("additionalProperties",false)))
        val toolsOk=probe("工具") { invoke(JSONArray().put(roleMessage("user","请调用 connection_probe 工具完成诊断。")),JSONArray().put(fn),stream=streamOk).optJSONArray("tool_calls")?.length()?.let { it>0 }==true }
        val visionOk=probe("图片") {
            val bmp=android.graphics.Bitmap.createBitmap(96,64,android.graphics.Bitmap.Config.ARGB_8888)
            val canvas=android.graphics.Canvas(bmp); canvas.drawColor(android.graphics.Color.WHITE)
            val paint=android.graphics.Paint().apply { color=android.graphics.Color.BLUE }
            canvas.drawCircle(24f,32f,16f,paint); paint.color=android.graphics.Color.RED; canvas.drawRect(56f,16f,88f,48f,paint)
            val bytes=java.io.ByteArrayOutputStream().also { bmp.compress(android.graphics.Bitmap.CompressFormat.PNG,100,it); bmp.recycle() }.toByteArray()
            val content=JSONArray().put(JSONObject().put("type","text").put("text","描述图中左右两侧的形状和颜色。"))
                .put(JSONObject().put("type","image_url").put("image_url",JSONObject().put("url","data:image/png;base64,"+java.util.Base64.getEncoder().encodeToString(bytes))))
            val answer=invoke(JSONArray().put(JSONObject().put("role","user").put("content",content)),stream=streamOk).optString("content")
            // Acceptance is a connection observation, not a proof of visual accuracy.
            diagnostic.put("imageObservation",answer.take(800))
            answer.isNotBlank() && answer!="null"
        }
        diagnostic.put("checkedAt",System.currentTimeMillis())
        profile.copy(textVerified=textOk,supportsStreaming=streamOk,supportsTools=toolsOk,supportsVision=visionOk,
            testReport=reports.joinToString("\n")+"\n图片诊断仅验证请求与返回，实际理解以资料问答为准。",diagnosticsJson=diagnostic.toString(),diagnosticIdentity=ModelCapabilityResolver.identity(profile))
    }
}

object SseReader {
    fun consume(reader: java.io.BufferedReader,onEvent: (String)->Boolean) {
        val data=StringBuilder(); var total=0
        fun dispatch(): Boolean { if(data.isEmpty()) return true; val value=data.toString().trimEnd('\n'); data.clear(); return onEvent(value) }
        while(true) { val line=reader.readLine()?.removePrefix("\uFEFF") ?: break; total+=line.length; require(total<=8*1024*1024) { "模型响应过大" }
            if(line.isEmpty()) { if(!dispatch()) return } else if(line.startsWith("data:")) data.append(line.substring(5).removePrefix(" ")).append('\n')
        }
        dispatch()
    }
}

class StreamAccumulator {
    val content=StringBuilder(); val reasoning=StringBuilder(); private val encrypted=StringBuilder()
    private val calls=sortedMapOf<Int,JSONObject>(); var done=false; var finished=false; var truncated=false; var filtered=false; var failed=false; var finishReason=""
    fun accept(json: JSONObject): String {
        if(json.has("error")) throw ModelFailure(FailureInfo.http(json.optJSONObject("error")?.optInt("status",400) ?: 400,json.toString()))
        val choices=json.optJSONArray("choices") ?: return ""; if(choices.length()==0) return ""
        val choice=choices.getJSONObject(0); val finish=choice.optString("finish_reason","")
        if(finish.isNotBlank() && finish!="null") { finishReason=finish; finished=true; truncated=finish=="length"; filtered=finish=="content_filter"; failed=finish !in setOf("stop","tool_calls","length","content_filter") }
        val d=choice.optJSONObject("delta") ?: return ""; val text=d.optString("content","").takeUnless { it=="null" }.orEmpty(); content.append(text)
        reasoning.append(d.optString("reasoning_content","").takeUnless { it=="null" }.orEmpty())
        encrypted.append(d.optString("encrypted_content","").takeUnless { it=="null" }.orEmpty())
        val tools=d.optJSONArray("tool_calls")
        if(tools!=null) for(i in 0 until tools.length()) {
            val t=tools.getJSONObject(i); val index=t.optInt("index",i)
            val c=calls.getOrPut(index) { JSONObject().put("id","").put("type","function").put("function",JSONObject().put("name","").put("arguments","")) }
            if(t.has("id") && !t.isNull("id")) c.put("id",c.getString("id")+t.getString("id"))
            t.optJSONObject("function")?.let { f -> val cf=c.getJSONObject("function"); for(key in listOf("name","arguments")) if(f.has(key) && !f.isNull(key)) cf.put(key,cf.getString(key)+f.getString(key)) }
        }
        return text
    }
    fun message(): JSONObject = roleMessage("assistant",content.toString()).apply {
        if(reasoning.isNotEmpty()) put("reasoning_content",reasoning.toString())
        if(encrypted.isNotEmpty()) put("encrypted_content",encrypted.toString())
        if(calls.isNotEmpty()) put("tool_calls",JSONArray(calls.values.toList()))
    }
}
