package app.mailpilot

import app.mailpilot.data.*
import app.mailpilot.platform.MailState
import app.mailpilot.ai.ReasoningSnapshot
import org.json.JSONObject
import org.json.JSONArray

/** Public channel payloads never expose stored credentials, even encrypted ones. */
object BridgeCodec {
    fun account(a: MailAccount)=mapOf("id" to a.id,"label" to a.label,"email" to a.email,"displayName" to a.displayName,"username" to a.username,"hasSecret" to a.passwordCipher.isNotBlank(),"imapHost" to a.imapHost,"imapPort" to a.imapPort,"imapSecurity" to a.imapSecurity,"smtpHost" to a.smtpHost,"smtpPort" to a.smtpPort,"smtpSecurity" to a.smtpSecurity)
    fun model(m: ModelProfile)=mapOf("id" to m.id,"label" to m.label,"baseUrl" to m.baseUrl,"model" to m.model,"hasSecret" to m.apiKeyCipher.isNotBlank(),"contextTokens" to m.contextTokens,"outputTokens" to app.mailpilot.ai.ModelOutputPolicy.ceiling(m),"outputMode" to (if(m.outputTokens==0) "auto" else "custom"),"textVerified" to m.textVerified,"supportsTools" to m.supportsTools,"capability" to app.mailpilot.ai.ModelCapabilityResolver.fields(m),"diagnostics" to runCatching { JSONObject(m.diagnosticsJson) }.getOrDefault(JSONObject()),"supportsVision" to (app.mailpilot.ai.ModelCapabilityResolver.vision(m)=="supported"),"supportsStreaming" to m.supportsStreaming,"tokenParameter" to m.tokenParameter,"testReport" to m.testReport,"provider" to m.provider,"thinkingMode" to m.thinkingMode,"reasoningEffort" to m.reasoningEffort,"thinkingBudget" to m.thinkingBudget)
    fun message(m: MailMessage)=mapOf("id" to m.id,"accountId" to m.accountId,"folder" to m.folder,"subject" to m.subject,"sender" to m.sender,"senderAddress" to m.senderAddress,"to" to m.to,"cc" to m.cc,"sentAt" to m.sentAt,"preview" to m.preview,"unread" to m.unread,"attachmentCount" to m.attachmentCount,"bodyState" to m.bodyState)
    fun attachment(a: Attachment)=mapOf("id" to a.id,"messageId" to a.messageId,"name" to a.name,"mimeType" to a.mimeType,"size" to app.mailpilot.attachments.SelectionPolicy.actualSize(a),"selectionReason" to app.mailpilot.attachments.SelectionPolicy.reason(a))
    fun draft(d: Draft)=mapOf("id" to d.id,"accountId" to d.accountId,"to" to d.to,"cc" to d.cc,"bcc" to d.bcc,"subject" to d.subject,"body" to d.body,"files" to JsonCodec.files(d.filesJson).map { mapOf("path" to it.path,"name" to it.name,"mime" to it.mime) },"revision" to d.revision,"status" to d.status,"error" to d.error,"updatedAt" to d.updatedAt)
    fun source(s: SourceChunk)=mapOf("id" to s.id,"messageId" to s.messageId,"attachmentId" to s.attachmentId,"title" to s.title,"location" to (s.location+if(s.contentKey.isNotBlank()) " · 本地预览，全文可按需读取" else ""),"text" to s.text,"imagePath" to s.imagePath,"isModelObservation" to s.isModelObservation,"kind" to s.kind,"url" to s.url,"assetKey" to s.assetKey)
    fun entry(e: ChatEntry,s: MailState,historical: Boolean=false): Map<String,Any?> = mapOf("id" to e.id,"role" to e.role,"versionCount" to (s.entryVersionCounts[e.id] ?: 1),"canEdit" to (e.role=="user" && e.id in s.editableMessageIds && !app.mailpilot.mail.ChatSendGate.isConfirmation(e.text)),"resultStatus" to e.resultStatus,"failure" to runCatching { JSONObject(e.failureJson) }.getOrDefault(JSONObject()),"visionModel" to e.visionModel,"text" to (if(e.role=="assistant") app.mailpilot.ai.DraftPresentation.readable(e.text) else e.text),"action" to e.action,"targetAnswerId" to e.targetAnswerId,"review" to app.mailpilot.mail.DraftReviewState.forEntry(e,s.entries.lastOrNull()?.id,s.drafts,s.accounts).fields(),"draftId" to e.draftId,"draftPreview" to runCatching { JSONObject(e.draftPreviewJson) }.getOrNull(),"sources" to JsonCodec.sources(e.sourcesJson).map(::source),"reasoning" to (s.reasoningRecords[e.id] ?: ReasoningSnapshot.legacy(e)).fields()) + mapOf("historical" to historical) +
        (if(historical) mapOf("canEdit" to false,"review" to mapOf("label" to "历史草稿 · 仅供查看","action" to "","canSend" to false)) else emptyMap())
    fun state(s: MailState): String=JSONObject(mapOf(
        "appVersion" to BuildConfig.VERSION_NAME,"buildNumber" to BuildConfig.VERSION_CODE,
        "modelCatalog" to app.mailpilot.ai.ModelCapabilityResolver.catalog.map { it.fields() },"localMaterials" to s.localMaterials.map { it.fields() }, "searchConfig" to s.settings.search.publicFields(), "speechConfig" to s.settings.speech.publicFields(),
        "accounts" to s.accounts.map(::account),"models" to s.models.map { m -> model(app.mailpilot.ai.ModelOutputPolicy.resolve(app.mailpilot.ai.ModelContextPolicy.resolve(m,s.settings.contextModes[m.id]),s.settings.outputModes[m.id]))+mapOf("contextMode" to app.mailpilot.ai.ModelContextPolicy.mode(m,s.settings.contextModes[m.id])) },"settings" to mapOf("accountId" to s.settings.accountId,"textModelId" to s.settings.textModelId,"visionModelId" to s.settings.visionModelId,"theme" to s.settings.theme,"appLanguage" to s.settings.appLanguage,"syncMinutes" to s.settings.syncMinutes,"fastCompression" to s.settings.fastCompression),
        "activeAccount" to s.activeAccount,"folder" to s.folder,"folders" to s.folders,"messages" to s.messages.map(::message),"query" to s.query,"unreadOnly" to s.unreadOnly,
        "foldersLoading" to s.foldersLoading,"foldersError" to s.foldersError,
        "syncing" to s.syncing,"syncLabel" to s.syncLabel,"searching" to s.searching,
        "selection" to s.selection.map { mapOf("messageId" to it.messageId,"attachmentIds" to it.attachmentIds,"pdfPages" to it.pdfPages,"defaultPdfIds" to it.defaultPdfIds) },"selectionLabels" to s.selectionLabels,"selectionGroups" to s.selectionGroups,"selectionBudget" to s.selectionBudget,
        "tab" to s.tab,"detail" to s.detail?.let { message(it)+mapOf("body" to it.body,"bodyError" to it.bodyError) },"detailAttachments" to s.detailAttachments.map(::attachment),"editor" to s.editor?.let(::draft),"drafts" to s.drafts.map(::draft),"sendPreview" to s.sendPreview?.let(::draft),
        "conversationId" to s.conversationId,"historyRevision" to s.historyRevision,"visionProgress" to s.visionProgress,"recheckAssets" to s.recheckAssets.toList(),
        "contextSummary" to s.currentConversation?.takeIf { it.id==s.conversationId }?.contextSummary.orEmpty(),
        "summarizedEntries" to (s.currentConversation?.takeIf { it.id==s.conversationId }?.summarizedEntries ?: 0),
        "entries" to s.entries.map { entry(it,s) },"streaming" to s.streaming,"resultCards" to s.resultCards.map(::message),
        "draftPartial" to s.draftPartial.json(),"agentStage" to s.agentStage,"responseId" to s.responseId,"reasoning" to s.reasoning.fields(),
        "busy" to s.busy,"analyzing" to s.analyzing,"status" to s.status,"error" to s.error,"notice" to s.notice,"ready" to s.ready,
        "pdfChoice" to s.pdfChoice?.let { mapOf("attachment" to attachment(it.attachment),"count" to it.count,"selected" to it.selected,"token" to it.token,"loading" to it.loading,"error" to it.error) },"source" to s.source?.let(::source)
    )).toString()
    fun source(j: JSONObject)=SourceChunk(j.optString("id",newId()),j.optString("messageId"),j.optString("attachmentId"),j.optString("title"),j.optString("location"),j.optString("text"),j.optString("imagePath"),j.optBoolean("isModelObservation"),j.optString("kind","mail"),j.optString("url"))
    fun account(j: JSONObject,old: MailAccount?)=(old ?: MailAccount()).copy(label=j.optString("label"),email=j.optString("email"),displayName=j.optString("displayName"),username=j.optString("username"),imapHost=j.optString("imapHost"),imapPort=j.optInt("imapPort",993),imapSecurity=j.optString("imapSecurity","SSL"),smtpHost=j.optString("smtpHost"),smtpPort=j.optInt("smtpPort",465),smtpSecurity=j.optString("smtpSecurity","SSL"))
    fun model(j: JSONObject,old: ModelProfile?): ModelProfile {
        val m=(old ?: ModelProfile()).copy(label=j.optString("label"),baseUrl=j.optString("baseUrl"),model=j.optString("model"),contextTokens=j.optInt("contextTokens",32768),outputTokens=if(j.optString("outputMode")=="auto") 0 else j.optInt("outputTokens",old?.outputTokens ?: DEFAULT_MODEL_OUTPUT_TOKENS),tokenParameter=j.optString("tokenParameter","max_tokens"),provider=j.optString("provider",old?.provider ?: "auto"),thinkingMode=j.optString("thinkingMode",old?.thinkingMode ?: "default"),reasoningEffort=j.optString("reasoningEffort",old?.reasoningEffort ?: ""),thinkingBudget=j.optInt("thinkingBudget",old?.thinkingBudget ?: 0))
        app.mailpilot.ai.ReasoningOptions.apply(m,JSONObject())
        return if(old!=null && (app.mailpilot.ai.ModelCapabilityResolver.endpoint(m)!=app.mailpilot.ai.ModelCapabilityResolver.endpoint(old) || m.model!=old.model)) m.copy(textVerified=false,supportsVision=false,supportsStreaming=false,supportsTools=false,testReport="连接信息已更改，旧诊断已过期；可直接使用",diagnosticIdentity="",diagnosticsJson="{}") else m
    }
    fun draft(j: JSONObject,old: Draft) = old.copy(accountId=j.optString("accountId",old.accountId),to=j.optString("to"),cc=j.optString("cc"),bcc=j.optString("bcc"),subject=j.optString("subject"),body=j.optString("body"),filesJson=(j.optJSONArray("files") ?: JSONArray(old.filesJson)).toString())
}


