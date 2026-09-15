package app.mailpilot.ai

import app.mailpilot.data.*
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive
import org.json.JSONObject

/** Independent, content-addressed document notes. History corrections remain chronological. */
class MaterialNotes(private val dao: MailDao,private val client: ModelClient) {
    suspend fun prepare(sources: List<SourceChunk>,hardTokens: Int,preferredTokens: Int,model: ModelProfile,
        requestId: String,account: String,conversation: String,progress: (String)->Unit,diagnostics: (JSONObject)->Unit): String {
        val turn=dao.turn(requestId)
        require(turn==null || (turn.accountId==account && turn.conversationId==conversation)) { "摘要快照不属于当前会话或账号" }
        val durable=turn!=null && turn.accountId==account && turn.conversationId==conversation
        val stored=mutableListOf<JSONObject>()
        // Do not hold twenty complete turn snapshots (including attachment/tool
        // bodies) in memory at once. Retain only their bounded note dictionaries.
        if(durable) for(offset in 0 until 20) {
            currentCoroutineContext().ensureActive()
            val raw=dao.materialNoteRequest(conversation,account,offset) ?: break
            runCatching { JSONObject(raw).optJSONObject("agentRun")?.optJSONObject("materialNotes") }.getOrNull()?.let(stored::add)
        }
        val limits=ContextBudgetPlanner.limits(model)
        val chunkLimits=ContextBudgetPlanner.limits(model.copy(thinkingMode="disabled",thinkingBudget=0,reasoningEffort=""))
        val chunkBudget=minOf(24000,(chunkLimits.trigger-2048).coerceAtLeast(512))
        val leafSpace=(limits.trigger/2-1024).coerceAtLeast(96)
        val leafBudget=minOf(2048,leafSpace)
        val notes=mutableListOf<String>(); var hits=0; var generated=0
        for(source in sources) {
            currentCoroutineContext().ensureActive()
            // Normalize only this source's label; grouped references remain part of the fingerprint.
            val title="${source.title} / ${source.location}${if(source.isModelObservation) "（模型观察，可能有识别误差）" else ""}"
            val canonical=source.text.replace("[${source.id}]","[MATERIAL]")
            val parts=ContextBudgetPlanner.chunks(canonical,chunkBudget).ifEmpty { listOf("") }
            for((index,part) in parts.withIndex()) {
                val input="[MATERIAL] $title · 片段 ${index+1}\n$part"
                val key=stableId("notes-v2|$account|$conversation|${ModelCapabilityResolver.identity(model)}|${source.kind}|${source.url}|$input")
                val legacyKey=stableId("notes-v1|$account|$conversation|${ContextBudgetPlanner.identity(model)}|${source.kind}|${source.url}|$input")
                val cached=stored.firstNotNullOfOrNull { ((it.opt(key) ?: it.opt(legacyKey)) as? String)?.takeIf { text -> text.isNotBlank() && text!="null" } }
                val text=when {
                    ContextBudgetPlanner.estimate(input)<=leafBudget -> input
                    cached!=null && ContextBudgetPlanner.estimate(cached)<=leafSpace -> { hits++; cached }
                    else -> {
                        progress("正在整理资料片段 · ${notes.size+1}")
                        ContextReducer(dao,client).reduce(listOf(input),"",leafSpace,model,requestId,"note-$key",key,
                            progress,diagnostics,leafBudget).also { generated++ }
                    }
                }
                if(durable && (cached!=null || ContextBudgetPlanner.estimate(input)>leafBudget)) AgentCheckpoints.update(dao,requestId) { cp ->
                    val saved=cp.optJSONObject("materialNotes") ?: JSONObject()
                    saved.remove(key); saved.put(key,text)
                    while(saved.length()>128 || ContextBudgetPlanner.estimate(saved.toString())>262144) saved.remove(saved.keys().next())
                    cp.put("materialNotes",saved)
                    cp.optJSONObject("compression")?.remove("note-$key")
                }
                notes+="[${source.id}] $title · 片段 ${index+1}/${parts.size}\n"+text.replace("[MATERIAL]","[${source.id}]")
            }
        }
        val stats=JSONObject().put("stage","compression").put("namespace","materials").put("model",model.model)
            .put("noteCacheHits",hits).put("noteGenerations",generated).put("noteChunks",notes.size).put("inputBudget",limits.input)
        if(durable) AgentCheckpoints.update(dao,requestId) { it.put("materialNoteStats",stats) }
        diagnostics(stats)
        if(hits>0) progress("已复用 $hits 个资料摘要片段")
        val combined=notes.joinToString("\n\n")
        if(ContextBudgetPlanner.estimate(combined)<=hardTokens) return combined
        return ContextReducer(dao,client).reduce(notes,"",hardTokens,model,requestId,"materials","$account|$conversation",
            progress,diagnostics,preferredTokens)
    }
}
