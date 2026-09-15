package app.mailpilot.platform

import app.mailpilot.data.*
import app.mailpilot.ai.ReasoningSnapshot

data class PdfChoice(val attachment: Attachment,val count: Int,val selected: List<Int>,val token: String=newId(),val loading: Boolean=false,val error: String="")
data class MailState(
    val selectionGroups: List<Map<String,Any?>> = emptyList(),val selectionBudget: Map<String,Any> = emptyMap(),
    val localMaterials: List<LocalMaterial> = emptyList(),
    val accounts: List<MailAccount> = emptyList(),val models: List<ModelProfile> = emptyList(),
    val settings: UserSettings = UserSettings(),val activeAccount: String = "",val folders: List<String> = listOf("INBOX"),val folder: String = "INBOX",
    val foldersLoading: Boolean=false,val foldersError: String="",
    val syncing: Boolean=false,val syncLabel: String="",val searching: Boolean=false,
    val messages: List<MailMessage> = emptyList(),val query: String = "",val unreadOnly: Boolean = false,
    val selection: List<Selection> = emptyList(),val tab: Int = 0,val detail: MailMessage? = null,val detailAttachments: List<Attachment> = emptyList(),
    val drafts: List<Draft> = emptyList(),val editor: Draft? = null,val sendPreview: Draft? = null,
    val editableMessageIds: Set<String> = emptySet(),
    val entryVersionCounts: Map<String,Int> = emptyMap(),
    val historyRevision: Long=0,val recheckAssets: Set<String> = emptySet(),val visionProgress: Map<String,Any> = emptyMap(),
    val conversationId: String = newId(),val currentConversation: Conversation? = null,val entries: List<ChatEntry> = emptyList(),
    val busy: Boolean = false,val analyzing: Boolean = false,val status: String = "",val error: String? = null,
    val streaming: String = "",val resultCards: List<MailMessage> = emptyList(),val pdfChoice: PdfChoice? = null,val source: SourceChunk? = null,
    val notice: String? = null,val ready: Boolean = false,val selectionLabels: List<String> = emptyList(),
    val responseId: String="",val reasoning: ReasoningSnapshot=ReasoningSnapshot(),
    val reasoningRecords: Map<String,ReasoningSnapshot> = emptyMap(),
    val draftPartial: app.mailpilot.ai.DraftPartial=app.mailpilot.ai.DraftPartial(),val agentStage: String=""
)


