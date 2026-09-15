package app.mailpilot.data

/** UI preference only: never rewrites model instructions, email or speech settings. */
object AppLanguage {
    val supported = setOf("zh", "zh_Hant", "en", "ja", "ko", "es", "fr", "de")
    fun normalize(code: String?): String = code?.takeIf { it in supported } ?: "zh"
}
