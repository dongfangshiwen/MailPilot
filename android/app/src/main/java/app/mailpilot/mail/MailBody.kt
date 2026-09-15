package app.mailpilot.mail

import org.commonmark.ext.gfm.strikethrough.StrikethroughExtension
import org.commonmark.ext.gfm.tables.TablesExtension
import org.commonmark.node.*
import org.commonmark.parser.Parser
import org.commonmark.renderer.text.CoreTextContentNodeRenderer
import org.commonmark.renderer.text.TextContentRenderer
import org.commonmark.renderer.text.LineBreakRendering
import org.jsoup.Jsoup

/** Convert only generated/imported Markdown, before the user reviews the draft.
 * Manual edits and the SMTP payload are never silently rewritten. */
object MailBody {
    private val extensions = listOf(TablesExtension.create(), StrikethroughExtension.create())
    private val parser = Parser.builder().extensions(extensions).build()
    private val renderer = TextContentRenderer.builder().extensions(extensions)
        .lineBreakRendering(LineBreakRendering.SEPARATE_BLOCKS)
        .nodeRendererFactory { context -> object : CoreTextContentNodeRenderer(context) {
            override fun visit(code: Code) { context.writer.write(code.literal) }
            override fun visit(line: ThematicBreak) { context.writer.block() }
            override fun visit(html: HtmlInline) {
                if (html.literal.matches(Regex("(?i)<br\\s*/?>"))) context.writer.line()
                // Raw tags are not email text; no HTML is executed or fetched.
            }
            override fun visit(html: HtmlBlock) {
                val doc = Jsoup.parse(html.literal)
                doc.select("script,style,iframe,object").remove()
                context.writer.write(doc.body().wholeText())
                context.writer.block()
            }
        } }.build()

    fun generated(markdown: String): String {
        val clean=markdown.replace(Regex("\\[(?:T\\d+:)?S\\d+]"),"")
            .lineSequence().filterNot { it.trim().matches(Regex("\\[(?:您的|你的|姓名|团队|Your |your ).*]")) }.joinToString("\n")
        return fromMarkdown(clean).trim()
    }
    fun fromMarkdown(markdown: String): String {
        require(markdown.length <= 100000) { "草稿正文不能超过 100000 字符" }
        return renderer.render(parser.parse(markdown)).trimEnd()
    }
}
