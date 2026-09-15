package app.mailpilot.data

import androidx.room.Entity
import androidx.room.ColumnInfo
import androidx.room.Index
import androidx.room.PrimaryKey
import org.json.JSONArray
import org.json.JSONObject
import java.security.MessageDigest
import java.util.UUID

fun newId(): String = UUID.randomUUID().toString()
const val DEFAULT_MODEL_OUTPUT_TOKENS = 4096
fun stableId(value: String): String = MessageDigest.getInstance("SHA-256").digest(value.toByteArray()).joinToString("") { "%02x".format(it) }

@Entity(tableName = "accounts")
data class MailAccount(
    @PrimaryKey val id: String = newId(), val label: String = "", val email: String = "",
    val displayName: String = "", val username: String = "", val passwordCipher: String = "",
    val imapHost: String = "imap.qq.com", val imapPort: Int = 993, val imapSecurity: String = "SSL",
    val smtpHost: String = "smtp.qq.com", val smtpPort: Int = 465, val smtpSecurity: String = "SSL"
)

@Entity(tableName = "models")
data class ModelProfile(
    @PrimaryKey val id: String = newId(), val label: String = "", val baseUrl: String = "",
    val apiKeyCipher: String = "", val model: String = "", val contextTokens: Int = 32768,
    val outputTokens: Int = DEFAULT_MODEL_OUTPUT_TOKENS, val textVerified: Boolean = false, val supportsTools: Boolean = false,
    val supportsVision: Boolean = false, val supportsStreaming: Boolean = false,
    val tokenParameter: String = "max_tokens", val testReport: String = "尚未测试",
    @ColumnInfo(defaultValue="'auto'") val provider: String = "auto",
    @ColumnInfo(defaultValue="'default'") val thinkingMode: String = "default",
    @ColumnInfo(defaultValue="''") val reasoningEffort: String = "",
    @ColumnInfo(defaultValue="0") val thinkingBudget: Int = 0,
    @ColumnInfo(defaultValue="''") val credentialVersion: String = "",
    @ColumnInfo(defaultValue="''") val diagnosticIdentity: String = "",
    @ColumnInfo(defaultValue="'{}'") val diagnosticsJson: String = "{}"
)

@Entity(tableName = "messages", indices = [Index(value = ["accountId", "folder", "uidValidity", "uid"], unique = true)])
data class MailMessage(
    @PrimaryKey val id: String, val accountId: String, val folder: String, val uidValidity: Long,
    val uid: Long, val subject: String, val sender: String, val senderAddress: String,
    val to: String = "", val cc: String = "", val replyTo: String = "", val sentAt: Long,
    val preview: String = "", val body: String = "", val html: String = "",
    val unread: Boolean = true, val attachmentCount: Int = 0, val internetMessageId: String = "",
    val references: String = "",
    @ColumnInfo(defaultValue="''") val bodyError: String = "",
    @ColumnInfo(defaultValue="'READY'") val bodyState: String = "READY"
)

@Entity(tableName="mail_folders", primaryKeys=["accountId","name"], foreignKeys=[androidx.room.ForeignKey(entity=MailAccount::class,parentColumns=["id"],childColumns=["accountId"],onDelete=androidx.room.ForeignKey.CASCADE)])
data class MailFolder(val accountId: String, val name: String)

// Persist only the date/UID index; bodies are downloaded for the visible page.
@Entity(tableName="mail_index", primaryKeys=["accountId","folder","validity","uid"], foreignKeys=[androidx.room.ForeignKey(entity=MailAccount::class,parentColumns=["id"],childColumns=["accountId"],onDelete=androidx.room.ForeignKey.CASCADE)])
data class MailIndex(val accountId: String,val folder: String,val validity: Long,val uid: Long,val sentAt: Long)

@Entity(tableName="sync_cursors",primaryKeys=["accountId","folder"],foreignKeys=[androidx.room.ForeignKey(entity=MailAccount::class,parentColumns=["id"],childColumns=["accountId"],onDelete=androidx.room.ForeignKey.CASCADE)])
data class SyncCursor(val accountId: String,val folder: String,val validity: Long,val lastUid: Long,val updatedAt: Long=System.currentTimeMillis())

