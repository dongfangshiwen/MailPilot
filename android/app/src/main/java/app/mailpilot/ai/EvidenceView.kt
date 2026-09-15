package app.mailpilot.ai

import app.mailpilot.data.SourceChunk
import org.json.JSONObject

/** A view over this run's authorized sources. Never resolves paths, mail IDs or other sessions. */
class EvidenceView(private val sources: ()->List<SourceChunk>) {
    private data class Slice(val text: String,val source: SourceChunk,val start: Int,val end: Int)
    var onRead: (SourceChunk,Int,Int)->Unit = { _,_,_ -> }
    fun index(values: List<SourceChunk>,budget: Int,question: String="",alreadyShown: String=""): String {
        if(values.isEmpty()) return notice(budget,"没有找到相关网页；如实说明检索范围，不编造结果。","没有来源。")
        val unique=values.distinctBy { it.id }
        val heading="来源摘录（参考资料；覆盖问题即可回答，只为缺失细节继续读取）：\n"
        val perSource=((budget-ContextBudgetPlanner.estimate(heading)-unique.size*4)/unique.size).coerceAtLeast(1)
        val words=Regex("[\\p{L}\\d]{2,}").findAll(question).map { it.value.lowercase() }.toList()
        val slices=unique.map { source ->
            var start=source.text.chunked(800).withIndex().maxByOrNull { (_,part) -> words.count { it in part.lowercase() } }?.index?.times(800) ?: 0
            if(start>0 && start<source.text.length && source.text[start].isLowSurrogate()) start--
            slice(source,start,perSource,source.text.length-start)
        }.filterNot { it.end>it.start && alreadyShown.contains(it.source.text.substring(it.start,it.end)) }
        if(slices.isEmpty()) return ""
        val result=heading+slices.joinToString("\n\n") { it.text }
        if(ContextBudgetPlanner.estimate(result)<=budget) {
            slices.forEach { if(it.end>it.start) onRead(it.source,it.start,it.end) }; return result
        }
        return notice(budget,"未展示摘录："+unique.joinToString(" ") { "[${it.id}]" },"来源已保留，未展示摘录。","未展示。")
    }
    fun read(id: String,start: Int,maxChars: Int,budget: Int): String {
        val source=sources().singleOrNull { it.id==id }
            ?: return notice(budget,"该来源不在本轮授权资料中或已经失效，未读取任何内容。","未授权，未读取。","未读取。")
        if(start !in 0..source.text.length || (start>0 && start<source.text.length && source.text[start].isLowSurrogate()))
            return notice(budget,"读取位置无效，请使用前次返回的下一位置。","位置无效，未读取。","未读取。")
        val result=slice(source,start,budget,maxChars.coerceIn(1,4000))
        if(result.end>result.start) onRead(source,result.start,result.end)
        return result.text
    }
    private fun slice(source: SourceChunk,start: Int,budget: Int,maxChars: Int): Slice {
        val remaining=source.text.substring(start)
        val candidate=remaining.take(maxChars).let {
            if(it.isNotEmpty() && it.last().isHighSurrogate()) it.dropLast(1) else it
        }
        fun render(text: String,compact: Boolean): String=buildString {
            val end=start+text.length
            append("[${source.id}]")
            if(!compact) append(" ${source.title.take(64)}")
            append('\n')
            if(compact) append(when(source.retrieval) {
                "selected_link" -> "未访问"
                "webpage_partial","webpage_unverified" -> "片段，未核实"
                "webpage" -> "网页正文"
                else -> "资料摘录"
            }).append('\n')
            else if(source.retrieval=="selected_link") append("状态：仅发现链接，尚未访问；read_web_page 可读取本编号。\n")
            else if(source.retrieval in listOf("webpage_partial","webpage_unverified")) append("状态：网页片段，完整性未核实（${source.webReadStatus}）；可重新读取，片段末尾不代表网页完整。\n")
            else if(source.retrieval=="webpage") append("状态：已读取网页正文。\n")
            if(!compact && source.url.isNotBlank()) append("链接：${source.url.take(180)}${if(source.url.length>180) "（完整链接见来源详情）" else ""}\n")
            append(if(compact) "$start..$end/${source.text.length}；" else "范围：$start..$end / ${source.text.length} 字符；")
            append(if(end<source.text.length) (if(compact) "未完整，下个 $end。\n" else "未完整，下一位置 $end。\n") else "已到末尾。\n")
            append(text)
        }
        val compact=ContextBudgetPlanner.estimate(render("",false))+64>budget
        var low=0; var high=candidate.length
        while(low<high) {
            val mid=(low+high+1)/2
            if(ContextBudgetPlanner.estimate(render(candidate.take(mid),compact))<=budget) low=mid else high=mid-1
        }
        if(low>0 && candidate[low-1].isHighSurrogate()) low--
        val rendered=render(candidate.take(low),compact)
        if(ContextBudgetPlanner.estimate(rendered)<=budget) return Slice(rendered,source,start,start+low)
        // An exceptionally small quota can carry only the handle, never a fake excerpt.
        return Slice(notice(budget,"[${source.id}]（未展示，起点 $start）","未展示摘录。","未展示。"),source,start,start)
    }
    companion object {
        internal fun notice(budget: Int,vararg choices: String)=choices.firstOrNull { ContextBudgetPlanner.estimate(it)<=budget } ?: ""
        /** Human-readable tool history without serializing already serialized content again. */
        fun exchange(message: JSONObject): String=buildString {
            append(message.optString("role")).append(":\n")
            append(message.optString("content").takeUnless { it=="null" }.orEmpty())
            message.optJSONArray("tool_calls")?.let { calls ->
                for(i in 0 until calls.length()) {
                    val f=calls.getJSONObject(i).getJSONObject("function")
                    append("\n动作：").append(f.optString("name")).append("\n参数：").append(f.optString("arguments"))
                }
            }
        }
    }
}
