package app.mailpilot.ai

import app.mailpilot.data.*
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.security.MessageDigest
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody
import okio.BufferedSink

/** Local files stay as references until OkHttp writes the body, never in a giant JSON string. */
class LocalImagePart(val source: SourceChunk): JSONObject() {
    val mime: String = File(source.imagePath).inputStream().use { input ->
        val h=ByteArray(12); val n=input.read(h)
        when { n>=4 && h[0]==0x89.toByte() && h[1]==0x50.toByte() -> "image/png"; n>=12 && String(h,0,4)=="RIFF" -> "image/webp"; else -> "image/jpeg" }
    }
    val prefix get()="{\"type\":\"image_url\",\"image_url\":{\"url\":\"data:$mime;base64,"
    init { put("type","image_url"); put("image_url",JSONObject().put("url","[local image]")) }
}

fun contentFingerprint(file: File): String {
    val digest=MessageDigest.getInstance("SHA-256")
    file.inputStream().buffered().use { input -> val bytes=ByteArray(32768); while(true) { val n=input.read(bytes); if(n<0) break; digest.update(bytes,0,n) } }
    return digest.digest().joinToString("") { "%02x".format(it) }
}

object VisionRequestPlanner {
    const val VERSION=2
    const val BODY_LIMIT=32L*1024*1024
    const val VERIFIED_AT="2026-09-09"
    data class Limits(val images: Int?,val body: Long,val dataUri: Long?,val source: String)
    data class Plan(val batches: List<List<SourceChunk>>,val reason: String,val requiresChoice: Boolean=false,val reliableEstimate: Boolean=false,val processingMode: String="complete",val limitSource: String="")
    fun reliableImageEstimate(p: ModelProfile?)=p!=null && ModelCapabilityResolver.contextEntry(p)!=null && ModelCapabilityResolver.officialProvider(p) in setOf("aliyun","deepseek")
    fun imageParts(messages: JSONArray): List<JSONObject> = (0 until messages.length()).flatMap { i ->
        messages.optJSONObject(i)?.optJSONArray("content")?.let { a -> (0 until a.length()).mapNotNull { a.optJSONObject(it)?.takeIf { p -> p.optString("type")=="image_url" } } }.orEmpty()
    }
    fun imageCount(messages: JSONArray)=imageParts(messages).size
    fun choice(info: FailureInfo,count: Int): FailureInfo = if(info.action!="multimodal_choice" && count>1 && info.type in setOf("material_limit","context_limit","request_size","image_count_limit"))
        info.copy(action="multimodal_choice",message=info.message+" 可调整资料，或选择分批处理本轮。") else info
    fun validateImages(p: ModelProfile,messages: JSONArray) {
        val parts=imageParts(messages); val caps=limits(p)
        if(parts.size>minOf(20,caps.images ?: 20)) throw ModelFailure(choice(FailureInfo("image_count_limit","本次请求图片数超过允许上限。","materials"),parts.size))
        parts.filterIsInstance<LocalImagePart>().forEach { part ->
            if(caps.dataUri!=null && encodedBytes(part.source)>caps.dataUri) throw ModelFailure(FailureInfo("material_limit","${part.source.title}：单张图片编码超过服务商限制，请调整资料。","materials"))
        }
    }
    fun limits(p: ModelProfile): Limits = when(ModelCapabilityResolver.officialProvider(p)) {
        "aliyun" -> Limits(250,BODY_LIMIT,20L*1024*1024,"https://help.aliyun.com/zh/model-studio/vision")
        "deepseek" -> Limits(600,minOf(BODY_LIMIT,48L*1024*1024),null,"https://api-docs.deepseek.com/zh-cn/guides/vision/")
        else -> Limits(null,BODY_LIMIT,null,"")
    }
    fun imageTokens(p: ModelProfile?,s: SourceChunk?): Int {
        if(p==null || ModelCapabilityResolver.contextEntry(p)==null) return 8192
        return when(ModelCapabilityResolver.officialProvider(p)) {
            "deepseek" -> 384
            "aliyun" -> {
                // Official default max_pixels=2,621,440 for the catalog's Qwen3.5+ / VL models.
                val pixels=if(s!=null && s.imageWidth>0 && s.imageHeight>0) s.imageWidth.toLong()*s.imageHeight else 2621440L
                ((minOf(pixels,2621440L)+1023)/1024+66).toInt()
            }
            else -> 8192 // Unverified provider estimates remain explicitly conservative.
        }
    }
    fun encodedBytes(s: SourceChunk)=((File(s.imagePath).length()+2)/3)*4+128
    fun plan(p: ModelProfile,images: List<SourceChunk>,baseTokens: Int=4096,baseBytes: Long=16384,allowBatch: Boolean=false,forceSplit: Boolean=false): Plan {
        val caps=limits(p); val tokenLimit=ContextBudgetPlanner.limits(p).trigger
        val batches=mutableListOf<List<SourceChunk>>(); var current=mutableListOf<SourceChunk>()
        var tokens=baseTokens; var bytes=baseBytes; val reasons=linkedSetOf<String>()
        for(s in images) {
            val size=encodedBytes(s); val cost=if(reliableImageEstimate(p) || allowBatch) imageTokens(p,s) else 0
            if(caps.dataUri!=null && size>caps.dataUri) throw ModelFailure(FailureInfo("material_limit","${s.title}：编码后图片超过服务商单图限制，请调整资料。","materials"))
            if(size+baseBytes>caps.body || cost+baseTokens>tokenLimit) throw ModelFailure(FailureInfo("material_limit","${s.title}：单张图片与问题超过请求预算，请调整资料或模型上下文。","materials"))
            val reason=when {
                current.size>=(caps.images ?: 20) -> "图片数量限制"
                bytes+size>caps.body -> "请求体大小限制"
                tokens+cost>=tokenLimit -> "模型输入预算"
                else -> ""
            }
            if(current.isNotEmpty() && reason.isNotEmpty()) { batches+=current; current=mutableListOf(); tokens=baseTokens; bytes=baseBytes; reasons+=reason }
            current+=s; tokens+=cost; bytes+=size
        }
        if(current.isNotEmpty()) batches+=current
        if(forceSplit && allowBatch && batches.size==1 && images.size>1) {
            batches.clear(); batches+=images.chunked((images.size+1)/2); reasons+="用户选择分批处理"
        }
        val reason=reasons.joinToString("、")
        return if(!allowBatch && batches.size>1) Plan(listOf(images),reason,true,reliableImageEstimate(p),"user_choice",caps.source)
            else Plan(batches,reason,false,reliableImageEstimate(p),if(allowBatch) "batch" else "complete",caps.source)
    }
    fun message(question: String,images: List<SourceChunk>)=JSONObject().put("role","user").put("content",JSONArray().apply {
        put(JSONObject().put("type","text").put("text",question))
        images.forEach { put(JSONObject().put("type","text").put("text","[${it.id}] ${it.title} · ${it.location}")); put(LocalImagePart(it)) }
    })
}

