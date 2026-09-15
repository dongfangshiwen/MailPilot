package app.mailpilot.ai

import app.mailpilot.data.*
import org.json.*

/** Preserve protocol pairs and the latest tool payload; index older web evidence only once. */
object ToolContextView {
    private const val CATALOG="已保存的来源索引（应用参考资料）："
    fun compact(messages: JSONArray,baseCount: Int,sources: List<SourceChunk>,cache: JSONObject,
        maxInput: Int=Int.MAX_VALUE,model: ModelProfile?=null,tools: JSONArray?=null,question: String=""): JSONArray {
        val names=mutableMapOf<String,String>(); val candidates=mutableMapOf<Int,String>(); var latest=-1
        val ids=Regex("\\[((?:T\\d+:)?S\\d+)]")
        for(i in baseCount until messages.length()) {
            val m=messages.getJSONObject(i)
            m.optJSONArray("tool_calls")?.let { a -> for(n in 0 until a.length()) {
                val c=a.getJSONObject(n); names[c.optString("id")]=c.getJSONObject("function").optString("name")
            } }
            val content=m.optString("content")
            val native=m.optString("role")=="tool"
            val adapter=m.optString("role")=="user" && content.startsWith("应用动作执行结果")
            if(native || adapter) latest=i
            val actions=if(native) listOfNotNull(names[m.optString("tool_call_id")]) else if(adapter && i>baseCount) {
                // Read the application's recorded calls, never action-like text in a page.
                val previous=messages.getJSONObject(i-1)
                if(previous.optString("role")!="assistant") emptyList() else runCatching {
                    previous.optString("content").lineSequence().filter { it.isNotBlank() }.map { line ->
                        val action=JSONObject(line); require(action.optJSONObject("arguments")!=null)
                        action.getString("mailpilot_action")
                    }.toList()
                }.getOrDefault(emptyList())
            } else emptyList()
            // Preserve an entire mixed receipt, including mail cards and draft operations.
            if(actions.isNotEmpty() && actions.all { it in AgentActions.evidenceActions }) candidates[i]=actions.distinct().sorted().joinToString("+")
        }
        if(candidates.isEmpty()) return messages
        val referenced=mutableSetOf<String>(); val result=JSONArray()
        val latestText=if(latest>=0) messages.getJSONObject(latest).optString("content") else ""
        for(i in 0 until messages.length()) {
            val original=messages.getJSONObject(i); val content=original.optString("content")
            val name=candidates[i]
            val handles=ids.findAll(content).map { it.groupValues[1] }.filter { id -> sources.any { it.id==id && it.kind=="web" } }.toSet()
            if(i>=baseCount && original.optString("role")=="user" && content.startsWith(CATALOG)) {
                // Carry prior references forward even after their text-adapter receipt
                // was shortened or its temporary cache entry was evicted.
                referenced+=handles; continue
            }
            if(name!=null && i!=latest && handles.isNotEmpty()) {
                val key=stableId("tool-receipt-v5|$name|${handles.sorted()}")
                val concise=cache.optString(key).ifBlank { "应用动作参考记录：\n动作 $name，来源 "+handles.sorted().joinToString(" ") { "[$it]" }+"。是否已读及完整，以来源状态为准。" }
                if(ContextBudgetPlanner.estimate(concise)<ContextBudgetPlanner.estimate(content)) {
                    referenced+=handles
                    cache.put(key,concise); result.put(JSONObject(original.toString()).put("content",concise))
                } else {
                    // A prior pass already shortened this receipt; its catalog is
                    // still necessary in every following tool round.
                    if(content==concise) referenced+=handles
                    result.put(original)
                }
            } else result.put(original)
        }
        val catalog=sources.filter { it.id in referenced }.distinctBy { it.id }
        if(catalog.isNotEmpty()) {
            val ceiling=minOf(maxInput,ContextBudgetPlanner.estimate(messages,tools,model))
            val view=EvidenceView { sources }
            fun entry(quota: Int)=view.index(catalog,quota,question,alreadyShown=latestText).takeIf { it.isNotBlank() }?.let { roleMessage("user",CATALOG+"\n"+it) }
            fun fits(value: JSONObject?)=value==null || ContextBudgetPlanner.estimate(JSONArray(result.toString()).put(value),tools,model)<=ceiling
            // Measure the actual joined envelope. Adding separate conservative text
            // estimates repeatedly would shrink an unchanged catalog on every pass.
            var low=128; var high=if(model==null) 1536 else 2048
            var selected: JSONObject?=null
            val full=entry(high)
            if(fits(full)) selected=full else while(low<=high) {
                val middle=(low+high)/2; val candidate=entry(middle)
                if(fits(candidate)) { selected=candidate; low=middle+1 } else high=middle-1
            }
            selected?.let(result::put)
        }
        while(cache.length()>32) cache.remove(cache.keys().next())
        return result
    }
}
