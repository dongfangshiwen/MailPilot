package app.mailpilot

import android.app.Application
import androidx.room.Room
import app.mailpilot.ai.*
import app.mailpilot.attachments.*
import app.mailpilot.data.*
import app.mailpilot.mail.*
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import okhttp3.OkHttpClient
import okhttp3.mockwebserver.*
import org.json.*
import org.junit.*
import org.junit.Assert.*
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import java.io.File
import java.util.concurrent.TimeUnit

@RunWith(RobolectricTestRunner::class)
@Config(sdk=[28],application=Application::class)
class Agent103Test {
    private lateinit var db: MailDatabase
    private val app get()=RuntimeEnvironment.getApplication()
    @Before fun setup() { db=Room.inMemoryDatabaseBuilder(app,MailDatabase::class.java).allowMainThreadQueries().build() }
    @After fun close() { db.close() }
    private fun repository()=MailRepositoryImpl(db,PlainTestSecrets(),app.filesDir)
    private val processor=object: AttachmentProcessor {
        override suspend fun pdfCount(file: File): Int=error("Answer conversion must not inspect PDF")
        override suspend fun previewPdf(file: File,page: Int): File=error("Must not render")
        override suspend fun process(attachment: Attachment,pages: List<Int>,onProgress: (String)->Unit): List<SourceChunk> =error("Must not process attachments")
    }
    private suspend fun turn(account: Boolean=true): Pair<ChatEntry,TurnSnapshot> {
        if(account) db.dao().putAccount(MailAccount(id="a",email="sender@example.test"))
        db.dao().putConversation(Conversation(id="c",accountId=if(account) "a" else ""))
        val e=ChatEntry(id="run",conversationId="c",role="assistant",text="",resultStatus="running")
        val t=TurnSnapshot("run","c",if(account) "a" else "","INBOX","[]",1)
        db.dao().putEntry(e); db.dao().putTurn(t); return e to t
    }
    private fun chunk(content: String="",reasoning: String="",finish: String?=null)="data: "+JSONObject().put("choices",JSONArray().put(JSONObject().put("delta",JSONObject().put("content",content).put("reasoning_content",reasoning)).put("finish_reason",finish ?: JSONObject.NULL)))+"\n\n"
    private fun client(readMs: Long=2000)=CompatibleModelClient(PlainTestSecrets(),OkHttpClient.Builder().readTimeout(readMs,TimeUnit.MILLISECONDS).callTimeout(10,TimeUnit.SECONDS).build(),true)
    private fun model(s: MockWebServer)=ModelProfile(baseUrl=s.url("/v1").toString(),model="fixture",thinkingMode="disabled")
    private val valid=JSONObject().put("status","draft").put("question","").put("subject","确认会议").put("body","您好，确认参加周五会议。\n\n谢谢。").toString()