/** Exact, bounded JSON encoding with incremental base64. Does not close OkHttp's sink. */
class ModelJsonBody(private val payload: JSONObject,private val maxBytes: Long=VisionRequestPlanner.BODY_LIMIT): RequestBody() {
    override fun contentType()="application/json".toMediaType()
    override fun contentLength(): Long = count(payload).also { if(it>maxBytes) throw ModelFailure(FailureInfo("material_limit","编码后的模型请求超过应用 32 MiB 上限，请减少资料。","materials")) }
    override fun writeTo(sink: BufferedSink) { contentLength(); write(payload,sink) }
    private fun scalar(value: Any?)=when(value) { null,JSONObject.NULL -> "null"; is String -> JSONObject.quote(value); else -> value.toString() }
    private fun count(value: Any?): Long = when(value) {
        is LocalImagePart -> value.prefix.length.toLong()+((File(value.source.imagePath).length()+2)/3)*4+3
        is JSONObject -> 2L+value.keys().asSequence().toList().sumOf { JSONObject.quote(it).toByteArray().size+1L+count(value.opt(it)) }+maxOf(0,value.length()-1)
        is JSONArray -> 2L+(0 until value.length()).sumOf { count(value.opt(it)) }+maxOf(0,value.length()-1)
        else -> scalar(value).toByteArray().size.toLong()
    }
    private fun write(value: Any?,sink: BufferedSink) {
        when(value) {
            is LocalImagePart -> {
                sink.writeUtf8(value.prefix)
                // 24 KiB is divisible by 3; only the final block may have padding.
                File(value.source.imagePath).inputStream().buffered().use { input ->
                    val block=ByteArray(24576)
                    while(true) { var used=0; while(used<block.size) { val n=input.read(block,used,block.size-used); if(n<0) break; used+=n }; if(used==0) break
                        sink.writeUtf8(java.util.Base64.getEncoder().encodeToString(if(used==block.size) block else block.copyOf(used))) }
                }
                sink.writeUtf8("\"}}")
            }
            is JSONObject -> { sink.writeUtf8("{"); value.keys().asSequence().toList().forEachIndexed { i,key -> if(i>0) sink.writeUtf8(","); sink.writeUtf8(JSONObject.quote(key)+":"); write(value.opt(key),sink) }; sink.writeUtf8("}") }
            is JSONArray -> { sink.writeUtf8("["); for(i in 0 until value.length()) { if(i>0) sink.writeUtf8(","); write(value.opt(i),sink) }; sink.writeUtf8("]") }
            else -> sink.writeUtf8(scalar(value))
        }
    }
}
