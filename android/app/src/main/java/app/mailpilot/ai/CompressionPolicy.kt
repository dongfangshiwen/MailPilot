package app.mailpilot.ai

import app.mailpilot.data.ModelProfile

/** Task-local settings never mutate the saved model or the answer's thinking mode. */
object CompressionPolicy {
    fun model(main: ModelProfile,fast: Boolean): ModelProfile =
        if(fast && ReasoningOptions.provider(main) in setOf("deepseek","volcengine","aliyun"))
            main.copy(thinkingMode="disabled",thinkingBudget=0,reasoningEffort="") else main

    fun outputLimit(model: ModelProfile,target: Int): Int? {
        val thinking=model.thinkingMode!="disabled"
        val separate=ReasoningOptions.provider(model)=="volcengine" && model.tokenParameter=="max_tokens"
        // An unknown combined thinking/body quota cannot safely be tightened to a
        // short body budget. Fast mode makes the budget predictable on supported APIs.
        if(thinking && !separate && model.thinkingBudget==0) return null
        val body=(target.toLong()+512).coerceIn(512,8192).toInt()
        return minOf(ModelOutputPolicy.ceiling(model),body+if(thinking && !separate) model.thinkingBudget else 0)
    }
}