    @Test fun incrementalDecoderHandlesEverySplitAndNeverPublishesJsonKeys() {
        val raw="""{"status":"draft","question":"","subject":"主题","body":"第一行\n引号\"反斜杠\\\u4e2d\ud83d\ude00结束"}"""
        for(split in 0..raw.length) {
            val decoder=DraftStreamDecoder(); decoder.append(raw.take(split)); val final=decoder.append(raw.drop(split))
            assertEquals(JSONObject(raw).getString("body"),final.body); assertEquals("主题",final.subject)
            assertFalse(final.readable().contains("status"))
        }
        val decoder=DraftStreamDecoder(); var final=DraftPartial()
        raw.forEach { final=decoder.append(it.toString()); assertFalse(final.body.lastOrNull()?.isHighSurrogate()==true) }
        assertEquals(JSONObject(raw).getString("body"),final.body)
    }
    @Test fun invalidStructuresNeverBecomeSendable() {
        for(raw in listOf("{\"status\":\"draft\",\"body\":\"", "{\"status\":\"draft\",\"body\":[]}","{\"status\":\"draft\",\"body\":\"\"}","{\"status\":\"sent\",\"body\":\"text\"}")) {
            assertEquals("result_format",FailureInfo.from(runCatching { DraftWorkflow.parse(raw) }.exceptionOrNull()!!).type)
        }
    }
    @Test fun finishMarkerClosesBeforeDelayedTailWithoutDone(): Unit=runBlocking {
        val s=MockWebServer(); s.start()
        try {
            val complete=chunk(valid,finish="stop")
            s.enqueue(MockResponse().setHeader("Content-Type","text/event-stream").setBody(complete+": tail not needed\n\n").throttleBody(complete.toByteArray().size.toLong(),3,TimeUnit.SECONDS))
            val events=withTimeout(2000) { client().generate(model(s),JSONArray()).toList() }
            assertEquals(valid,events.filterIsInstance<ModelEvent.Completed>().single().message.getString("content"))
            assertEquals("stop",events.filterIsInstance<ModelEvent.Diagnostics>().last().value.getString("finishReason"))
            assertEquals(1,events.filterIsInstance<ModelEvent.Diagnostics>().count { it.value.optString("event")=="request_body_sent" })
            assertEquals(1,s.requestCount)
        } finally { s.shutdown() }
    }
    @Test fun heartbeatsCountAsActivityWhileOnlyThinkingArrives(): Unit=runBlocking {
        val s=MockWebServer(); s.start()
        try {
            val body=chunk(reasoning="核对")+": ping\n\n".repeat(8)+chunk(valid,finish="stop")
            s.enqueue(MockResponse().setHeader("Content-Type","text/event-stream").setBody(body).throttleBody(30,80,TimeUnit.MILLISECONDS))
            val events=client(500).generate(model(s),JSONArray()).toList()
            assertEquals(1,events.filterIsInstance<ModelEvent.Thinking>().size)
            assertEquals(valid,events.filterIsInstance<ModelEvent.Completed>().single().message.getString("content"))
        } finally { s.shutdown() }
    }
    @Test fun stalledReadRetainsTypedPartialAndDoesNotRetry(): Unit=runBlocking {
        val s=MockWebServer(); s.start()
        try {
            val first=chunk("{\"status\":\"draft\",\"subject\":\"会议\",\"body\":\"已收到")
            s.enqueue(MockResponse().setHeader("Content-Type","text/event-stream").setBody(first+chunk("完整\"}",finish="stop")).throttleBody(first.toByteArray().size.toLong(),1,TimeUnit.SECONDS))
            val decoder=DraftStreamDecoder(); var preview=DraftPartial(); var complete=false
            val error=runCatching { client(200).generateRequest(model(s),JSONArray(),options=ModelRequestOptions(true,"draft","run")).collect { if(it is ModelEvent.Delta) preview=decoder.append(it.text); if(it is ModelEvent.Completed) complete=true } }.exceptionOrNull()!!
            val failure=FailureInfo.from(error)
            assertEquals("read_timeout",failure.type); assertEquals("已收到",preview.body); assertFalse(complete); assertEquals(1,s.requestCount)
            assertEquals("draft",failure.diagnostics.getString("stage")); assertFalse(failure.diagnostics.toString().contains("已收到"))
        } finally { s.shutdown() }
    }
    @Test fun eofLimitAndFilterDoNotCommitEvenWithValidJson(): Unit=runBlocking {
        val s=MockWebServer(); s.start()
        try {
            for((finish,type) in listOf(null to "stream_interrupted","length" to "output_limit","content_filter" to "content_filter")) {
                s.enqueue(MockResponse().setHeader("Content-Type","text/event-stream").setBody(chunk(valid,finish=finish)))
                val received=mutableListOf<ModelEvent>()
                val failure=runCatching { client().generate(model(s),JSONArray()).collect { received+=it } }.exceptionOrNull()!!
                assertEquals(type,FailureInfo.from(failure).type); assertTrue(received.none { it is ModelEvent.Completed }); assertEquals(valid,received.filterIsInstance<ModelEvent.Delta>().single().text)
            }
        } finally { s.shutdown() }
    }
    @Test fun answerConversionSkipsSelectedPdfAndHasOneAnswerCopyWithFrozenThinking(): Unit=runBlocking {
        val (_,t)=turn()
        val selection=listOf(Selection("m",listOf("pdf")))
        db.dao().putTurn(t.copy(selectionJson=JsonCodec.selections(selection)))
        db.dao().putMessages(listOf(MailMessage("m","a","INBOX",1,1,"会议","HR","hr@example.test",sentAt=0,body="RAW_SHOULD_NOT_UPLOAD")))
        val source=SourceChunk("T1:S1","m","pdf","邀请.pdf","第1页","ALREADY_READ_PDF",imagePath="deleted-image.png",isModelObservation=true)
        val answer=ChatEntry(id="answer",conversationId="c",role="assistant",text="ANSWER_START "+"摘要内容".repeat(200)+" ANSWER_END",sourcesJson=JsonCodec.sources(listOf(source)))
        var count=0; val events=mutableListOf<AgentEvent>()
        val client=object: ModelClient {
            override suspend fun test(profile: ModelProfile)=profile
            override fun generate(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?)=flow {
                count++; assertEquals("disabled",profile.thinkingMode); assertNull(tools)
                val prompt=messages.toString(); assertEquals(1,Regex("ANSWER_END").findAll(prompt).count()); assertFalse(prompt.contains("RAW_SHOULD_NOT_UPLOAD")); assertFalse(prompt.contains("ALREADY_READ_PDF"))
                valid.chunked(3).forEach { emit(ModelEvent.Delta(it)) }; emit(ModelEvent.Completed(roleMessage("assistant",valid)))
            }
        }
        val result=LocalAgent(db.dao(),repository(),processor,client).run("a","INBOX",selection,"将这条回答写成邮件",ChatRequestOptions("disabled").apply(ModelProfile(thinkingMode="enabled")),null,history=listOf(answer),conversationId="c",composeMode=true,requestId="run",targetAnswerId=answer.id,onEvent={ events+=it })
        assertEquals(1,count); assertEquals("hr@example.test",result.candidate!!.draft.to); assertTrue(db.dao().allDrafts().isEmpty())
        assertTrue(events.filterIsInstance<AgentEvent.DraftPreview>().any { it.value.body.isNotEmpty() }); assertTrue(result.sources.any { it.id=="T1:S1" })
    }
    @Test fun checkpointCommitIsAtomicIdempotentAndResumable(): Unit=runBlocking {
        val (entry,_)=turn()
        val result=AnalysisResult("请核对",emptyList(),candidate=DraftCandidate(Draft(accountId="a",subject="会议",body="正文")))
        AgentResultCommitter.checkpoint(db.dao(),entry.id,result)
        val restored=AgentResultCommitter.restored(db.dao().turn(entry.id))!!
        assertEquals(result.candidate!!.draft.id,restored.candidate!!.draft.id)
        val commit=AgentResultCommitter(db,repository())
        val first=commit.commit(entry,restored)!!; val second=commit.commit(entry,result)!!
        assertEquals(first.id,second.id); assertEquals(1L,second.revision); assertEquals(1,db.dao().allDrafts().size)
        assertEquals("complete",AgentRunCheckpoint.from(db.dao().turn(entry.id)).phase)
        val saved=db.dao().history("c").single(); assertEquals(first.id,saved.draftId); assertTrue(saved.draftPreviewJson.isNotBlank())
        recoverAgentRuns(db.dao()); assertEquals("complete",db.dao().history("c").single().resultStatus)
    }
    @Test fun failureAfterDraftWriteRollsBackAllRows(): Unit=runBlocking {
        val (entry,_)=turn(false) // Missing account fails while constructing the confirmation card.
        val result=AnalysisResult("请核对",emptyList(),candidate=DraftCandidate(Draft(accountId="",body="正文")))
        assertNotNull(runCatching { AgentResultCommitter(db,repository()).commit(entry,result) }.exceptionOrNull())
        assertTrue(db.dao().allDrafts().isEmpty()); assertEquals("running",db.dao().history("c").single().resultStatus)
        assertNotEquals("complete",AgentRunCheckpoint.from(db.dao().turn(entry.id)).phase)
    }
    @Test fun interruptedRunRecoversPartialAndKeepsCompletedReasoning(): Unit=runBlocking {
        val (entry,_)=turn()
        db.dao().putEntry(entry.copy(reasoningText="实际思考",reasoningState="completed"))
        AgentCheckpoints.update(db.dao(),entry.id) { it.put("phase","generating").put("preview",DraftPartial("主题","部分正文").json()) }
        recoverAgentRuns(db.dao())
        val saved=db.dao().history("c").single(); assertEquals("failed",saved.resultStatus); assertEquals("completed",saved.reasoningState)
        assertEquals("部分正文",JSONObject(saved.failureJson).getJSONObject("draftPartial").getString("body")); assertTrue(saved.draftId.isBlank())
        assertTrue(db.dao().allDrafts().isEmpty())
        assertEquals("",AgentRunCheckpoint.from(TurnSnapshot("old","c","a","INBOX","[]",1)).phase)
    }
    @Test fun pendingOrChangedDraftCannotBeOverwrittenOnCommit(): Unit=runBlocking {
        val (entry,_)=turn()
        for(status in listOf("SENDING","UNKNOWN","SENT")) {
            val original=Draft(id="draft",accountId="a",body="原稿",status=status,revision=3); db.dao().putDraft(original)
            assertNotNull(runCatching { AgentResultCommitter(db,repository()).commit(entry,AnalysisResult("",emptyList(),candidate=DraftCandidate(original.copy(body="新版")))) }.exceptionOrNull())
            assertEquals(original,db.dao().draft(original.id))
        }
    }
    @Test fun reasoningCompletionIsIndependentOfLaterAnswerFailure() {
        val trace=ReasoningTrace(); trace.append("已完成实际思考"); trace.finish(); trace.finish("interrupted"); assertEquals("completed",trace.snapshot().state)
        trace.append("下一次真实思考"); trace.finish("interrupted"); assertEquals("interrupted",trace.snapshot().state)
    }
    @Test fun completedVisionIsReusedButChangedFileIsReadAgain(): Unit=runBlocking {
        turn()
        val file=File.createTempFile("vision103",".png").apply { writeBytes(byteArrayOf(1,2,3)) }
        try {
            var calls=0
            val client=object: ModelClient {
                override suspend fun test(profile: ModelProfile)=profile
                override fun generate(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?)=flow { calls++; emit(ModelEvent.Completed(roleMessage("assistant","已读到会议时间为周五"))) }
            }
            val source=SourceChunk("T2:S1","m","image","邀请.png","图片",imagePath=file.path)
            val reader=VisionReader(client); val model=ModelProfile(model="vision",baseUrl="https://example.test/v1")
            repeat(2) { assertTrue(reader.read(listOf(source),"总结",listOf(model),{},db.dao(),"run").first.getValue(source.id).contains("周五")) }
            assertEquals(1,calls)
            file.appendBytes(byteArrayOf(4))
            reader.read(listOf(source),"总结",listOf(model),{},db.dao(),"run")
            assertEquals(2,calls)
        } finally { file.delete() }
    }
    @Test fun repeatedToolWithoutNewInputStopsEarly(): Unit=runBlocking {
        var calls=0
        val client=object: ModelClient {
            override suspend fun test(profile: ModelProfile)=profile
            override fun generate(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?)=flow {
                calls++
                emit(ModelEvent.Completed(roleMessage("assistant","").put("tool_calls",JSONArray().put(JSONObject().put("id","call$calls").put("function",JSONObject().put("name","create_draft").put("arguments","{\"to\":\"\",\"subject\":\"主题\",\"body\":\"正式正文\"}"))))))
            }
        }
        val failure=runCatching { LocalAgent(db.dao(),repository(),processor,client).run("a","INBOX",emptyList(),"查询信息",ModelProfile(supportsTools=true),null) }.exceptionOrNull()!!
        assertEquals("action_format",FailureInfo.from(failure).type); assertEquals(3,calls); assertTrue(db.dao().allDrafts().isEmpty())
    }
    @Test fun structuredPolicyRespectsKnownModelModeAndLeavesUnknownUntouched() {
        val qwen=ModelProfile(baseUrl="https://dashscope.aliyuncs.com/compatible-mode/v1",model="qwen3.5-plus",thinkingMode="enabled")
        assertFalse(ResponseFormatPolicy.jsonObject(qwen)); assertTrue(ResponseFormatPolicy.jsonObject(qwen.copy(thinkingMode="disabled")))
        assertTrue(ResponseFormatPolicy.jsonObject(qwen.copy(model="qwen3.8-max")))
        assertFalse(ResponseFormatPolicy.jsonObject(qwen.copy(baseUrl="https://unknown.test/v1",thinkingMode="disabled")))
        val frozen=ChatRequestOptions("enabled").freeze(qwen.copy(reasoningEffort="high",thinkingBudget=8192))
        assertEquals(8192,ChatRequestOptions.parse(JSONObject(frozen.json())).apply(qwen.copy(thinkingBudget=0)).thinkingBudget)
        assertEquals("enabled",frozen.thinking)
    }
}
