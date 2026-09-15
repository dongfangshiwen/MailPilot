package app.mailpilot.services

import org.jsoup.Jsoup
import org.jsoup.nodes.Element

/** Content assessment uses document state; character count does not prove completion. */
internal object WebContentPolicy {
    data class Assessment(val page: WebPage,val scripted: Boolean,val busy: Boolean)
    fun analyze(html: String): Assessment {
        val doc=Jsoup.parse(html)
        fun visible(element: Element)= (listOf(element)+element.parents()).none {
            it.hasAttr("hidden") || it.attr("aria-hidden").equals("true",true) ||
                Regex("(?:display\\s*:\\s*none|visibility\\s*:\\s*hidden)",RegexOption.IGNORE_CASE).containsMatchIn(it.attr("style"))
        }
        if(doc.select("input[type=password]").any(::visible)) return Assessment(WebPage(status="login_required"),false,false)
        val scripted=doc.select("script").any { it.attr("type").lowercase() in setOf("","module","text/javascript","application/javascript") }
        val busy=doc.select("[aria-busy=true],[role=progressbar],progress").any(::visible)
        doc.select("[style]").filterNot(::visible).forEach { it.remove() }
        doc.select("script,style,noscript,nav,footer,header,form,svg,[hidden],[aria-hidden=true]").remove()
        val body=doc.selectFirst("main,article,[role=main]") ?: doc.body()
        val text=body.wholeText().trim()
        body.select("button,input,select,textarea,[role=button],[role=status],[role=progressbar],progress").remove()
        val content=body.text().isNotBlank()
        val status=when {
            busy || scripted -> "needs_render"
            text.isBlank() -> "empty_or_dynamic"
            !content -> "limited_content"
            else -> "complete"
        }
        return Assessment(WebPage(text,status),scripted,busy)
    }
}
