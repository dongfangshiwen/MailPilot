package app.mailpilot.mail

import app.mailpilot.data.*
import jakarta.mail.internet.InternetAddress
import org.json.JSONObject

data class DraftReviewState(val code: String,val label: String,val action: String="",val canSend: Boolean=false) {
    fun fields()=mapOf("code" to code,"label" to label,"action" to action,"canSend" to canSend)
    companion object {
        fun content(d: Draft): DraftReviewState {
            if(d.status=="SENDING") return DraftReviewState("sending","正在发送，请勿重复操作")
            if(d.status=="UNKNOWN") return DraftReviewState("unknown","发送结果待核实","edit")
            if(d.status=="SENT") return DraftReviewState("sent","已提交发送","edit")
            if(d.to.isBlank()) return DraftReviewState("recipient","待补充收件人","recipient")
            if(runCatching { listOf(d.to,d.cc,d.bcc).filter { it.isNotBlank() }.forEach { validateAddresses(it) } }.isFailure)
                return DraftReviewState("invalid_address","请检查收件人、抄送或密送地址","edit")
            if(d.subject.contains('\r') || d.subject.contains('\n')) return DraftReviewState("subject","主题不能包含换行","edit")
            if(d.body.isBlank()) return DraftReviewState("body","请补充邮件正文","edit")
            if(JsonCodec.files(d.filesJson).any { !java.io.File(it.path).isFile || java.io.File(it.path).length()>MAX_ATTACHMENT_BYTES } || JsonCodec.files(d.filesJson).sumOf { java.io.File(it.path).length() }>MAX_ATTACHMENT_BYTES) return DraftReviewState("attachment","发送附件已失效，请重新添加","edit")
            return DraftReviewState("ready","等待你确认","send",true)
        }
        fun validateAddresses(value: String) {
            val addresses=InternetAddress.parse(value,true)
            require(addresses.isNotEmpty()) { "请输入有效邮箱地址" }
            addresses.forEach { it.validate(); require(!it.isGroup && it.address.contains('@')) { "请输入完整邮箱地址" } }
        }
        fun forEntry(entry: ChatEntry,lastId: String?,drafts: List<Draft>,accounts: List<MailAccount>): DraftReviewState {
            val preview=runCatching { JSONObject(entry.draftPreviewJson) }.getOrNull() ?: return DraftReviewState("none","")
            val current=drafts.firstOrNull { it.id==entry.draftId } ?: return DraftReviewState("deleted","草稿已删除")
            if(current.status in listOf("SENDING","UNKNOWN","SENT")) return content(current)
            if(current.revision!=preview.optLong("revision") || lastId!=entry.id || accounts.firstOrNull { it.id==current.accountId }?.email!=preview.optString("senderEmail"))
                return DraftReviewState("outdated","此确认已失效，请核对最新版本","latest")
            return content(current)
        }
    }
}
