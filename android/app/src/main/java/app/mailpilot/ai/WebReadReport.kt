package app.mailpilot.ai

import app.mailpilot.data.SourceChunk

internal data class WebReadView(val id: String,val source: SourceChunk?,val status: String)

/** Budget the final tool text, including every status, handle and heading. */
internal object WebReadReport {
    fun render(reads: List<WebReadView>,view: EvidenceView,budget: Int,question: String): String {
        val sources=reads.mapNotNull { it.source }.distinctBy { it.id }
        val warnings=reads.filter { it.status !in listOf("complete","cached") }.groupBy { it.status }
            .map { (status,items) -> items.joinToString(" ") { "[${it.id}]" }+" "+unavailable(status) }.joinToString("\n")
        val prefix=warnings+if(warnings.isNotBlank() && sources.isNotEmpty()) "\n\n" else ""
        val remaining=budget-ContextBudgetPlanner.estimate(prefix)
        if(sources.isEmpty() && warnings.isNotEmpty() && remaining>=0) return warnings
        if(sources.isNotEmpty() && remaining>=128) return prefix+view.index(sources,remaining,question)
        val statuses=reads.joinToString("\n") {
            val label=when { it.status=="unauthorized" -> "未授权"; it.source==null -> "未读"; it.status in listOf("complete","cached") -> "已读"; else -> "片段" }
            "[${it.id}] $label"
        }
        return EvidenceView.notice(budget,"未展示摘录：\n"+statuses,"未完整展示结果，资料及状态保留。","未展示摘录。","未展示。")
    }
    private fun unavailable(status: String): String=when(status) {
        "unauthorized" -> "来源不在本轮授权资料中，未读取。"
        "empty" -> "网页未返回可读文字，未确认正文内容。"
        "login_required","http_401","http_403" -> "网页要求登录或拒绝访问；请在浏览器中打开原链接查看。"
        "empty_or_dynamic" -> "网页没有可提取的正文，可能需要 JavaScript 或验证码；请在浏览器中查看。"
        "limited_content" -> "页面已打开，但尚未确认正文完整，可能仍是初始内容、操作入口或图片／文件预览。以下片段不代表已读取图片或文件；缺失细节请在浏览器查看，或将文件添加为资料。"
        "interaction_required" -> "页面需要提交请求或交互才能继续；自动读取未执行这些操作，请在浏览器中查看。"
        "loading_incomplete" -> "页面仍在加载，正文未确认完整；以下内容仅供参考，可稍后重新读取。"
        "resource_failed" -> "页面部分资源加载失败，正文未确认完整；可稍后重试或在浏览器查看。"
        "resource_limit" -> "页面资源达到读取上限，正文未确认完整；请在浏览器查看。"
        "renderer_failed" -> "动态页面加载失败，未把浏览器错误页当作正文；请在浏览器中查看。"
        "http_406" -> "网站拒绝了当前文档请求（HTTP 406），尚未获取正文；可在浏览器中查看原链接。"
        "unsupported_type" -> "链接返回文件或不支持的内容类型；请下载后作为本轮资料添加，尚未读取文件内容。"
        "too_large" -> "网页超过 2 MiB 读取上限；请缩小资料或下载后添加。"
        "page_budget" -> "已达到本阶段最多八页的读取上限，可继续检索或缩小范围。"
        "blocked_target" -> "地址或重定向目标不符合公开网页访问规则，未继续连接。"
        "timeout" -> "读取网页超时，可稍后重试。"
        "connection_failed" -> "网页连接失败，可稍后重试或在浏览器中查看。"
        else -> "网页未读取（$status），可在浏览器中查看原链接。"
    }
}