@Entity(tableName="conversation_turns",indices=[Index("conversationId")],foreignKeys=[androidx.room.ForeignKey(entity=Conversation::class,parentColumns=["id"],childColumns=["conversationId"],onDelete=androidx.room.ForeignKey.CASCADE)])
data class TurnSnapshot(@PrimaryKey val id: String,val conversationId: String,val accountId: String,val folder: String,val selectionJson: String,val number: Int, @ColumnInfo(defaultValue="'{}'") val optionsJson: String="{}", @ColumnInfo(defaultValue="'[]'") val localJson: String="[]", @ColumnInfo(defaultValue="'{}'") val requestJson: String="{}")

@Entity(tableName = "attachments", indices = [Index("messageId")])
data class Attachment(
    @PrimaryKey val id: String, val messageId: String, val name: String, val mimeType: String,
    val size: Long, val partPath: String, val localPath: String = ""
)

@Entity(tableName = "drafts")
data class Draft(
    @PrimaryKey val id: String = newId(), val accountId: String = "", val to: String = "", val cc: String = "",
    val bcc: String = "", val subject: String = "", val body: String = "", val filesJson: String = "[]",
    val inReplyTo: String = "", val references: String = "", val revision: Long = 0,
    val status: String = "DRAFT", val error: String = "", val updatedAt: Long = System.currentTimeMillis()
)

@Entity(tableName = "send_attempts", indices = [Index(value = ["draftId", "revision"], unique = true)])
data class SendAttempt(
    @PrimaryKey val id: String = newId(), val draftId: String, val revision: Long,
    val messageId: String, val status: String = "PREPARING", val detail: String = "",
    val createdAt: Long = System.currentTimeMillis()
)

@Entity(tableName = "conversations", indices=[Index(value=["accountId","pinnedAt","lastActivityAt"])])
data class Conversation(@PrimaryKey val id: String = newId(), val title: String = "新的对话", val selectionJson: String = "[]", val createdAt: Long = System.currentTimeMillis(), val accountId: String = "", val folder: String = "INBOX",
    @ColumnInfo(defaultValue="''") val contextSummary: String = "",
    @ColumnInfo(defaultValue="''") val summaryThroughId: String = "",
    @ColumnInfo(defaultValue="0") val summarizedEntries: Int = 0,
    @ColumnInfo(defaultValue="0") val lastActivityAt: Long = createdAt,
    @ColumnInfo(defaultValue="0") val pinnedAt: Long = 0)

data class ConversationHeader(val id: String,val title: String,val accountId: String,val createdAt: Long,val lastActivityAt: Long,val pinnedAt: Long)

@Entity(tableName="visual_evidence",indices=[Index(value=["conversationId","accountId"])],foreignKeys=[androidx.room.ForeignKey(entity=Conversation::class,parentColumns=["id"],childColumns=["conversationId"],onDelete=androidx.room.ForeignKey.CASCADE)])
data class VisualEvidence(@PrimaryKey val id: String,val conversationId: String,val accountId: String,
    val assetsJson: String,val sourcesJson: String,val question: String,val text: String,val model: String,
    val kind: String,val responseId: String,val createdAt: Long=System.currentTimeMillis())

@Entity(tableName="processed_materials",indices=[Index("conversationId")],foreignKeys=[androidx.room.ForeignKey(entity=Conversation::class,parentColumns=["id"],childColumns=["conversationId"],onDelete=androidx.room.ForeignKey.CASCADE)])
data class ProcessedMaterial(@PrimaryKey val id: String,val conversationId: String,val accountId: String,
    val attachmentId: String,val fingerprint: String,val sourcesJson: String)

@Entity(tableName = "chat_entries", indices = [Index("conversationId")])
data class ChatEntry(@PrimaryKey val id: String = newId(), val conversationId: String, val role: String,
    val text: String, val sourcesJson: String = "[]", val createdAt: Long = System.currentTimeMillis(),
    @ColumnInfo(defaultValue="''") val reasoningText: String="",
    @ColumnInfo(defaultValue="0") val reasoningMillis: Long=0,
    @ColumnInfo(defaultValue="''") val reasoningState: String="",
    @ColumnInfo(defaultValue="0") val reasoningTruncated: Boolean=false,
    @ColumnInfo(defaultValue="''") val draftId: String="",
    @ColumnInfo(defaultValue="''") val draftPreviewJson: String="",
    @ColumnInfo(defaultValue="''") val action: String="",
    @ColumnInfo(defaultValue="''") val targetAnswerId: String="",
    @ColumnInfo(defaultValue="'complete'") val resultStatus: String="complete",
    @ColumnInfo(defaultValue="'{}'") val failureJson: String="{}",
    @ColumnInfo(defaultValue="''") val visionModel: String="")

