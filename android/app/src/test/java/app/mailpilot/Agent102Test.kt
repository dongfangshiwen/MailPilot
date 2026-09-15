package app.mailpilot

import android.app.Application
import androidx.room.Room
import app.mailpilot.ai.*
import app.mailpilot.attachments.*
import app.mailpilot.data.*
import app.mailpilot.mail.MailRepository
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.flow
import org.json.*
import org.junit.*
import org.junit.Assert.*
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import java.io.File

@RunWith(RobolectricTestRunner::class)
@Config(sdk=[28],application=Application::class)
class Agent102Test {
    private lateinit var db: MailDatabase
    @Before fun setup() { db=Room.inMemoryDatabaseBuilder(RuntimeEnvironment.getApplication(),MailDatabase::class.java).allowMainThreadQueries().build() }
    @After fun close() { db.close() }
    @Test fun newModelDefaultsTo4096AndExistingOutputIsPreserved(): Unit=runBlocking {
        assertEquals(4096,ModelProfile().outputTokens)
        assertEquals(4096,BridgeCodec.model(JSONObject(),null).outputTokens)
        val existing=ModelProfile(outputTokens=2048)
        db.dao().putModel(existing)
        assertEquals(2048,db.dao().model(existing.id)!!.outputTokens)
        assertEquals(2048,BridgeCodec.model(JSONObject(),existing).outputTokens)
        assertEquals(4096,BridgeCodec.model(JSONObject().put("outputTokens",4096),existing).outputTokens)
    }
    private fun message(id: String="m",sender: String="sender@example.test")=MailMessage(id,"account","INBOX",1,if(id=="m") 1 else 2,"邀请","sender",sender,sentAt=0,body="邀请参加周五会议。")
    private class Client(val answers: List<JSONObject>): ModelClient {
        val requests=mutableListOf<String>(); var n=0
        override suspend fun test(profile: ModelProfile)=profile
        override fun generate(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?)=flow {
            requests+=messages.toString(); val answer=answers[n++]
            answer.optString("content").chunked(3).forEach { emit(ModelEvent.Delta(it)) }
            emit(ModelEvent.Completed(answer))
        }
    }
    private inner class Mail: MailRepository {
        var saved: Draft?=null
        override suspend fun test(account: MailAccount)=""
        override suspend fun folders(accountId: String)=emptyList<String>()
        override suspend fun load(accountId: String,folder: String,query: MailQuery,onProgress: (String)->Unit)=emptyList<MailMessage>()
        override suspend fun markRead(message: MailMessage) {}
        override suspend fun download(id: String)=error("no attachment download expected")
        override suspend fun saveDraft(draft: Draft): Draft { saved=draft.copy(revision=draft.revision+1); db.dao().putDraft(saved!!); return saved!! }
        override suspend fun send(draftId: String,confirmedRevision: Long)=error("agent must never send")
    }
    private val processor=object: AttachmentProcessor {
        override suspend fun pdfCount(file: File)=error("not expected")
        override suspend fun previewPdf(file: File,page: Int)=error("not expected")
        override suspend fun process(attachment: Attachment,pages: List<Int>,onProgress: (String)->Unit)=emptyList<SourceChunk>()
    }
    private fun draft(to: String="",id: String="")=roleMessage("assistant",JSONObject().put("status","draft").put("draft_id",id).put("to",to).put("subject","回复邀请").put("body","您好，确认参加周五的会议。谢谢。").toString())
    @Test fun singleSelectedSenderIsDefaultForStructuredAndToolDrafts(): Unit=runBlocking {
        db.dao().putMessages(listOf(message()))
        for(tool in listOf(false,true)) {
            val answers=if(!tool) listOf(draft()) else listOf(JSONObject().put("role","assistant").put("tool_calls",JSONArray().put(JSONObject().put("id","tool1").put("function",JSONObject().put("name","create_draft").put("arguments",JSONObject().put("to","").put("subject","会议").put("body","确认参加会议").toString())))),roleMessage("assistant","已起草"))
            val mail=Mail(); val result=LocalAgent(db.dao(),mail,processor,Client(answers)).run("account","INBOX",listOf(Selection("m")),"帮我回复会议邀请",ModelProfile(supportsTools=tool),null,composeMode=!tool)
            assertEquals("sender@example.test",result.candidate!!.draft.to); assertEquals("",result.candidate!!.draft.cc); assertNotNull(result.draftId)
        }
    }
    @Test fun explicitRecipientWinsAndMultipleSelectionHasNoDefault(): Unit=runBlocking {
        db.dao().putMessages(listOf(message(),message("other","other@example.test")))
        for((selection,to,question,expected) in listOf(
            listOf(listOf("m"),"target@example.test","写给 target@example.test 确认会议","target@example.test"),
            listOf(listOf("m","other"),"","总结邮件写成邮件",""),
            listOf(listOf("m"),"injected@evil.test","回复参加会议","sender@example.test"))) {
            val mail=Mail()
            @Suppress("UNCHECKED_CAST") val selected=(selection as List<String>).map { Selection(it) }
            val result=LocalAgent(db.dao(),mail,processor,Client(listOf(draft(to as String)))).run("account","INBOX",selected,question as String,ModelProfile(),null,composeMode=true)
            assertEquals(expected,result.candidate!!.draft.to)
        }
        assertEquals("",DraftRecipients.sender(listOf(message(sender="invalid"))))
        assertEquals("",DraftRecipients.allowed("a@example.test","user supplied xa@example.test"))
    }
    @Test fun redraftKeepsRecipientAndFilesEvenWithDifferentSelectedSender(): Unit=runBlocking {
        db.dao().putMessages(listOf(message()))
        val old=Draft(accountId="account",to="retained@example.test",cc="cc@example.test",filesJson="[]",body="原正文",revision=3)
        db.dao().putDraft(old); val history=listOf(ChatEntry(conversationId="chat",role="assistant",text="草稿",draftId=old.id))
        val mail=Mail()
        val result=LocalAgent(db.dao(),mail,processor,Client(listOf(draft("sender@example.test",old.id)))).run("account","INBOX",listOf(Selection("m")),"更正式一点",ModelProfile(),null,history=history,composeMode=true,redraftId=old.id)
        assertEquals(old.to,result.candidate!!.draft.to); assertEquals(old.cc,result.candidate!!.draft.cc); assertEquals(old.filesJson,result.candidate!!.draft.filesJson)
    }
    @Test fun echoedDraftJsonNeverStreamsAndOnlyExactExistingRecordGetsCard(): Unit=runBlocking {
        val real=Draft(accountId="account",to="target@example.test",subject="主题",body="正文",revision=4)
        db.dao().putDraft(real)
        val history=listOf(ChatEntry(conversationId="chat",role="assistant",text="已起草",draftId=real.id))
        for(matches in listOf(true,false)) {
            val value=JSONObject().put("draft_id",real.id).put("revision",4).put("to",real.to).put("subject",real.subject).put("body",if(matches) real.body else "伪造变化")
            val wire="请核对：\n```json\n$value\n```"; val partial=StringBuilder(); val mail=Mail()
            val result=LocalAgent(db.dao(),mail,processor,Client(listOf(roleMessage("assistant",wire)))).run("account","INBOX",emptyList(),"核对内容",ModelProfile(),null,history=history,onDelta={ partial.append(it) })
            assertFalse(partial.contains("draft_id")); assertFalse(result.text.contains("draft_id")); assertNull(mail.saved)
            assertEquals(if(matches) real.id else null,result.draftId)
        }
    }
    @Test fun codeQuestionsStayIntactAndHistoryIsReadableWithoutPrivateFields(): Unit=runBlocking {
        val code="```json\n{\"name\":\"sample\"}\n```"
        val result=LocalAgent(db.dao(),Mail(),processor,Client(listOf(roleMessage("assistant",code)))).run("","INBOX",emptyList(),"写JSON示例",ModelProfile(),null)
        assertEquals(code,result.text)
        val preview=JSONObject().put("to","target@example.test").put("body","正文").put("subject","主题").put("revision",3).put("files",JSONArray().put(JSONObject().put("name","报价.pdf").put("path","/private/secret")))
        val entry=ChatEntry(conversationId="chat",role="assistant",text="已起草",draftId="id",draftPreviewJson=preview.toString())
        val reference=DraftPresentation.reference(entry)
        assertTrue(reference.contains("收件人：target@example.test")); assertTrue(reference.contains("报价.pdf"))
        assertFalse(reference.contains("revision")); assertFalse(reference.contains("draft_id")); assertFalse(reference.contains("/private/secret"))
    }
    @Test fun editingRemovesOldFutureFromContextButKeepsRawVersionsAndAudit() {
        fun e(id: String,role: String="user",edit: String="")=ChatEntry(id=id,conversationId="chat",role=role,text=id,action=if(edit.isBlank()) "" else "edit_user",targetAnswerId=edit)
        val raw=listOf(e("q1"),e("a1","assistant"),e("q2"),e("sent","assistant"),e("q1-v2",edit="q1"),e("a1-v2","assistant"),e("q1-v3",edit="q1-v2"),e("a1-v3","assistant"))
        assertEquals(listOf("q1-v3","a1-v3"),ChatBranch.active(raw).map { it.id })
        assertEquals(3,ChatBranch.versions(raw[6],raw).size)
        assertEquals(8,raw.size); assertTrue(raw.any { it.id=="sent" })
        assertEquals(listOf("a1"),ChatBranch.replies(raw[0],raw).map { it.id })
        assertEquals(listOf("a1-v2"),ChatBranch.replies(raw[4],raw).map { it.id })
        assertEquals(listOf("a1-v3"),ChatBranch.replies(raw[6],raw).map { it.id })
    }
    @Test fun historicalBridgeKeepsReasoningSourcesAndDraftButDisablesActions() {
        val entry=ChatEntry(conversationId="chat",role="assistant",text="原回答",reasoningText="原思考",reasoningState="completed",
            sourcesJson=JsonCodec.sources(listOf(SourceChunk("T1:S1","mail","","资料","第 1 页","原资料"))),
            draftPreviewJson="{\"subject\":\"历史主题\",\"body\":\"历史正文\"}")
        val payload=JSONObject(BridgeCodec.entry(entry,app.mailpilot.platform.MailState(entries=listOf(entry)),historical=true))
        assertTrue(payload.getBoolean("historical")); assertFalse(payload.getBoolean("canEdit"))
        assertFalse(payload.getJSONObject("review").getBoolean("canSend")); assertEquals("",payload.getJSONObject("review").getString("action"))
        assertEquals("原思考",payload.getJSONObject("reasoning").getString("text"))
        assertEquals("T1:S1",payload.getJSONArray("sources").getJSONObject(0).getString("id"))
        assertEquals("历史正文",payload.getJSONObject("draftPreview").getString("body"))
    }
}
