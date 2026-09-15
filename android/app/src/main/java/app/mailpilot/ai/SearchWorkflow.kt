package app.mailpilot.ai

import app.mailpilot.data.*
import app.mailpilot.services.DirectWebSearchClient
import app.mailpilot.services.WebSearchClient
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.supervisorScope
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import org.json.JSONArray
import org.json.JSONObject

/** Boundary filtering is separate from semantic intent selection. */
object SearchPrivacy {
    // Contact details and obvious credentials never become search-engine keywords.
    fun publicText(text: String): String = text
        .replace(Regex("(?i)(?:api[_-]?key|access[_-]?token|authorization|password|密码|授权码|密钥)\\s*[:=：]\\s*\\S+"), "[凭据已省略]")
        .replace(Regex("(?i)https?://[^\\s<>\"\\]]+")) { match ->
            // Public domains can help resolve a topic; private paths/query tokens cannot.
            runCatching { java.net.URI(match.value).host }.getOrNull()?.let { "https://$it" } ?: "[链接已省略]"
        }
        .replace(Regex("(?i)\\b(?:sk|ark)-[a-z0-9_-]{12,}\\b"), "[凭据已省略]")
        .replace(Regex("(?i)\\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}\\b"), "[邮箱已省略]")
        .replace(Regex("(?<![\\p{L}\\d])\\+?\\d[\\d ()-]{9,}\\d(?![\\p{L}\\d])"), "[号码已省略]")

}

/** Execute validated public queries; each successful query is an independent checkpoint. */
class SearchWorkflow(private val dao: MailDao,private val service: WebSearchClient?) {
    suspend fun run(queries: JSONArray,contextKey: String,config: ServiceConfig,requestId: String,
        progress: (String)->Unit,event: (AgentEvent)->Unit): List<SourceChunk> {
        val key=stableId(contextKey+config.json())
        suspend fun cached()=AgentRunCheckpoint.from(dao.turn(requestId)).data.optJSONObject("search")?.takeIf { it.optString("key")==key }
        val publicQueries=(0 until queries.length()).map { i ->
            val raw=(queries.opt(i) as? String)?.trim().orEmpty()
            if(raw.length !in 1..100 || raw=="null" || queries.length() !in 1..2)
                throw ModelFailure(FailureInfo("search_query_format","搜索动作没有提供有效关键词，请重试本轮。"))
            val sanitized=SearchPrivacy.publicText(raw).replace(Regex("\\[(?:凭据|邮箱|号码|链接)已省略]"),"").trim()
            if(sanitized.length<2) throw ModelFailure(FailureInfo("search_query_private","未提取出可公开检索的主题，请补充产品、技术或政策名称。"))
            sanitized
        }.distinct()
        if(publicQueries.isEmpty()) throw ModelFailure(FailureInfo("search_query_format","搜索动作没有提供关键词，请重试本轮。"))
        AgentCheckpoints.update(dao,requestId) { cp -> cp.put("search",(cp.optJSONObject("search")?.takeIf { it.optString("key")==key } ?: JSONObject()).put("key",key).put("phase","retrieving")) }
        progress("正在检索 ${publicQueries.size} 项公开主题")
        event(AgentEvent.Stage("search_retrieving","正在检索相关网页"))
        val fetched=supervisorScope { publicQueries.map { query -> async {
            currentCoroutineContext().ensureActive()
            val start=System.nanoTime()
            val attempt=AgentRunCheckpoint.from(dao.turn(requestId)).data.optString("activeAttemptId")
            val queryKey=stableId(query)
            // optString returns an empty string for a missing key. A miss is not JSON.
            val saved=(cached()?.optJSONObject("results")?.opt(queryKey) as? String)?.takeIf { it.isNotBlank() }
            val restored=saved?.let { runCatching { JsonCodec.sources(it) }.getOrNull() }
            var outcome="complete"
            try { Result.success(restored ?: run {
                requireNotNull(service) { "搜索服务不可用" }.search(config,query).also { values ->
                    AgentCheckpoints.update(dao,requestId) { cp -> val search=cp.getJSONObject("search")
                        search.put("results",(search.optJSONObject("results") ?: JSONObject()).put(queryKey,JsonCodec.sources(values))) }
                }
            }) } catch(e: CancellationException) { outcome="stopped"; throw e } catch(e: Exception) { outcome="failed"; Result.failure<List<SourceChunk>>(WebSearchFailure(e.message ?: "请检查搜索服务设置")) }
            finally { kotlinx.coroutines.withContext(kotlinx.coroutines.NonCancellable) {
                RunTelemetry.request(dao,requestId,attempt,JSONObject().put("id",newId()).put("stage","search")
                    .put("elapsedMs",(System.nanoTime()-start)/1_000_000).put("cacheHit",restored!=null).put("status",outcome))
            } }
        } }.awaitAll() }
        // Successful siblings have already been checkpointed, even when another failed.
        val sources=DirectWebSearchClient.deduplicate(fetched.flatMap { it.getOrNull().orEmpty() })
        fetched.firstOrNull { it.isFailure }?.exceptionOrNull()?.let { throw WebSearchFailure(it.message.orEmpty().removePrefix("本轮未完成联网："),sources) }
        progress("已取得 ${sources.size} 个网页来源")
        AgentCheckpoints.update(dao,requestId) { it.optJSONObject("search")?.put("phase","complete") }
        return sources
    }
}
