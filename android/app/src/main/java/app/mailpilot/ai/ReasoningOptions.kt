package app.mailpilot.ai

import app.mailpilot.data.ModelProfile
import org.json.JSONObject
import java.net.URI

/** Chat Completions wire parameters. SDK extra_body fields belong at JSON root. */
object ReasoningOptions {
    fun provider(p: ModelProfile): String {
        if(p.provider!="auto") return p.provider
        val host=runCatching { URI(p.baseUrl).host.orEmpty().lowercase() }.getOrDefault("")
        fun domain(name: String)=host==name || host.endsWith(".$name")
        return when {
            domain("deepseek.com") -> "deepseek"
            domain("volces.com") || domain("volcengine.com") -> "volcengine"
            domain("aliyuncs.com") -> "aliyun"
            else -> "compatible"
        }
    }
    fun efforts(p: ModelProfile): Set<String> = when(provider(p)) {
        "deepseek" -> setOf("low","high","max")
        "volcengine" -> setOf("minimal","low","medium","high")
        "aliyun" -> when {
            p.model.lowercase().startsWith("qwen3.8") -> setOf("low","medium","xhigh")
            p.model.lowercase().startsWith("qwen") || p.model.lowercase().startsWith("qwq") -> emptySet()
            else -> setOf("low","high","max")
        }
        else -> setOf("minimal","low","medium","high","xhigh","max")
    }
    fun apply(p: ModelProfile,payload: JSONObject): JSONObject {
        require(p.provider in setOf("auto","compatible","deepseek","volcengine","aliyun")) { "请选择有效的模型服务商" }
        val provider=provider(p)
        require(p.thinkingMode in setOf("default","enabled","disabled") || (provider=="volcengine" && p.thinkingMode=="auto")) { "该服务商不支持此思考模式" }
        require(p.thinkingBudget in 0..262144) { "思考预算需为 0–262144；0 表示服务商默认" }
        if(p.thinkingMode=="disabled") {
            when(provider) {
                "aliyun" -> payload.put("enable_thinking",false)
                "deepseek","volcengine" -> payload.put("thinking",JSONObject().put("type","disabled"))
                else -> payload.put("reasoning_effort","none")
            }
            return payload
        }
        require(p.reasoningEffort.isEmpty() || p.reasoningEffort in efforts(p)) { "当前模型不支持此思考档位，请调整档位或使用服务商默认" }
        require(p.thinkingBudget==0 || provider=="aliyun") { "数值思考预算仅适用于支持该参数的阿里云模型" }
        require(p.thinkingBudget==0 || p.reasoningEffort.isEmpty()) { "思考档位与思考预算不能同时设置，请选择其中一种" }
        require(p.thinkingBudget==0 || p.thinkingBudget<ModelOutputPolicy.ceiling(p)) { "思考预算须小于最大输出长度，请为回答正文预留空间" }
        val mode=if(p.thinkingMode=="default" && (p.reasoningEffort.isNotEmpty() || p.thinkingBudget>0)) "enabled" else p.thinkingMode
        when(provider) {
            "aliyun" -> {
                if(mode=="enabled") payload.put("enable_thinking",true)
                if(p.thinkingBudget>0) payload.put("thinking_budget",p.thinkingBudget)
            }
            "deepseek","volcengine" -> if(mode!="default") payload.put("thinking",JSONObject().put("type",mode))
            else -> if(mode=="enabled" && p.reasoningEffort.isEmpty()) payload.put("reasoning_effort","high")
        }
        if(p.reasoningEffort.isNotEmpty()) payload.put("reasoning_effort",p.reasoningEffort)
        return payload
    }
}
