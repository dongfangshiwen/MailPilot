package app.mailpilot.ai

import app.mailpilot.data.SourceChunk
import okhttp3.HttpUrl.Companion.toHttpUrlOrNull
import org.jsoup.Jsoup

/** Offline extraction from the current selection. Discovering a link never fetches it. */
object SelectedLinks {
    const val MAX_LINKS=64
    private val plainUrl=Regex("""https?://[^\s\p{Z}<>"'`。，；！？、【】《》]+""",RegexOption.IGNORE_CASE)
    data class Link(val url: String,val label: String)

    fun extract(text: String,html: String=""): List<Link> {
        val found=linkedMapOf<String,Link>()
        fun add(raw: String,label: String) {
            if(raw.length>8192) return
            val url=raw.trim().toHttpUrlOrNull() ?: return
            if(url.username.isNotEmpty() || url.password.isNotEmpty()) return
            val normalized=url.toString()
            found.putIfAbsent(normalized,Link(normalized,label.trim().take(120).ifBlank { url.host }))
        }
        // href is authoritative even when the visible anchor disguises a different address.
        val displayOnly=mutableSetOf<String>()
        if(html.isNotBlank()) Jsoup.parse(html).select("a[href]").forEach { a ->
            add(a.attr("href"),a.text())
            val displayed=a.text().trim().toHttpUrlOrNull()?.toString()
            if(displayed!=null && displayed!=a.attr("href").trim().toHttpUrlOrNull()?.toString()) displayOnly+=displayed
        }
        plainUrl.findAll(text).forEach { match ->
            var url=match.value.trimEnd('.',',',';',':','!','?','。','，','；','：','！','？','、','】','》')
            for((left,right) in listOf('(' to ')','[' to ']','（' to '）')) {
                while(url.endsWith(right) && url.count { it==right }>url.count { it==left }) url=url.dropLast(1)
            }
            if(url.toHttpUrlOrNull()?.toString() !in displayOnly) add(url,"")
        }
        return found.values.toList()
    }

    fun sources(parent: SourceChunk,links: List<Link>): List<SourceChunk> = links.map { link ->
        SourceChunk(messageId=parent.messageId,attachmentId=parent.attachmentId,title=link.label,
            location="${parent.title} · 资料中的链接（尚未访问）",kind="web",url=link.url,retrieval="selected_link",
            text="所选资料中的链接，尚未读取网页。来源：${parent.title}。链接文字：${link.label}。用户要求查看时使用 read_web_page 读取本来源编号；不要把链接或访问参数发给搜索服务。")
    }
    fun selected(source: SourceChunk)=source.kind=="web" && (source.messageId.isNotBlank() || source.attachmentId.isNotBlank())
    fun identity(source: SourceChunk)=listOf(source.messageId,source.attachmentId,source.url)
}
