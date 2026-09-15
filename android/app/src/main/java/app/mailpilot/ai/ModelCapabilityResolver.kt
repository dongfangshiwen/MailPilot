package app.mailpilot.ai

import app.mailpilot.data.ModelProfile
import app.mailpilot.data.stableId
import java.net.URI

/** Offline declarations. Diagnostics are observations of a connection, never a capability gate. */
object ModelCapabilityResolver {
    const val verifiedAt = "2026-09-09"
    data class Entry(val provider: String, val name: String, val source: String, val context: Int,
        val input: Int=context, val thinkingInput: Int=input, val output: Int=32768, val vision: Boolean=true,
        val outputSource: String=source, val outputVerifiedAt: String=verifiedAt) {
        fun fields()=mapOf("provider" to provider,"model" to name,"vision" to vision,"verifiedAt" to verifiedAt,"source" to source,
            "contextTokens" to context,"maxInputTokens" to input,"maxThinkingInputTokens" to thinkingInput,"maxOutputTokens" to output,
            "outputSource" to outputSource,"outputVerifiedAt" to outputVerifiedAt)
    }
    private const val arkSource="https://docs.volcengine.com/docs/82379/1330310?lang=zh"
    val catalog = listOf(
        Entry("volcengine","doubao-seed-evolving",arkSource,1048576,output=262144),
        Entry("volcengine","doubao-seed-2-1-pro-260628",arkSource,262144,output=262144),
        Entry("volcengine","doubao-seed-2-1-turbo-260628",arkSource,262144,output=262144),
        Entry("volcengine","doubao-seed-2-0-lite-260428",arkSource,262144,229376,output=131072),
        Entry("volcengine","doubao-seed-2-0-mini-260428",arkSource,262144,229376,output=131072)
    ) + listOf("qwen3.8-max","qwen3.7-plus","qwen3.6-plus","qwen3.6-flash","qwen3.5-plus","qwen3.5-flash").map {
        Entry("aliyun",it,"https://help.aliyun.com/zh/model-studio/"+it.replace('.','-'),1000000,991808,983616,
            if(it in setOf("qwen3.8-max","qwen3.7-plus")) 131072 else 65536)
    } + listOf("qwen3-vl-plus","qwen3-vl-flash").map {
        Entry("aliyun",it,"https://help.aliyun.com/zh/model-studio/$it",262144,260096,258048,32768)
    } + listOf("deepseek-v4-flash","deepseek-v4-pro","deepseek-v4-flash-vision-exp").map {
        Entry("deepseek",it,"https://api-docs.deepseek.com/quick_start/pricing/",1000000,output=384000,vision=it.endsWith("vision-exp"),
            outputSource="https://api-docs.deepseek.com/quick_start/agent_integrations/pi_mono/",outputVerifiedAt="2026-09-10")
    }
    fun endpoint(p: ModelProfile)=p.baseUrl.trim().trimEnd('/').removeSuffix("/chat/completions").trimEnd('/')
    fun identity(p: ModelProfile)=stableId(endpoint(p)+"\n"+p.model+"\n"+p.credentialVersion)
    fun diagnosticCurrent(p: ModelProfile)=p.diagnosticIdentity.isNotBlank() && p.diagnosticIdentity==identity(p)
    fun entry(p: ModelProfile)=catalog.firstOrNull { it.provider==ReasoningOptions.provider(p) && it.name==p.model }
    fun vision(p: ModelProfile): String = when {
        entry(p)!=null -> if(entry(p)!!.vision) "supported" else "unsupported"
        diagnosticCurrent(p) && p.supportsVision -> "supported"
        ReasoningOptions.provider(p)=="deepseek" && p.model in setOf("deepseek-chat","deepseek-reasoner","deepseek-v4-flash","deepseek-v4-pro") -> "unsupported"
        else -> "unknown" // Legacy false values explicitly mean unconfirmed.
    }
    fun fields(p: ModelProfile)=mapOf("vision" to vision(p),"source" to (entry(p)?.source ?: if(diagnosticCurrent(p)&&p.supportsVision) "连接诊断" else "能力待确认，可直接尝试"),"verifiedAt" to (entry(p)?.let { verifiedAt } ?: ""),"diagnosticCurrent" to diagnosticCurrent(p),"endpointKind" to endpointKind(p),"contextNote" to if(endpointKind(p)=="ark_plan") "套餐接口的上下文及图片限额暂未核实，保留当前配置；不会套用标准接口额度。" else "",
        "context" to contextEntry(p)?.fields(),"effectiveInputTokens" to ContextBudgetPlanner.limits(p).input)
    fun officialProvider(p: ModelProfile): String? {
        val uri=runCatching { URI(endpoint(p)) }.getOrNull() ?: return null
        if(uri.scheme!="https" || uri.userInfo!=null || uri.query!=null || uri.fragment!=null || uri.port!=-1) return null
        return when {
            uri.host in setOf("ark.cn-beijing.volces.com","ark.cn-shanghai.volces.com") && uri.path=="/api/v3" -> "volcengine"
            uri.host in setOf("dashscope.aliyuncs.com","dashscope-intl.aliyuncs.com","dashscope-us.aliyuncs.com") && uri.path=="/compatible-mode/v1" -> "aliyun"
            uri.host=="api.deepseek.com" && uri.path in setOf("","/v1") -> "deepseek"
            else -> null
        }?.takeIf { it==ReasoningOptions.provider(p) }
    }
    fun contextEntry(p: ModelProfile)=entry(p)?.takeIf { it.provider==officialProvider(p) }
    fun endpointKind(p: ModelProfile): String {
        val u=runCatching { URI(endpoint(p)) }.getOrNull() ?: return "custom"
        if(u.scheme=="https" && u.host=="ark.cn-beijing.volces.com" && u.path=="/api/plan/v3" && u.port==-1 && u.userInfo==null && u.query==null && u.fragment==null) return "ark_plan"
        return officialProvider(p)?.let { if(it=="volcengine") "ark_standard" else it } ?: "custom"
    }
    /** A provider selection alone is not permission to reuse a key on another endpoint. */
    fun defaultHelper(p: ModelProfile): ModelProfile? {
        val uri=runCatching { URI(endpoint(p)) }.getOrNull() ?: return null
        if(uri.scheme!="https" || uri.userInfo!=null || uri.query!=null || uri.fragment!=null || uri.port!=-1) return null
        val name=when {
            uri.host in setOf("ark.cn-beijing.volces.com","ark.cn-shanghai.volces.com") && uri.path=="/api/v3" -> "doubao-seed-2-0-lite-260428"
            uri.host in setOf("dashscope.aliyuncs.com","dashscope-intl.aliyuncs.com","dashscope-us.aliyuncs.com") && uri.path=="/compatible-mode/v1" -> "qwen3-vl-flash"
            uri.host=="api.deepseek.com" && uri.path in setOf("","/v1") -> "deepseek-v4-flash-vision-exp"
            else -> return null
        }
        val helper=p.copy(id=p.id+":vision",label="视觉助手",model=name,outputTokens=ModelOutputPolicy.AUTO,thinkingMode="default",reasoningEffort="",thinkingBudget=0,diagnosticIdentity="",diagnosticsJson="{}")
        return helper.copy(contextTokens=contextEntry(helper)?.context ?: 32768)
    }
}

object VisionRouter {
    fun candidates(main: ModelProfile, helper: ModelProfile?, configured: List<ModelProfile>): List<ModelProfile> {
        val current=main.takeIf { ModelCapabilityResolver.vision(it)!="unsupported" }
        val peers=configured.filter { ModelCapabilityResolver.endpoint(it)==ModelCapabilityResolver.endpoint(main) && ModelCapabilityResolver.vision(it)=="supported" }
        // An explicitly fixed helper takes priority. With auto mode (helper=null), current model is first.
        return (listOfNotNull(helper,current)+peers+listOfNotNull(ModelCapabilityResolver.defaultHelper(main)))
            .distinctBy { ModelCapabilityResolver.endpoint(it)+"/"+it.model }
            .map { it.copy(thinkingMode="default",reasoningEffort="",thinkingBudget=0) }
    }
}
