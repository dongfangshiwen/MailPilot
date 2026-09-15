package app.mailpilot.ai

object DraftIntent {
    fun language(question: String,existing: String="",original: String=""): String {
        if(Regex("(?:用|使用|改成|写成|换成|译成).{0,5}(?:英文|英语)|英文邮件|(?:in|into|use)\\s+English",RegexOption.IGNORE_CASE).containsMatchIn(question)) return "en"
        if(Regex("(?:用|使用|改成|写成|换成|译成).{0,5}(?:中文|汉语)|中文邮件|(?:in|into|use)\\s+Chinese",RegexOption.IGNORE_CASE).containsMatchIn(question)) return "zh"
        return detect(existing.ifBlank { original.ifBlank { question } })
    }
    fun detect(text: String): String {
        val main=text.lineSequence().takeWhile { !Regex("^-{2,}|^On .+wrote:|^发件人[：:]|^Sent from|^此致|^Best regards|^Regards[,]?",RegexOption.IGNORE_CASE).containsMatchIn(it.trim()) }
            .filterNot { it.trimStart().startsWith('>') }.joinToString("\n")
            .replace(Regex("https?://\\S+|[\\w.+-]+@[\\w.-]+"),"")
        val chinese=main.count { it in '\u4e00'..'\u9fff' }
        val words=Regex("[A-Za-z]{2,}").findAll(main).count()
        return when { chinese>=4 && chinese>words*2 -> "zh"; words>=3 && words>chinese -> "en"; else -> "auto" }
    }
    fun instruction(language: String)="聊天解释使用简体中文；正式邮件语言："+when(language) { "en" -> "英文，主题与正文均用自然英语。"; "zh" -> "中文。"; else -> "按主要内容判断中文或英文；语言确实不明确时先简短询问。" }+
        "忽略签名、引用历史和邮箱域名，不根据地址猜测国籍。用户明确要求优先；回复跟随原邮件正文，新邮件跟随用户内容，重拟保留原草稿语言。"
}
