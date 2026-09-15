package app.mailpilot.ai

import app.mailpilot.data.MailMessage
import jakarta.mail.internet.InternetAddress

object DraftRecipients {
    fun explicitTarget(question: String): String = Regex("(?:发送给|发给|写给|收件人(?:改为|是|为|[：:])|(?:send|write|reply)\\s+to)\\s*([A-Za-z0-9._%+\\-]+@[A-Za-z0-9.\\-]+\\.[A-Za-z]{2,})",RegexOption.IGNORE_CASE)
        .find(question)?.groupValues?.get(1).orEmpty()
    fun sender(messages: List<MailMessage>): String = messages.distinctBy { it.id }.singleOrNull()?.senderAddress
        ?.let { address -> runCatching { InternetAddress.parse(address,true).single().also { it.validate() }.address }.getOrDefault("") }.orEmpty()
    fun allowed(proposed: String, explicit: String, fallback: String=""): String {
        if(proposed.isBlank()) return fallback
        val addresses=runCatching { InternetAddress.parse(proposed,true).onEach { it.validate() }.map { it.address } }.getOrDefault(emptyList())
        val supplied=Regex("[A-Za-z0-9._%+\\-]+@[A-Za-z0-9.\\-]+\\.[A-Za-z]{2,}").findAll(explicit).map { it.value.lowercase() }.toSet()
        return if(addresses.isNotEmpty() && addresses.all { it.lowercase() in supplied }) proposed else fallback
    }
}
