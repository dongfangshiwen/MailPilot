package app.mailpilot.ai

import org.json.JSONObject
import java.io.IOException

data class FailureInfo(val type: String,val message: String,val action: String="retry",val model: String="",val diagnostics: JSONObject=JSONObject()) {
    fun fields()=mapOf("type" to type,"message" to message,"action" to action,"model" to model,"diagnostics" to diagnostics)
    fun json()=JSONObject(fields()).toString()
    companion object {
        fun from(e: Throwable): FailureInfo = when(e) {
            is app.mailpilot.attachments.MaterialFailure -> FailureInfo("materials",e.message.orEmpty(),"materials")
            is ModelFailure -> e.info
            is java.net.SocketTimeoutException -> FailureInfo("read_timeout","等待模型数据超时，已收到内容保留，请重试")
            is IOException -> FailureInfo("stream_interrupted","模型连接中断，已收到内容保留，请重试")
            is WebSearchFailure -> FailureInfo("search",e.message.orEmpty(),"search_config")
            is org.json.JSONException -> FailureInfo("result_format","服务返回格式不完整或不兼容，请重试或检查模型配置")
            else -> when {
                e.message.orEmpty().contains("输出上限") -> FailureInfo("output_limit","模型达到输出上限，请增加最大输出长度或缩小资料范围","model_config")
                e.message.orEmpty().contains("连接中断") -> FailureInfo("network","回答连接中断，已收到内容保留，请重试")
                e.message.orEmpty().contains("未返回") || e.message.orEmpty().contains("空响应") -> FailureInfo("result_format",e.message ?: "服务未返回完整结果")
                else -> FailureInfo("request",e.message ?: "本轮未完成，请重试")
            }
        }
        fun http(status: Int,body: String): FailureInfo {
            val obj=runCatching { JSONObject(body).optJSONObject("error") ?: JSONObject(body) }.getOrDefault(JSONObject())
            val detail=(obj.optString("code")+" "+obj.optString("message")).lowercase()
            val unsupported=Regex("(not support|unsupported|doesn't support|不支持)")
            return when {
                status==401 -> FailureInfo("permission","模型认证失败，API Key 无效或已过期，请修改模型配置","model_config")
                status==403 || detail.contains("modelnotopen") || detail.contains("not activated") -> FailureInfo("permission","该账号未开通型号或无访问权限，请检查模型配置与服务商授权","model_config")
                status==429 -> FailureInfo("rate_limit","请求受限或额度不足，请稍后重试")
                status==404 -> FailureInfo("configuration","未找到接口或型号，请检查模型配置","model_config")
                status in listOf(400,413,422) && Regex("context_length|context length|maximum context|input.*token.*exceed|上下文.*超|输入.*超").containsMatchIn(detail) -> FailureInfo("context_limit","服务商报告输入超限，请调整上下文设置或资料范围后重试；原有记忆保留。","model_config")
                status==413 -> FailureInfo("request_size","服务商拒绝了过大的请求体，请减少图片或资料后重试。","materials")
                status in listOf(400,422) && Regex("too many images|maximum.*images|images.*exceed|图片数量.*超|图像数量.*超").containsMatchIn(detail) -> FailureInfo("image_count_limit","服务商报告图片数量超限，请减少图片后重试。","materials")
                status in listOf(400,422) && detail.contains("response_format") -> FailureInfo("response_format","接口拒绝结构化输出参数，可使用兼容模式重试","compatible_retry")
                status in listOf(400,422) && unsupported.containsMatchIn(detail) && Regex("image|vision|multimodal|图片|图像").containsMatchIn(detail) -> FailureInfo("image_unsupported","此接口的当前型号明确不支持图片输入","vision_helper")
                status in listOf(400,422) && Regex("reasoning_effort|thinking_budget|enable_thinking|thinking.type|reasoning effort|思考档位|思考预算").containsMatchIn(detail) -> FailureInfo("thinking","接口拒绝了本轮思考参数，可恢复模型默认设置后重试","thinking_default")
                status>=500 -> FailureInfo("network","模型服务暂时不可用（$status），请稍后重试")
                else -> FailureInfo("request","模型拒绝请求（$status），请核对接口、型号和输出参数","model_config")
            }
        }
    }
}
class ModelFailure(val info: FailureInfo,cause: Throwable?=null): IllegalStateException(info.message,cause)
