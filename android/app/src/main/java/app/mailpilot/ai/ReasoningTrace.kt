package app.mailpilot.ai

import app.mailpilot.data.ChatEntry
import app.mailpilot.data.newId
import org.json.JSONObject

data class ReasoningSegment(val id: String,val stage: String,val start: Int,val end: Int,val state: String,val order: Long=0) {
    fun fields()=mapOf("id" to id,"stage" to stage,"start" to start,"end" to end,"state" to state,"order" to order)
}
data class ReasoningSnapshot(val text: String="",val elapsedMs: Long=0,val state: String="",val truncated: Boolean=false,
    val attemptId: String="",val revision: Long=0,val runComplete: Boolean=false,
    val segments: List<ReasoningSegment> = emptyList(),val previous: List<ReasoningSnapshot> = emptyList(),val activities: List<Map<String,Any>> = emptyList()) {
    fun fields(): Map<String,Any> = mapOf("text" to text,"elapsedMs" to elapsedMs,"state" to state,"truncated" to truncated,
        "attemptId" to attemptId,"revision" to revision,"runComplete" to runComplete,
        "segments" to segments.map { it.fields() },"previous" to previous.map { it.copy(previous=emptyList()).fields() },"activities" to activities)
    fun attach(entry: ChatEntry)=entry.copy(reasoningText=text,reasoningMillis=elapsedMs,reasoningState=state,reasoningTruncated=truncated)
    companion object {
        fun from(j: JSONObject?): ReasoningSnapshot {
            if(j==null) return ReasoningSnapshot()
            val parts=j.optJSONArray("segments"); val old=j.optJSONArray("previous")
            return ReasoningSnapshot(j.optString("text"),j.optLong("elapsedMs"),j.optString("state"),j.optBoolean("truncated"),
                j.optString("attemptId"),j.optLong("revision"),j.optBoolean("runComplete"),
                (0 until (parts?.length() ?: 0)).map { i -> val p=parts!!.getJSONObject(i); ReasoningSegment(p.getString("id"),p.optString("stage"),p.getInt("start"),p.getInt("end"),p.getString("state"),p.optLong("order")) },
                (0 until minOf(3,old?.length() ?: 0)).map { from(JSONObject(old!!.getJSONObject(it).toString()).apply { remove("previous") }) },
                j.optJSONArray("activities")?.let { a -> (0 until minOf(a.length(),128)).map { i -> val v=a.getJSONObject(i); mapOf<String,Any>("id" to v.optString("id"),"kind" to v.optString("kind"),"state" to v.optString("state"),"count" to v.optInt("count"),"order" to v.optLong("order"),"sequence" to v.optInt("sequence"),"domains" to (v.optJSONArray("domains")?.let { d -> (0 until d.length()).map { d.getString(it) } } ?: emptyList())) } } ?: emptyList())
        }
        fun legacy(e: ChatEntry)=ReasoningSnapshot(e.reasoningText,e.reasoningMillis,e.reasoningState,e.reasoningTruncated,runComplete=e.resultStatus!="running")
    }
}

/** Display-only trace. Provider protocol messages remain untouched for tool continuation. */
class ReasoningTrace(private val attemptId: String=newId(),previous: ReasoningSnapshot?=null,
    private val clock: ()->Long = { System.nanoTime()/1_000_000 }) {
    companion object { const val MAX_CHARS=128000 }
    private val text=StringBuilder()
    private val parts=mutableListOf<ReasoningSegment>()
    private val activities=mutableListOf<Map<String,Any>>()
    private val old=previous?.let { listOf(it.copy(previous=emptyList(),attemptId=it.attemptId.ifBlank { newId() }))+it.previous }?.filter { it.text.isNotEmpty() || it.activities.isNotEmpty() }?.take(3).orEmpty()
    private var started: Long?=null
    private var elapsed=0L
    private var state=""
    private var truncated=false
    private var revision=0L; private var complete=false
    private var request=""; private var stage="answer"
    @Synchronized fun begin(id: String,phase: String) {
        if(request==id) return
        finish(); request=id; stage=phase
    }
    @Synchronized fun append(delta: String) {
        if(delta.isEmpty() || complete) return
        if(started==null) {
            started=clock(); state="thinking"
            if(!truncated && text.isNotEmpty() && text.length+2<MAX_CHARS) text.append("\n\n")
            parts+=ReasoningSegment(request.ifBlank { newId() },stage,text.length,text.length,"thinking",++revision)
        }
        if(truncated) return
        val room=MAX_CHARS-text.length
        var length=minOf(room,delta.length)
        if(length<delta.length && length>0 && delta[length-1].isHighSurrogate()) length--
        text.append(delta,0,length); revision++
        parts[parts.lastIndex]=parts.last().copy(end=text.length)
        if(length<delta.length) truncated=true
    }
    @Synchronized fun finish(outcome: String="completed") {
        require(outcome in setOf("completed","stopped","interrupted"))
        if(started!=null) {
            elapsed+=(clock()-started!!).coerceAtLeast(0); started=null
            state=outcome; revision++
            if(parts.isNotEmpty()) parts[parts.lastIndex]=parts.last().copy(state=outcome,end=text.length)
        }
    }
    @Synchronized fun activity(event: AgentEvent.ToolActivity) {
        if(complete) return
        val index=activities.indexOfFirst { it["id"]==event.id }
        val prior=activities.getOrNull(index)
        if(prior!=null && (prior["sequence"] as Number).toInt()>=event.sequence) return
        if(index<0 && activities.size>=128) return
        revision++
        val value=mapOf("id" to event.id,"kind" to event.kind,"state" to event.state,"count" to event.count,
            "domains" to event.domains.take(8),"order" to (prior?.get("order") ?: revision),"sequence" to event.sequence)
        if(index<0) activities+=value else activities[index]=value
    }
    @Synchronized fun end(outcome: String="completed") {
        finish(outcome)
        for(i in activities.indices) if(activities[i]["state"]=="running") activities[i]=activities[i]+("state" to if(outcome=="completed") "failed" else outcome)
        complete=true; revision++
    }
    @Synchronized fun snapshot()=ReasoningSnapshot(text.toString(),elapsed+(started?.let { (clock()-it).coerceAtLeast(0) } ?: 0),state,truncated,
        attemptId,revision,complete,parts.toList(),old,activities.toList())
}
