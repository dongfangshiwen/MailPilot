package app.mailpilot

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.room.Room
import app.mailpilot.ai.*
import app.mailpilot.attachments.*
import app.mailpilot.data.*
import app.mailpilot.mail.*
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import org.json.*
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File

@RunWith(AndroidJUnit4::class)
class Agent103DeviceTest {
    @Test fun interruptedDraftRecoveryAndAtomicCommitOnApi36(): Unit=runBlocking {
        val context=InstrumentationRegistry.getInstrumentation().targetContext
        val db=Room.inMemoryDatabaseBuilder(context,MailDatabase::class.java).build()
        try {
            val dao=db.dao(); val secrets=AndroidSecrets()
            val mail=MailRepositoryImpl(db,secrets,context.filesDir)
            dao.putAccount(MailAccount(id="a",email="device103@example.test"))
            dao.putConversation(Conversation(id="c",accountId="a"))
            dao.putMessages(listOf(MailMessage("m","a","INBOX",1,1,"会议邀请","sender","hr@example.test",sentAt=0,body="不应再次进入模型的原文")))
            val source=SourceChunk("T1:S1","m","pdf","会议.pdf","第1页","已读取的 PDF",isModelObservation=true)
            val answer=ChatEntry(id="answer",conversationId="c",role="assistant",text="请于周五参加会议。",sourcesJson=JsonCodec.sources(listOf(source)))
            val question=ChatEntry(id="q",conversationId="c",role="user",text="将这条回答写成邮件")
            dao.putEntry(answer); dao.putEntry(question)
            dao.putTurn(TurnSnapshot("run","c","a","INBOX","[]",2,ChatRequestOptions("disabled").json(),requestJson=JSONObject().put("userEntryId","q").toString()))
            val processor=object: AttachmentProcessor {
                override suspend fun pdfCount(file: File): Int=error("Must not inspect PDF")
                override suspend fun previewPdf(file: File,page: Int): File=error("Must not render PDF")
                override suspend fun process(attachment: Attachment,pages: List<Int>,onProgress: (String)->Unit): List<SourceChunk> =error("Must not re-read attachments")
            }
            var attempts=0
            val client=object: ModelClient {
                override suspend fun test(profile: ModelProfile)=profile
                override fun generate(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?)=flow {
                    attempts++; assertEquals("disabled",profile.thinkingMode); assertNull(tools)
                    assertFalse(messages.toString().contains("不应再次进入模型的原文"))
                    val raw=JSONObject().put("status","draft").put("subject","确认会议").put("body","您好，我确认参加周五的会议。谢谢。").toString()
                    if(attempts==1) { emit(ModelEvent.Delta("{\"status\":\"draft\",\"subject\":\"确认会议\",\"body\":\"您好，我确认")); throw java.io.IOException("fixture interruption") }
                    raw.chunked(2).forEach { emit(ModelEvent.Delta(it)) }; emit(ModelEvent.Completed(roleMessage("assistant",raw)))
                }
            }
            var partial=DraftPartial()
            val agent=LocalAgent(dao,mail,processor,client)
            suspend fun run()=agent.run("a","INBOX",emptyList(),question.text,ModelProfile(thinkingMode="disabled"),null,history=listOf(answer),conversationId="c",composeMode=true,requestId="run",targetAnswerId=answer.id,onEvent={ if(it is AgentEvent.DraftPreview) partial=it.value })
            assertNotNull(runCatching { run() }.exceptionOrNull())
            assertTrue(partial.body.isNotBlank()); assertTrue(dao.allDrafts().isEmpty())
            AgentCheckpoints.update(dao,"run") { it.put("phase","generating").put("preview",partial.json()) }
            recoverAgentRuns(dao)
            assertEquals("failed",dao.history("c").first { it.id=="run" }.resultStatus)
            assertEquals(partial.body,JSONObject(dao.history("c").first { it.id=="run" }.failureJson).getJSONObject("draftPartial").getString("body"))
            val result=run(); AgentResultCommitter.checkpoint(dao,"run",result)
            val entry=ChatEntry(id="run",conversationId="c",role="assistant",text=result.text)
            val committer=AgentResultCommitter(db,mail)
            val saved=committer.commit(entry,AgentResultCommitter.restored(dao.turn("run"))!!)!!
            committer.commit(entry,result)
            assertEquals(2,attempts); assertEquals(1,dao.allDrafts().size); assertEquals(1L,saved.revision); assertEquals("hr@example.test",saved.to)
            assertEquals("DRAFT",saved.status); assertNull(dao.attempt(saved.id,saved.revision))
            assertEquals("complete",dao.history("c").first { it.id=="run" }.resultStatus)
        } finally { db.close() }
    }
}
