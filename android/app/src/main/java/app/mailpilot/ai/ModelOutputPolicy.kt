package app.mailpilot.ai

import app.mailpilot.data.DEFAULT_MODEL_OUTPUT_TOKENS
import app.mailpilot.data.ModelProfile
import org.json.JSONArray

/** Zero in the existing output column means automatic, never a zero-token API request. */
object ModelOutputPolicy {
    const val AUTO = 0
    fun mode(p: ModelProfile, saved: String? = null): String = saved?.takeIf { it in setOf("auto", "custom") }
        ?: if (p.outputTokens == AUTO || (p.outputTokens == DEFAULT_MODEL_OUTPUT_TOKENS && ModelCapabilityResolver.contextEntry(p) != null)) "auto" else "custom"
    fun resolve(p: ModelProfile, saved: String? = null) = if (mode(p, saved) == "auto") p.copy(outputTokens = AUTO) else p
    fun maximum(p: ModelProfile) = ModelCapabilityResolver.contextEntry(p)?.output ?: DEFAULT_MODEL_OUTPUT_TOKENS
    fun ceiling(p: ModelProfile) = if (p.outputTokens == AUTO) maximum(p) else p.outputTokens
    // Automatic mode keeps the established minimum output reserve for history planning.
    // The final request grants all remaining space, up to the verified model maximum.
    fun reserve(p: ModelProfile) = if (p.outputTokens == AUTO)
        minOf(maximum(p), maxOf(DEFAULT_MODEL_OUTPUT_TOKENS, p.thinkingBudget + 1024)) else p.outputTokens
    fun requestTokens(p: ModelProfile, messages: JSONArray, tools: JSONArray? = null): Int {
        if (p.outputTokens != AUTO) return p.outputTokens
        val remaining = ContextBudgetPlanner.limits(p).context - ContextBudgetPlanner.extraThinking(p) -
            ContextBudgetPlanner.estimate(messages, tools, p)
        return minOf(maximum(p), remaining).also {
            if (it < 128 || (p.thinkingMode != "disabled" && p.thinkingBudget >= it))
                throw ModelFailure(FailureInfo("context_limit", "本轮资料没有为输出留下足够空间，请调整资料或上下文设置。", "model_config", p.model))
        }
    }
}
