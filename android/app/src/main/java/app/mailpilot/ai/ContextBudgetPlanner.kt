package app.mailpilot.ai

import app.mailpilot.data.ModelProfile
import app.mailpilot.data.stableId
import org.json.JSONArray
import org.json.JSONObject

/** Local conservative estimates, not a provider tokenizer or billable usage counter. */
object ContextBudgetPlanner {
    const val VERSION=6
    const val TRIGGER_PERCENT=95
    const val TARGET_PERCENT=60
    data class Limits(val context: Int,val input: Int) {
        val trigger get()=input.toLong().times(TRIGGER_PERCENT).div(100).toInt()
        val target get()=input.toLong().times(TARGET_PERCENT).div(100).toInt()
        fun needsCompression(tokens: Int)=tokens>=trigger
    }
    fun limits(p: ModelProfile): Limits {
        val entry=ModelCapabilityResolver.contextEntry(p)
        val context=minOf(p.contextTokens,entry?.context ?: p.contextTokens)
        val thinking=p.thinkingMode!="disabled"
        // Ark max_tokens caps answer only. Keep additional space for thinking; unlike
        // max_completion_tokens, it must not be treated as a combined output cap.
        val reserve=ModelOutputPolicy.reserve(p)+extraThinking(p)
        val providerInput=if(thinking) entry?.thinkingInput else entry?.input
        return Limits(context,minOf(context-reserve,providerInput ?: context).coerceAtLeast(0))
    }
    fun extraThinking(p: ModelProfile)=if(p.thinkingMode!="disabled" && ReasoningOptions.provider(p)=="volcengine" && p.tokenParameter=="max_tokens") minOf(32768,p.contextTokens/8) else 0
    fun estimate(text: String): Int=maxOf(text.length.toLong()*2,text.toByteArray(Charsets.UTF_8).size.toLong()).coerceAtMost(Int.MAX_VALUE.toLong()).toInt()
    fun estimate(messages: JSONArray,tools: JSONArray?=null,profile: ModelProfile?=null,includeUncertainImages: Boolean=false): Int {
        // Count the decoded protocol fields. JSON wire escaping and Base64 bytes
        // are a separate request-body limit, not text presented to the model.
        var total=128L+logical(tools)
        for(i in 0 until messages.length()) {
            val original=messages.getJSONObject(i)
            val message=JSONObject().apply { original.keys().forEach { if(it!="content") put(it,original.opt(it)) } }
            message.put("content",original.opt("content"))
            val content=message.optJSONArray("content")
            if(content!=null) {
                val text=JSONArray()
                for(j in 0 until content.length()) {
                    val part=content.getJSONObject(j)
                    if(part.optString("type")=="image_url") {
                        // Unverified image estimates are diagnostics, not a reason to reject a real request.
                        if(includeUncertainImages || VisionRequestPlanner.reliableImageEstimate(profile)) total+=VisionRequestPlanner.imageTokens(profile,(part as? LocalImagePart)?.source)
                    } else text.put(part)
                }
                message.put("content",text)
            }
            total+=32L+logical(message)
        }
        return total.coerceAtMost(Int.MAX_VALUE.toLong()).toInt()
    }
    private fun logical(value: Any?): Long=when(value) {
        null,JSONObject.NULL -> 0L
        is String -> estimate(value).toLong()
        is JSONObject -> 8L+value.keys().asSequence().sumOf { estimate(it).toLong()+4+logical(value.opt(it)) }
        is JSONArray -> 8L+(0 until value.length()).sumOf { 4L+logical(value.opt(it)) }
        else -> estimate(value.toString()).toLong()
    }
    fun report(p: ModelProfile,messages: JSONArray,tools: JSONArray?=null)=JSONObject()
        .put("estimatedInputTokens",estimate(messages,tools,p)).put("inputBudget",limits(p).input)
        .put("contextTokens",limits(p).context).put("outputReserve",ModelOutputPolicy.reserve(p))
        .put("thinkingReserve",extraThinking(p)).put("triggerTokens",limits(p).trigger)
        .put("targetTokens",limits(p).target).put("imageEstimateReliable",VisionRequestPlanner.reliableImageEstimate(p))
        .put("budgetVersion",VERSION).put("origin","local_preflight")
    fun validate(p: ModelProfile) {
        val maximum=ModelCapabilityResolver.contextEntry(p)?.output ?: 32768
        require(p.contextTokens in 4096..1048576 && (p.outputTokens==ModelOutputPolicy.AUTO || p.outputTokens in 128..maximum)) { "请检查上下文和输出长度；当前接口的自定义输出上限为 $maximum Token" }
        require(limits(p).input>=512) { "当前输入与输出预算不可用，请调整模型配置" }
    }
    fun requireFits(p: ModelProfile,messages: JSONArray,tools: JSONArray?=null) {
        val tokens=estimate(messages,tools,p); val limits=limits(p)
        if(tokens>limits.input) throw ModelFailure(VisionRequestPlanner.choice(FailureInfo("context_limit","本轮必需内容超过可用输入预算，问题与已处理资料已保留；请查看预算并调整资料。","budget",p.model,
            report(p,messages,tools)),VisionRequestPlanner.imageCount(messages)))
    }
    fun identity(p: ModelProfile)=stableId("$VERSION|${ModelCapabilityResolver.identity(p)}|${p.contextTokens}|${p.outputTokens}|${p.tokenParameter}|${p.thinkingMode}|${p.reasoningEffort}|${p.thinkingBudget}|${limits(p)}")
    /** Splits at Unicode boundaries without dropping a character. */
    fun chunks(text: String,budget: Int): List<String> {
        require(budget>=4)
        val result=mutableListOf<String>(); var start=0; var used=0; var index=0
        while(index<text.length) {
            val size=Character.charCount(text.codePointAt(index)); val cost=estimate(text.substring(index,index+size))
            if(used+cost>budget && index>start) { result+=text.substring(start,index); start=index; used=0 }
            used+=cost; index+=size
        }
        if(start<text.length) result+=text.substring(start)
        return result
    }
}

object ModelContextPolicy {
    fun mode(p: ModelProfile,saved: String?=null)=saved?.takeIf { it in setOf("auto","custom") }
        ?: if(p.contextTokens==32768 && ModelCapabilityResolver.contextEntry(p)!=null) "auto" else "custom"
    fun resolve(p: ModelProfile,saved: String?=null)=if(mode(p,saved)=="auto") p.copy(contextTokens=ModelCapabilityResolver.contextEntry(p)?.context ?: p.contextTokens) else p
}
