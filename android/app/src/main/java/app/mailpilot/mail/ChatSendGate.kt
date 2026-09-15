package app.mailpilot.mail

import androidx.room.withTransaction
import app.mailpilot.BridgeCodec
import app.mailpilot.data.*
import jakarta.mail.internet.InternetAddress
import org.json.JSONObject

/** Only an explicit user action enters this gate. It is never exposed as a model tool. */
class ChatSendGate(private val db: MailDatabase,private val mail: MailRepository) {
    private val dao=db.dao()
    suspend fun snapshot(draft: Draft): String {
        val account=requireNotNull(dao.account(draft.accountId)) { "发件邮箱已删除" }
        return JSONObject(BridgeCodec.draft(draft)+( "senderEmail" to account.email)).toString()
    }
    suspend fun send(conversation: String,entryId: String,confirmation: String="确认发送"): Draft {
        val draft=db.withTransaction {
            val entry=dao.history(conversation).lastOrNull()
            require(entry?.id==entryId && entry.role=="assistant" && entry.draftPreviewJson.isNotBlank()) { "请先在聊天中重新查看最新的邮件确认卡片" }
            val preview=JSONObject(entry.draftPreviewJson)
            val current=requireNotNull(dao.draft(entry.draftId)) { "草稿已删除" }
            require(current.revision==preview.getLong("revision") && current.status in listOf("DRAFT","FAILED")) { "草稿已修改或已经发送，请重新查看确认内容" }
            require(dao.account(current.accountId)?.email==preview.optString("senderEmail")) { "发件邮箱已修改，请重新确认" }
            val review=DraftReviewState.content(current); require(review.canSend) { review.label }
            require(current.to.isNotBlank()) { "请先补全目标收件人邮箱，再确认发送" }
            for(address in listOf(current.to,current.cc,current.bcc).filter { it.isNotBlank() }) InternetAddress.parse(address,true).forEach { it.validate() }
            require(current.body.isNotBlank()) { "请先填写邮件正文" }
            val submitted=ChatEntry(conversationId=conversation,role="user",text=confirmation)
            dao.putEntry(submitted)
            dao.touchConversation(conversation,submitted.createdAt)
            current
        }
        return mail.send(draft.id,draft.revision)
    }
    companion object {
        fun isConfirmation(text: String): Boolean = text.trim().trimEnd('。','！','!','.').trim() in setOf("确认发送","同意发送","确认并发送","确认","同意","发送吧","可以发送")
    }
}