data class DraftFile(val path: String, val name: String, val mime: String = "application/octet-stream")
data class Selection(val messageId: String, val attachmentIds: List<String> = emptyList(), val pdfPages: Map<String, List<Int>> = emptyMap(), val defaultPdfIds: List<String> = emptyList())
data class SourceChunk(val id: String = newId(), val messageId: String, val attachmentId: String = "", val title: String,
    val location: String, val text: String = "", val imagePath: String = "", val isModelObservation: Boolean = false, val kind: String="mail", val url: String="",
    val assetKey: String="",val imageWidth: Int=0,val imageHeight: Int=0,val retrieval: String="",val contentKey: String="",val webReadVersion: Int=0,val webReadStatus: String="")
data class MailQuery(val keyword: String = "", val after: Long? = null, val before: Long? = null,
    val unreadOnly: Boolean = false, val offset: Int = 0, val limit: Int = 10)

object JsonCodec {
    fun files(value: List<DraftFile>): String = JSONArray().apply { value.forEach { put(JSONObject().put("path", it.path).put("name", it.name).put("mime", it.mime)) } }.toString()
    fun files(value: String): List<DraftFile> = JSONArray(value).let { a -> (0 until a.length()).map { a.getJSONObject(it).let { o -> DraftFile(o.getString("path"), o.getString("name"), o.optString("mime", "application/octet-stream")) } } }
    fun sources(value: List<SourceChunk>): String = JSONArray().apply { value.forEach { s -> put(JSONObject().put("id", s.id).put("messageId", s.messageId).put("attachmentId", s.attachmentId).put("title", s.title).put("location", s.location).put("text", if(s.contentKey.isNotBlank()) s.text.take(4000) else s.text).put("imagePath", s.imagePath).put("isModelObservation", s.isModelObservation).put("kind",s.kind).put("url",s.url).put("assetKey",s.assetKey).put("imageWidth",s.imageWidth).put("imageHeight",s.imageHeight).put("retrieval",s.retrieval).put("contentKey",s.contentKey).put("webReadVersion",s.webReadVersion).put("webReadStatus",s.webReadStatus)) } }.toString()
    fun sources(value: String): List<SourceChunk> = JSONArray(value).let { a -> (0 until a.length()).map { a.getJSONObject(it).let { o -> SourceChunk(o.getString("id"), o.getString("messageId"), o.optString("attachmentId"), o.getString("title"), o.getString("location"), o.optString("text"), o.optString("imagePath"), o.optBoolean("isModelObservation"),o.optString("kind","mail"),o.optString("url"),o.optString("assetKey"),o.optInt("imageWidth"),o.optInt("imageHeight"),o.optString("retrieval"),o.optString("contentKey"),o.optInt("webReadVersion"),o.optString("webReadStatus")) } } }
    fun selections(value: List<Selection>): String = JSONArray().apply { value.forEach { s -> put(JSONObject().put("messageId", s.messageId).put("attachmentIds", JSONArray(s.attachmentIds)).put("defaultPdfIds",JSONArray(s.defaultPdfIds)).put("pdfPages", JSONObject().apply { s.pdfPages.forEach { (id,pages) -> put(id,JSONArray(pages)) } })) } }.toString()
    fun selections(value: String): List<Selection> = JSONArray(value).let { a -> (0 until a.length()).map { a.getJSONObject(it).let { o -> val p=o.optJSONObject("pdfPages") ?: JSONObject(); val defaults=o.optJSONArray("defaultPdfIds") ?: JSONArray(); Selection(o.getString("messageId"), o.getJSONArray("attachmentIds").let { ids -> (0 until ids.length()).map { ids.getString(it) } }, p.keys().asSequence().associateWith { key -> p.getJSONArray(key).let { pages -> (0 until pages.length()).map { pages.getInt(it) } } },(0 until defaults.length()).map { defaults.getString(it) }) } } }
}
