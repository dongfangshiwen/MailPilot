package app.mailpilot.ai

import app.mailpilot.data.*
import app.mailpilot.services.*
import kotlinx.coroutines.*
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import org.json.*

data class WebReadResult(val text: String,val count: Int,val domains: List<String>,val cacheable: Boolean,val reusedCount: Int=0)

/** Bounded page acquisition, independent of the model's decision loop. */
class WebReadWorkflow(private val dao: MailDao,private val reader: WebPageReader,private val store: WebEvidenceStore?=null) {
    companion object { const val READ_POLICY_VERSION=3 }
    private data class Loaded(val page: WebPage,val fetched: Boolean)
    suspend fun run(ids: List<String>,sources: List<SourceChunk>,progress: ResearchProgress,budget: Int,question: String,requestId: String,
        save: suspend (List<SourceChunk>)->Unit): WebReadResult {
        var numbered=sources.map { store?.restore(it) ?: WebEvidenceStore.normalize(it) }; val saveMutex=Mutex()
        val attempt=if(requestId.isBlank()) "" else AgentRunCheckpoint.from(dao.turn(requestId)).data.optString("activeAttemptId")
        val requested=ids.distinct()
        val allowed=requested.mapNotNull { id -> numbered.singleOrNull { it.id==id && it.kind=="web" && it.url.isNotBlank() } }
        val loaded=linkedMapOf<String,Loaded>()
        // Full URLs include query and fragment: different SPA routes are different documents.
        for(group in allowed.map { it.url }.distinct().chunked(2)) {
            val results=coroutineScope { group.map { url ->
                val key=stableId(url); val saved=progress.pages.optJSONObject(key)
                val aliases=numbered.filter { it.kind=="web" && it.url==url }
                val complete=aliases.firstOrNull { it.retrieval=="webpage" && it.text.isNotBlank() }
                val permitted=saved!=null || complete!=null || progress.pages.length()<ResearchProgress.MAX_PAGES
                if(permitted && complete==null && saved==null) progress.pages.put(key,JSONObject().put("status","pending"))
                async(start=CoroutineStart.LAZY) {
                    var fetched=false
                    var page=when {
                        !permitted -> WebPage(status="page_budget")
                        complete!=null -> WebPage(complete.text,"cached")
                        saved!=null && saved.optInt("policyVersion")==READ_POLICY_VERSION && saved.optString("attemptId")==attempt && saved.optString("status") !in listOf("pending","complete","cached") ->
                            WebPage(aliases.firstOrNull { it.retrieval=="webpage_partial" && it.webReadStatus==saved.optString("status") }?.text.orEmpty(),saved.optString("status"))
                        else -> { fetched=true; fetch(url,requestId) }
                    }
                    if(page.status in listOf("complete","cached") && page.text.isBlank()) page=page.copy(status="empty")
                    if(page.status!="page_budget") saveMutex.withLock {
                        if(page.text.isNotBlank()) {
                            val partial=page.status !in listOf("complete","cached")
                            val base=complete ?: aliases.first()
                            val updated=base.copy(text=if(partial) page.text.take(4000) else page.text,
                                webReadVersion=READ_POLICY_VERSION,webReadStatus=if(page.status=="cached") "complete" else page.status,
                                contentKey=if(page.status=="cached") base.contentKey else "",
                                location=if(partial) "页面可见片段（正文未确认完整）" else if(page.status=="cached") base.location else if(page.rendered) "网页正文（动态页面可见文字）" else "网页正文（已提取可读文字）",
                                retrieval=if(partial) "webpage_partial" else "webpage")
                            val stored=if(page.status=="complete") store?.save(updated) ?: updated else updated
                            // Share fetched bytes while preserving each source's mail, attachment and citation identity.
                            numbered=numbered.map { source -> if(source.kind=="web" && source.url==url)
                                source.copy(text=stored.text,contentKey=stored.contentKey,location=stored.location,retrieval=stored.retrieval,webReadVersion=stored.webReadVersion,webReadStatus=stored.webReadStatus) else source }
                        }
                        if(page.status!="cached") progress.pages.put(key,receipt(page.status,attempt))
                        // Commit failures as well as successes before waiting for a sibling request.
                        save(numbered)
                    }
                    url to Loaded(page,fetched)
                }
            }.awaitAll() }
            loaded.putAll(results)
        }
        val views=requested.map { id ->
            val source=allowed.singleOrNull { it.id==id }; val page=source?.let { loaded[it.url]?.page }
            val updated=if(page?.text?.isNotBlank()==true) numbered.single { it.id==id } else null
            if(updated!=null) progress.source(updated)
            WebReadView(id,updated,page?.status ?: "unauthorized")
        }
        progress.bindSources(numbered)
        val text=WebReadReport.render(views,EvidenceView { numbered }.also { it.onRead=progress::read },budget,question)
        save(numbered)
        val domains=allowed.filter { loaded[it.url]?.page?.text?.isNotBlank()==true }.mapNotNull { runCatching { java.net.URI(it.url).host }.getOrNull() }.distinct()
        return WebReadResult(text,loaded.values.count { it.fetched && it.page.text.isNotBlank() },domains,
            views.all { it.source!=null && it.status in listOf("complete","cached") },loaded.values.count { !it.fetched && it.page.text.isNotBlank() })
    }
    private fun receipt(status: String,attempt: String)=JSONObject().put("status",status).put("policyVersion",READ_POLICY_VERSION).put("attemptId",attempt)
    private suspend fun fetch(url: String,requestId: String): WebPage {
        val started=System.nanoTime(); var status="stopped"; var cause=""; var rendered=false
        try {
            val page=try { reader.read(url) }
                catch(e: TimeoutCancellationException) { currentCoroutineContext().ensureActive(); cause=e.javaClass.simpleName; WebPage(status="timeout") }
                catch(e: CancellationException) { cause=e.javaClass.simpleName; throw e }
                catch(e: IllegalArgumentException) { cause=e.javaClass.simpleName; WebPage(status="blocked_target") }
                catch(e: Exception) { cause=e.javaClass.simpleName; WebPage(status="connection_failed") }
            status=page.status; rendered=page.rendered; cause=page.cause.ifBlank { cause }; return page
        } finally { if(requestId.isNotBlank()) withContext(NonCancellable) {
            RunTelemetry.request(dao,requestId,AgentRunCheckpoint.from(dao.turn(requestId)).data.optString("activeAttemptId"),JSONObject().put("id",newId()).put("stage","web_read").put("status",status).put("rendered",rendered).put("cause",cause).put("elapsedMs",(System.nanoTime()-started)/1_000_000))
        } }
    }
}
