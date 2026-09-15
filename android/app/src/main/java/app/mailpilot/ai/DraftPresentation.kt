package app.mailpilot.ai

import app.mailpilot.data.ChatEntry
import org.json.JSONObject

/** Internal draft records belong to the review card, never a chat code block. */
object DraftPresentation {
    private val keys = Regex("\"(?:draft_id|senderEmail|attachment_names|revision)\"\\s*:")
    fun isRecord(value: JSONObject): Boolean = value.has("subject") && value.has("body") &&
        (value.has("draft_id") || value.has("senderEmail") || (value.has("to") && value.has("revision")))

    fun records(text: String): List<JSONObject> {
        val result=mutableListOf<JSONObject>(); var start=-1; var depth=0; var quoted=false; var escaped=false
        text.forEachIndexed { index,c ->
            if(start<0) { if(c=='{') { start=index; depth=1 }; return@forEachIndexed }
            if(escaped) { escaped=false; return@forEachIndexed }
            if(quoted && c=='\\') { escaped=true; return@forEachIndexed }
            if(c=='"') quoted=!quoted
            if(!quoted) {
                if(c=='{') depth++
                if(c=='}' && --depth==0) {
                    runCatching { JSONObject(text.substring(start,index+1)) }.getOrNull()?.takeIf(::isRecord)?.let(result::add)
                    start=-1
                }
            }
        }
        return result
    }
    fun containsRecord(text: String)=records(text).isNotEmpty() || (keys.containsMatchIn(text) && text.contains("\"body\""))
    // Hold a possible JSON object until it can be classified; normal code answers
    // are released unchanged on completion. No provider-specific formatting.
    fun streaming(text: String): String {
        val objectStart=text.indexOf('{'); val fence=text.indexOf("```")
        if(objectStart<0 && fence<0) return text
        return text.take(listOf(objectStart,fence).filter { it>=0 }.min()).trimEnd()
    }
    fun readable(text: String): String {
        val visible=InlineToolCalls.readable(text)
        if(visible!=text) return visible
        val record=records(text).firstOrNull() ?: return if(containsRecord(text)) "这条历史回答包含内部草稿数据，请重新查看最新邮件卡片。" else text
        return buildString {
            append("邮件草稿（历史参考）\n\n")
            record.optString("to").takeIf { it.isNotBlank() }?.let { append("收件人：$it\n") }
            append("主题：${record.optString("subject")}\n\n${record.optString("body")}\n\n")
            append("请查看最新邮件确认卡片后再发送。")
        }
    }
    fun reference(entry: ChatEntry): String {
        if(entry.role!="assistant") return entry.text
        val p=runCatching { JSONObject(entry.draftPreviewJson) }.getOrNull() ?: return readable(entry.text)
        return buildString {
            append(readable(entry.text)); append("\n历史邮件草稿（仅供理解内容）：\n")
            append("草稿定位标识：${entry.draftId}\n")
            for((key,label) in listOf("senderEmail" to "发件邮箱","to" to "收件人","cc" to "抄送","bcc" to "密送","subject" to "主题","body" to "正文")) {
                p.optString(key).takeUnless { it.isBlank() || it=="null" }?.let { append("$label：$it\n") }
            }
            val files=p.optJSONArray("files")
            if(files!=null && files.length()>0) append("附件名称："+(0 until files.length()).joinToString("、") { files.getJSONObject(it).optString("name") })
        }
    }
}
