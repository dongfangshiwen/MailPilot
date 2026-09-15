package app.mailpilot.services

import app.mailpilot.data.*
import org.json.JSONObject
import okhttp3.HttpUrl.Companion.toHttpUrlOrNull

interface WebSearchClient { suspend fun search(config: ServiceConfig,query: String): List<SourceChunk> }

class DirectWebSearchClient(private val secrets: SecretStore,private val http: JsonHttp=JsonHttp()): WebSearchClient {
    override suspend fun search(config: ServiceConfig,query: String): List<SourceChunk> {
        require(query.isNotBlank() && query.length<=100) { "搜索词应为 1–100 字符" }
        require(config.keyCipher.isNotBlank()) { "请在设置中配置独立的联网搜索服务" }
        val volc=config.provider=="volcengine"
        require(volc || config.provider=="bocha") { "搜索服务商不受支持" }
        val body=if(volc) JSONObject().put("Query",query).put("SearchType","web").put("Count",5)
            .put("Filter",JSONObject().put("NeedContent",true).put("NeedUrl",true)).put("ContentFormats","text")
        else JSONObject().put("query",query).put("count",5).put("summary",true).put("freshness","noLimit")
        return parse(config.provider,http.post(config.baseUrl,secrets.decrypt(config.keyCipher),body))
    }
    companion object {
        fun parse(provider: String,j: JSONObject): List<SourceChunk> {
            val volc=provider=="volcengine"
            require(j.optJSONObject("ResponseMetadata")?.optJSONObject("Error")==null) { "联网搜索服务返回错误，请检查配置和额度" }
            if(!volc) require(!j.has("code") || j.optInt("code")==200) { "博查请求未成功，请检查配置和额度" }
            val rows=if(volc) j.optJSONObject("Result")?.optJSONArray("WebResults") else j.optJSONObject("data")?.optJSONObject("webPages")?.optJSONArray("value")
            requireNotNull(rows) { "搜索服务未返回有效结果列表" }
            return (0 until minOf(rows.length(),5)).mapNotNull { index ->
                val r=rows.getJSONObject(index)
                val url=r.optString(if(volc) "Url" else "url").toHttpUrlOrNull()?.takeIf { it.username.isEmpty() && it.password.isEmpty() } ?: return@mapNotNull null
                val text=if(volc) r.optString("Content").ifBlank { r.optString("Summary").ifBlank { r.optString("Snippet") } } else r.optString("summary").ifBlank { r.optString("snippet") }
                val excerpt=text.take(6000)
                SourceChunk(messageId="",title=r.optString(if(volc) "Title" else "name",url.host),location="网页检索内容${if(text.length>excerpt.length) "（前 6000 字）" else ""}",text=excerpt,kind="web",url=url.toString())
            }
        }
        fun deduplicate(sources: List<SourceChunk>)=sources.distinctBy { it.url.toHttpUrlOrNull()?.newBuilder()?.fragment(null)?.build()?.toString()?.trimEnd('/') ?: it.url }.take(8)
    }
}
