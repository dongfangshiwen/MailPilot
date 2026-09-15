package app.mailpilot.ai

import app.mailpilot.data.*
import org.json.*

/** Deterministic progress, independent of model wording. Stored with the turn, never global. */
class ResearchProgress(val data: JSONObject) {
    init { data.put("version",2) }
    companion object { const val MAX_ROUNDS=7; const val MAX_PAGES=8 }
    val rounds get()=data.optInt("rounds")
    val finishing get()=data.optString("phase")=="synthesize" || rounds>=MAX_ROUNDS || data.optInt("idleRounds")>=2
    val count get()=data.optLong("progress")
    val pages get()=data.optJSONObject("pages") ?: JSONObject().also { data.put("pages",it) }
    fun resume() { data.remove("stopReason"); data.put("rounds",0).put("idleRounds",0).put("phase","gather").put("pages",JSONObject()) }
    fun finishRound(before: Long) { data.put("rounds",rounds+1).put("idleRounds",if(count>before) 0 else data.optInt("idleRounds")+1) }
    fun stop(reason: String) { data.put("phase","synthesize").put("stopReason",reason) }
    fun key(name: String,args: JSONObject): String {
        fun canonical(v: Any?): String=when(v) {
            is JSONObject -> v.keys().asSequence().sorted().joinToString(prefix="{",postfix="}") { JSONObject.quote(it)+":"+canonical(v.opt(it)) }
            is JSONArray -> (0 until v.length()).joinToString(prefix="[",postfix="]") { canonical(v.opt(it)) }
            is String -> JSONObject.quote(v)
            else -> v?.toString() ?: "null"
        }
        val policy=if(name in setOf("read_web_page","read_evidence")) "|web-policy:${WebReadWorkflow.READ_POLICY_VERSION}|" else ""
        return stableId(name+policy+canonical(args))
    }
    fun receipt(key: String)=data.optJSONObject("receipts")?.opt(key) as? String
    fun saveReceipt(key: String,text: String) { val receipts=data.optJSONObject("receipts") ?: JSONObject(); receipts.put(key,text); data.put("receipts",receipts) }
    fun discardReceipt(key: String) { data.optJSONObject("receipts")?.remove(key) }
    /** Cache the acquired source identities, never a budget-dependent rendered excerpt. */
    fun evidenceReceipt(key: String,sources: List<SourceChunk>): List<SourceChunk>? {
        val ids=data.optJSONObject("evidenceReceipts")?.optJSONArray(key) ?: return null
        val current=sources.associateBy { it.id }
        return (0 until ids.length()).map { current[ids.optString(it)]?.takeIf { source -> source.kind=="web" } ?: return null }
    }
    fun saveEvidenceReceipt(key: String,sources: List<SourceChunk>) {
        val receipts=data.optJSONObject("evidenceReceipts") ?: JSONObject()
        receipts.put(key,JSONArray(sources.map { it.id }.distinct())); data.put("evidenceReceipts",receipts)
    }
    fun source(source: SourceChunk) {
        val versions=data.optJSONObject("sources") ?: JSONObject()
        val key=stableId(source.url.ifBlank { source.id }); val hash=stableId(source.text)
        if(source.text.isNotBlank() && versions.optString(key)!=hash) { versions.put(key,hash); data.put("progress",count+1) }
        data.put("sources",versions)
    }
    private fun rangeKey(source: SourceChunk)=if(source.kind=="web" && source.url.isNotBlank()) stableId("web-range-v2|${source.url}|${stableId(source.text)}")
        else stableId(source.id+stableId(source.text))
    private fun intervals(value: JSONArray?)=(0 until (value?.length() ?: 0)).map { value!!.getJSONArray(it).let { a -> a.getInt(0) to a.getInt(1) } }
    private fun union(intervals: List<Pair<Int,Int>>): List<Pair<Int,Int>> {
        val merged=mutableListOf<Pair<Int,Int>>()
        for(next in intervals.sortedBy { it.first }) {
            if(merged.isEmpty() || merged.last().second<next.first) merged+=next
            else merged[merged.lastIndex]=merged.last().first to maxOf(merged.last().second,next.second)
        }
        return merged
    }
    private fun encoded(intervals: List<Pair<Int,Int>>)=JSONArray().apply { intervals.forEach { put(JSONArray(listOf(it.first,it.second))) } }
    /** Migrate authorized aliases without counting migration itself as new evidence. */
    fun bindSources(sources: List<SourceChunk>) {
        val ranges=data.optJSONObject("ranges") ?: return
        for(source in sources) {
            val legacy=stableId(source.id+stableId(source.text)); val key=rangeKey(source)
            if(legacy==key || !ranges.has(legacy)) continue
            ranges.put(key,encoded(union(intervals(ranges.optJSONArray(key))+intervals(ranges.optJSONArray(legacy)))))
            ranges.remove(legacy)
        }
    }
    fun read(source: SourceChunk,start: Int,end: Int) {
        if(start<0 || end>source.text.length || end<=start) return
        bindSources(listOf(source))
        val ranges=data.optJSONObject("ranges") ?: JSONObject(); val key=rangeKey(source)
        val old=intervals(ranges.optJSONArray(key)); val merged=union(old+(start to end))
        if(merged.sumOf { it.second-it.first }>old.sumOf { it.second-it.first }) data.put("progress",count+1)
        ranges.put(key,encoded(merged)); data.put("ranges",ranges)
    }
}
