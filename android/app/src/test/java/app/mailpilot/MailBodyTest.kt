package app.mailpilot

import app.mailpilot.mail.MailBody
import org.junit.Assert.*
import org.junit.Test

class MailBodyTest {
    @Test fun markdownBecomesReadableMailWithoutLosingData() {
        val text=MailBody.fromMarkdown("""
            # 项目确认

            您好，**预算**为 100 元。

            1. 核对 _金额_
            2. 回复安排

            | 项目 | 金额 |
            | --- | --- |
            | 设计 | 100 |

            [查看方案](https://example.test/plan)

            ```text
            invoice_id = A_123
            ```
        """.trimIndent())
        listOf("项目确认","预算","100 元","1. 核对 金额","2. 回复安排","设计","https://example.test/plan","invoice_id = A_123").forEach { assertTrue("Missing $it in $text",text.contains(it)) }
        listOf("# 项目","**","_金额_","```","| ---").forEach { assertFalse(text.contains(it)) }
    }
    @Test fun plainMailAndEscapedPunctuationSurvive() {
        assertEquals("你好：\n费用为 100 元。\n\n联系 first_last@example.test。",MailBody.fromMarkdown("你好：\n费用为 100 元。\n\n联系 first_last@example.test。"))
        assertEquals("*literal* and a_b_c",MailBody.fromMarkdown("\\*literal\\* and a_b_c"))
    }
    @Test fun rawHtmlCannotBecomeActiveMailMarkup() {
        val text=MailBody.fromMarkdown("<div>您好<br>正文<script>alert(1)</script></div>")
        assertTrue(text.contains("您好")); assertTrue(text.contains("正文"))
        assertFalse(text.contains("<div>")); assertFalse(text.contains("alert"))
    }
    @Test fun oversizeDraftHasExplicitError() {
        assertTrue(runCatching { MailBody.fromMarkdown("a".repeat(100001)) }.exceptionOrNull() is IllegalArgumentException)
    }
}
