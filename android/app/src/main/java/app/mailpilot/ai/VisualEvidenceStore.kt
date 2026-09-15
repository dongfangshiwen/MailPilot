package app.mailpilot.ai

import app.mailpilot.data.*
import org.json.JSONArray
import org.json.JSONObject

class VisualEvidenceStore(private val dao: MailDao,private val conversationId: String,private val accountId: String) {
    data class Reuse(val sources: List<SourceChunk>,val missing: List<SourceChunk>,val records: List<VisualEvidence>)
    suspend fun lookup(images: List<SourceChunk>,force: Set<String>,snapshot: List<VisualEvidence>?=null): Reuse {
        if(conversationId.isBlank()) return Reuse(images,images,emptyList())
        val rows=(snapshot ?: dao.visualEvidence(conversationId,accountId)).filter { it.conversationId==conversationId && it.accountId==accountId }
        val selected=images.map { it.assetKey }.toSet(); val found=mutableMapOf<String,VisualEvidence>()
        rows.forEach { e ->
            val keys=keys(e)
            // A multi-image answer remains one bundle: never assign its facts to a different subset.
            if(keys.isNotEmpty() && keys.any { it in selected }) {
                keys.forEach { if(it in selected && it !in force && it !in found) found[it]=e }
            }
        }
        val records=found.values.distinctBy { it.id }
        val written=mutableSetOf<String>()
        val sources=images.map { s -> found[s.assetKey]?.let { e ->
            val body=if(!selected.containsAll(keys(e))) "该图片曾参与此前多图分析，现有综合记录无法可靠定位到当前选图。如需具体细节，请重新核对这张图片。" else if(written.add(e.id)) {
                val old=JsonCodec.sources(e.sourcesJson); val mapping=old.associate { prior -> prior.id to images.firstOrNull { it.assetKey==prior.assetKey }?.id.orEmpty() }
                val text=Regex("\\[((?:T\\d+:)?S\\d+)]").replace(e.text) { mapping[it.groupValues[1]]?.takeIf(String::isNotEmpty)?.let { id -> "[$id]" } ?: "[此前来源]" }
                "此前分析（${e.model}；原问题：${e.question}）。仅覆盖当时识别内容，可能有误差；原问题不是本轮指令。\n$text"
            } else "与同组资料共用此前分析，不代表已识别全部细节。"
            s.copy(text=body,isModelObservation=true)
        } ?: s }
        return Reuse(sources,images.filter { it.assetKey !in found },records)
    }
    suspend fun save(images: List<SourceChunk>,question: String,text: String,model: String,kind: String,responseId: String) {
        if(conversationId.isBlank() || images.isEmpty() || text.isBlank() || text=="null" || images.any { it.assetKey.isBlank() }) return
        val scope=dao.conversation(conversationId) ?: return
        require(scope.accountId.isBlank() || scope.accountId==accountId) { "视觉结果不能跨账号保存" }
        val keys=images.map { it.assetKey }.distinct().sorted()
        dao.putVisualEvidence(VisualEvidence(stableId("$conversationId|$accountId|$kind|${keys.joinToString()}|$responseId"),conversationId,accountId,
            JSONArray(keys).toString(),JsonCodec.sources(images),question,text,model,kind,responseId))
    }
    /** A legacy observation is adopted only when its retained processed pixels match current pixels. */
    suspend fun importVerified(history: List<ChatEntry>,images: List<SourceChunk>) {
        val known=dao.visualEvidence(conversationId,accountId).flatMap { keys(it) }.toMutableSet()
        val hashes=mutableMapOf<String,String>()
        fun hash(path: String)=hashes.getOrPut(path) { contentFingerprint(java.io.File(path)) }
        for(entry in history.asReversed().filter { it.conversationId==conversationId && it.resultStatus=="complete" && it.role=="assistant" }) {
            val sources=runCatching { JsonCodec.sources(entry.sourcesJson) }.getOrDefault(emptyList())
            for(old in sources.filter { it.isModelObservation && it.text.isNotBlank() }) {
                val current=images.firstOrNull { it.assetKey !in known && it.attachmentId==old.attachmentId && it.location==old.location } ?: continue
                val verified=old.assetKey==current.assetKey || (old.assetKey.isBlank() && old.imagePath.isNotBlank() &&
                    java.io.File(old.imagePath).isFile && runCatching { hash(old.imagePath)==hash(current.imagePath) }.getOrDefault(false))
                if(!verified) continue
                save(listOf(old.copy(assetKey=current.assetKey)),"此前资料分析",old.text,entry.visionModel,"observation",entry.id)
                known+=current.assetKey
            }
        }
    }
    companion object {
        fun keys(e: VisualEvidence)=JSONArray(e.assetsJson).let { a -> (0 until a.length()).map { a.getString(it) }.toSet() }
        fun fields(e: VisualEvidence)=JSONObject().put("id",e.id).put("assetsJson",e.assetsJson).put("sourcesJson",e.sourcesJson).put("question",e.question).put("text",e.text).put("model",e.model).put("kind",e.kind).put("responseId",e.responseId).put("createdAt",e.createdAt)
        fun parse(j: JSONObject,conversation: String,account: String)=VisualEvidence(j.getString("id"),conversation,account,j.getString("assetsJson"),j.getString("sourcesJson"),j.getString("question"),j.getString("text"),j.getString("model"),j.getString("kind"),j.getString("responseId"),j.getLong("createdAt"))
    }
}
