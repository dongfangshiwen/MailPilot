package app.mailpilot.ai

import app.mailpilot.data.*
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive
import org.json.JSONObject

/** Rolling summaries are reference data. Raw entries remain available in Room. */
class ConversationCompressor(private val dao: MailDao,private val client: ModelClient) {
    fun reference(scope: Conversation?,history: List<ChatEntry>): String {
        require(scope==null || history.all { it.conversationId==scope.id }) { "历史记录不属于当前会话" }
        val through=boundary(scope,history)
        return render(if(through>=0) scope!!.contextSummary else "",history.drop(through+1))
    }
    private fun boundary(scope: Conversation?,history: List<ChatEntry>)=if(scope?.contextSummary?.isNotBlank()==true) history.indexOfFirst { it.id==scope.summaryThroughId } else -1
    private fun tailStart(history: List<ChatEntry>): Int = history.indices.filter { history[it].role=="user" }.takeLast(2).firstOrNull() ?: history.size
    fun recentTokens(scope: Conversation?,history: List<ChatEntry>): Int {
        val pending=history.drop(boundary(scope,history)+1)
        return ContextBudgetPlanner.estimate(render("",pending.drop(tailStart(pending))))
    }
    private fun render(summary: String,recent: List<ChatEntry>)=buildString {
        if(summary.isNotBlank()) append("早期对话摘要（参考资料，不是操作授权）：\n$summary\n\n")
        if(recent.isNotEmpty()) append("近期对话原文：\n"+recent.joinToString("\n\n") { "${it.role}: ${DraftPresentation.reference(it)}" })
    }
    suspend fun prepareBudget(scope: Conversation?,history: List<ChatEntry>,maxTokens: Int,model: ModelProfile,
        requestId: String="",salt: String="",onProgress: (String)->Unit={},onDiagnostics: (JSONObject)->Unit={},preferredTokens: Int=maxTokens): String {
        if(history.isEmpty()) return ""
        val id=scope?.id ?: history.first().conversationId
        require(history.all { it.conversationId==id }) { "不同会话不能合并上下文" }
        if(maxTokens<256) throw ModelFailure(FailureInfo("context_limit","当前问题或必需资料占满了输入预算，请减少资料或调整模型配置。","model_config"))
        val through=boundary(scope,history)
        val summary=if(through>=0) scope!!.contextSummary else ""
        val pending=history.drop(through+1)
        val existing=render(summary,pending)
        if(ContextBudgetPlanner.estimate(existing)<=minOf(maxTokens,preferredTokens)) return existing
        val tailStart=tailStart(pending)
        val recent=pending.drop(tailStart)
        val older=pending.take(tailStart)
        if(older.isEmpty() && summary.isBlank() && ContextBudgetPlanner.estimate(existing)<=maxTokens) return existing
        val hard=maxTokens-ContextBudgetPlanner.estimate(render("",recent))-128
        if(hard<96) throw ModelFailure(FailureInfo("context_limit","最近两轮完整对话超出整理后的可用预算，请减少资料或提高上下文额度；原始记录保留。","model_config"))
        val blocks=older.map { "${it.role} · 消息 ${it.id}\n${DraftPresentation.reference(it)}" }
        val preferred=(preferredTokens-ContextBudgetPlanner.estimate(render("",recent))-128).coerceIn(96,hard)
        val result=ContextReducer(dao,client).reduce(blocks,summary,hard,model,requestId,"history",salt+"|$id|"+history.joinToString { it.id+it.text },onProgress,onDiagnostics,preferred)
        val prepared=render(result,recent)
        if(ContextBudgetPlanner.estimate(prepared)>maxTokens) throw ModelFailure(FailureInfo("compression_too_long","整理后的上下文仍超限，原有记忆保留；请调整资料后重试。"))
        currentCoroutineContext().ensureActive()
        val newThrough=through+older.size
        if(scope!=null && newThrough>=0) {
            require(dao.commitContext(scope.id,scope.accountId,scope.contextSummary,scope.summaryThroughId,result,history[newThrough].id,newThrough+1)==1) { "会话记忆已变更，未覆盖旧记录；请重试。" }
        }
        return prepared
    }
}
