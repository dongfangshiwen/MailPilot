package app.mailpilot.ai

import androidx.room.withTransaction
import app.mailpilot.data.*
import app.mailpilot.mail.*
import org.json.JSONObject

class AgentResultCommitter(private val db: MailDatabase,private val mail: MailRepository) {
    companion object {
        fun draftJson(d: Draft)=JSONObject(app.mailpilot.BridgeCodec.draft(d)).put("inReplyTo",d.inReplyTo).put("references",d.references)
        fun parseDraft(j: JSONObject)=Draft(id=j.getString("id"),accountId=j.getString("accountId"),to=j.getString("to"),cc=j.getString("cc"),bcc=j.getString("bcc"),subject=j.getString("subject"),body=j.getString("body"),filesJson=j.getJSONArray("files").toString(),inReplyTo=j.optString("inReplyTo"),references=j.optString("references"),revision=j.getLong("revision"),status=j.getString("status"))
        suspend fun checkpoint(dao: MailDao,id: String,result: AnalysisResult) {
            val value=JSONObject().put("text",result.text).put("sources",JsonCodec.sources(result.sources)).put("draftId",result.draftId).put("visionModel",result.visionModel).put("partial",result.partial)
            result.candidate?.draft?.let { d -> value.put("candidate",draftJson(d)) }
            AgentCheckpoints.update(dao,id) {
                // The validated result replaces intermediate caches; don't retain duplicate
                // copies of potentially large attachment text in the same Room JSON column.
                if(!result.partial) listOf("files","vision","search","actions","context","materialSummaries","compression","compressionRepair").forEach(it::remove)
                it.put("result",value).put("phase","committing")
            }
        }
        fun restored(turn: TurnSnapshot?): AnalysisResult? {
            val result=AgentRunCheckpoint.from(turn).data.optJSONObject("result") ?: return null
            val d=result.optJSONObject("candidate")?.let(::parseDraft)
            return AnalysisResult(result.getString("text"),JsonCodec.sources(result.getString("sources")),result.optString("draftId").takeIf { it.isNotBlank() && it!="null" },result.optString("visionModel"),d?.let(::DraftCandidate),result.optBoolean("partial"))
        }
    }
    suspend fun commit(entry: ChatEntry,result: AnalysisResult): Draft? = db.withTransaction {
        val dao=db.dao(); val turn=requireNotNull(dao.turn(entry.id)) { "本轮记录已删除" }
        requireNotNull(dao.conversation(entry.conversationId)) { "会话已删除" }
        require(turn.conversationId==entry.conversationId) { "会话范围不一致" }
        val cp=AgentRunCheckpoint.from(turn).data
        if(cp.optString("phase")=="complete") return@withTransaction cp.optString("draftId").takeIf { it.isNotBlank() }?.let { dao.draft(it) }
        val draft=result.candidate?.draft?.also { require(it.accountId==turn.accountId) { "草稿账号不一致" } }?.let { mail.saveDraft(it) }
            ?: result.draftId?.let { dao.draft(it) }
        val preview=draft?.let { ChatSendGate(db,mail).snapshot(it) }.orEmpty()
        dao.putEntry(entry.copy(draftId=draft?.id.orEmpty(),draftPreviewJson=preview,resultStatus="complete",action=if(result.partial) "research_partial" else entry.action,failureJson=JSONObject().put("diagnostics",cp.optJSONObject("diagnostics") ?: JSONObject()).toString()))
        cp.put("phase","complete").put("draftId",draft?.id.orEmpty()).put("draftRevision",draft?.revision ?: 0).remove("preview")
        cp.remove("result")
        dao.updateTurnRequest(turn.id,JSONObject(turn.requestJson).put("agentRun",cp).toString())
        draft
    }
}

suspend fun recoverAgentRuns(dao: MailDao) {
    dao.purgeOrphanTurns()
    for(turn in dao.allTurns()) {
        val cp=AgentRunCheckpoint.from(turn)
        // New action stages must recover without maintaining a second list of running names.
        if(cp.phase.isBlank() || cp.phase in setOf("complete","failed","canceled","cancelled","stopped")) continue
        val old=dao.history(turn.conversationId).firstOrNull { it.id==turn.id }
            ?: ChatEntry(id=turn.id,conversationId=turn.conversationId,role="assistant",text="")
        val failure=FailureInfo("process_interrupted","本轮因应用退出而中断，资料和预览已保留，请手动重试。")
        dao.putEntry(old.copy(resultStatus="failed",text=old.text.ifBlank { "本轮未完成" },action="analysis_failed",
            failureJson=JSONObject(failure.fields()).put("draftPartial",cp.preview.json()).toString(),
            reasoningState=if(old.reasoningState=="thinking") "interrupted" else old.reasoningState))
        AgentCheckpoints.update(dao,turn.id) { checkpoint ->
            checkpoint.put("phase","failed")
            checkpoint.optJSONObject("reasoningTrace")?.let { raw ->
                val trace=ReasoningSnapshot.from(raw)
                checkpoint.put("reasoningTrace",JSONObject(trace.copy(runComplete=true,revision=trace.revision+1,
                    state=if(trace.state=="thinking") "interrupted" else trace.state,
                    segments=trace.segments.map { if(it.state=="thinking") it.copy(state="interrupted") else it }).fields()))
            }
        }
        RunTelemetry.end(dao,turn.id,"process_interrupted")
    }
}
