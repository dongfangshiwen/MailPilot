package app.mailpilot

import android.app.Application
import android.graphics.Bitmap
import androidx.room.Room
import app.mailpilot.ai.*
import app.mailpilot.attachments.*
import app.mailpilot.data.*
import app.mailpilot.mail.*
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import org.json.*
import org.junit.*
import org.junit.Assert.*
import org.junit.runner.RunWith
import org.robolectric.*
import org.robolectric.annotation.Config
import java.io.File

@RunWith(RobolectricTestRunner::class)
@Config(sdk=[28],application=Application::class)
class Vision24Test {
    private lateinit var db: MailDatabase
    private val app get()=RuntimeEnvironment.getApplication()
    private val visual=ModelProfile(model="deepseek-v4-flash-vision-exp",baseUrl="https://api.deepseek.com/v1",provider="deepseek",contextTokens=1048576)
    @Before fun setup() { db=Room.inMemoryDatabaseBuilder(app,MailDatabase::class.java).allowMainThreadQueries().build() }
    @After fun close() { db.close() }
    private fun image(index: Int): File=File(app.filesDir,"fixture24-$index.png").also { file ->
        val b=Bitmap.createBitmap(64,48,Bitmap.Config.ARGB_8888); b.eraseColor(index or 0xff000000.toInt())
        file.outputStream().use { b.compress(Bitmap.CompressFormat.PNG,100,it) }; b.recycle()
    }
    private fun source(index: Int)=SourceChunk(id="T1:S$index",messageId="",title="图片$index",location="图片",imagePath=image(index).path,assetKey="asset-$index",imageWidth=64,imageHeight=48)
    private suspend fun files(count: Int,conversation: String="c"): List<LocalMaterial> {
        if(db.dao().conversation(conversation)==null) db.dao().putConversation(Conversation(id=conversation))
        return (1..count).map { i -> LocalMaterial(id="local-$conversation-$i",conversationId=conversation,name="$i.png",mime="image/png",path=image(i).path,size=image(i).length()).also { db.dao().putMaterial(it) } }
    }
    private var processed=0
    private val processor=object: AttachmentProcessor {
        override suspend fun pdfCount(file: File)=1
        override suspend fun previewPdf(file: File,page: Int)=file
        override suspend fun process(attachment: Attachment,pages: List<Int>,onProgress: (String)->Unit): List<SourceChunk> {
            processed++
            return listOf(SourceChunk(messageId=attachment.messageId,attachmentId=attachment.id,title=attachment.name,location="图片",imagePath=attachment.localPath))
        }
    }
    private class CountingClient: ModelClient {
        val uploads=mutableListOf<Int>(); val messages=mutableListOf<JSONArray>()
        val profiles=mutableListOf<ModelProfile>()
        var failure: String?=null
        var failuresRemaining=Int.MAX_VALUE
        override suspend fun test(profile: ModelProfile)=profile
        override fun generate(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?)=flow {
            this@CountingClient.messages+=messages
            profiles+=profile
            val parts=(0 until messages.length()).flatMap { i -> messages.getJSONObject(i).optJSONArray("content")?.let { a -> (0 until a.length()).map { a.optJSONObject(it) } }.orEmpty() }
            uploads+=parts.count { it is LocalImagePart }
            emit(ModelEvent.Diagnostics(JSONObject().put("event","request_body_sent").put("attemptId",newId()).put("imagesInRequest",uploads.last())))
            failure?.takeIf { failuresRemaining-->0 }?.let { throw ModelFailure(FailureInfo(it,"fixture")) }
            val helper=messages.toString().contains("文档视觉阅读助手")
            val answer=if(helper) JSONObject().put("results",JSONArray(parts.filterIsInstance<LocalImagePart>().map { JSONObject().put("id",it.source.id).put("text","可见文字与数字：24") })).toString() else "已核对选中的图片，可见编号与图形。[T1:S1]"
            emit(ModelEvent.Delta(answer)); emit(ModelEvent.Completed(roleMessage("assistant",answer)))
        }
    }
    private fun agent(client: ModelClient)=LocalAgent(db.dao(),MailRepositoryImpl(db,PlainTestSecrets(),app.filesDir),processor,client)
    private suspend fun ask(client: ModelClient,files: List<LocalMaterial>,p: ModelProfile=visual,helper: ModelProfile?=null,question: String="说明图片",run: String="") =
        agent(client).run("","INBOX",emptyList(),question,p,helper,conversationId=files.first().conversationId,localMaterials=files,requestId=run)

    @Test fun fullAgentKeepsFiveAndTenPicturesWithQuestionAndMailAcrossProviders(): Unit=runBlocking {
        val ark=visual.copy(model="doubao-seed-evolving",provider="volcengine",contextTokens=32768)
        val profiles=listOf(ark.copy(baseUrl="https://ark.cn-beijing.volces.com/api/plan/v3"),ark.copy(baseUrl="https://ark.cn-beijing.volces.com/api/v3"),
            visual.copy(model="qwen3-vl-flash",provider="aliyun",baseUrl="https://dashscope.aliyuncs.com/compatible-mode/v1",contextTokens=32768),visual.copy(contextTokens=32768))
        db.dao().putAccount(MailAccount(id="mail",email="a@example.test"))
        db.dao().putMessages(listOf(MailMessage("mail-id","mail","INBOX",1,1,"正文核对","sender","sender@example.test",sentAt=0,body="本邮件要求核对全部图中数字，订单编号 ORDER-25。")))
        for((index,p) in profiles.withIndex()) for(count in listOf(5,10)) for(thinking in listOf("disabled","enabled")) {
            val conversation="full-$index-$count-$thinking"
            val fs=files(count,conversation)
            db.dao().putConversation(Conversation(id=conversation,accountId="mail"))
            val c=CountingClient(); val progress=mutableListOf<String>(); val events=mutableListOf<AgentEvent>()
            agent(c).run("mail","INBOX",listOf(Selection("mail-id")),"结合订单和图片核对数量。",p.copy(thinkingMode=thinking),null,
                conversationId=conversation,localMaterials=fs,onProgress={ progress+=it },onEvent={ events+=it })
            assertEquals(listOf(count),c.uploads)
            val body=okio.Buffer(); ModelJsonBody(JSONObject().put("messages",c.messages.single())).writeTo(body)
            val raw=body.readUtf8()
            assertTrue(raw.contains("ORDER-25")); assertTrue(raw.contains("结合订单和图片核对数量")); assertFalse(raw.contains("文档视觉阅读助手"))
            assertEquals(count,Regex("data:image/png;base64").findAll(raw).count())
            assertTrue(progress.any { it=="正在分析 $count 张图片" }); assertTrue(progress.none { it.contains("批") })
            assertEquals(thinking,c.profiles.single().thinkingMode)
            val v=events.filterIsInstance<AgentEvent.VisionProgress>().last()
            assertEquals(1,v.imageRequests); assertEquals(count,v.uploadedImages); assertEquals("complete",v.mode)
        }
        assertNull(ModelCapabilityResolver.contextEntry(profiles.first()))
        assertEquals(32768,ModelContextPolicy.resolve(profiles.first()).contextTokens)
        assertEquals("ark_plan",ModelCapabilityResolver.endpointKind(profiles.first()))
    }
    @Test fun onlyImageUnsupportedFallsBackAndDraftAlsoRequiresChoice(): Unit=runBlocking {
        val fs=files(5)
        for(type in listOf("read_timeout","permission","rate_limit","result_format","request_size","context_limit","image_count_limit")) {
            val c=CountingClient().apply { failure=type }
            val e=runCatching { ask(c,fs) }.exceptionOrNull() as ModelFailure
            assertEquals(listOf(5),c.uploads)
            assertEquals(type,e.info.type)
            assertEquals(type in setOf("request_size","context_limit","image_count_limit"),e.info.action=="multimodal_choice")
        }
        val draft=CountingClient().apply { failure="request_size" }
        val e=runCatching { agent(draft).run("","INBOX",emptyList(),"请按资料拟写一封说明邮件",visual,null,conversationId="c",localMaterials=fs,composeMode=true) }.exceptionOrNull() as ModelFailure
        assertEquals("multimodal_choice",e.info.action); assertEquals(listOf(5),draft.uploads)
        val supported=CountingClient().apply { failure="image_unsupported"; failuresRemaining=1 }
        ask(supported,fs,helper=visual.copy(model="qwen3-vl-flash",provider="aliyun",baseUrl="https://dashscope.aliyuncs.com/compatible-mode/v1"))
        assertEquals(listOf(5,5,0),supported.uploads)
    }
    @Test fun longHistoryCompactsWithoutSendingImagesToTheCompressor(): Unit=runBlocking {
        val fs=files(5); val c=CountingClient()
        val history=(1..8).map { n -> ChatEntry(id="history-$n",conversationId="c",role=if(n%2==1) "user" else "assistant",text=if(n<=4) "已确认项目的事实和限制。".repeat(1500) else "近期对话 $n",createdAt=n.toLong()).also { db.dao().putEntry(it) } }
        val p=visual.copy(model="doubao-seed-evolving",provider="volcengine",baseUrl="https://ark.cn-beijing.volces.com/api/plan/v3",contextTokens=32768,thinkingMode="disabled")
        val stages=mutableListOf<AgentEvent>()
        agent(c).run("","INBOX",emptyList(),"根据图片和前面的说明回答",p,null,history=history,conversationId="c",localMaterials=fs,onEvent={ stages+=it })
        assertTrue(c.uploads.size>1); assertEquals(listOf(5),c.uploads.filter { it>0 })
        assertEquals(5,c.uploads.last()); assertTrue(c.messages.last().toString().contains("根据图片和前面的说明回答"))
        assertTrue(stages.filterIsInstance<AgentEvent.Stage>().any { it.name=="compression" })
    }
    @Test fun batchChoiceIsTurnLocalAndSingleFailureDoesNotLoseCompletedObservations(): Unit=runBlocking {
        val old=ChatRequestOptions.parse(JSONObject("{\"thinking\":\"disabled\"}"))
        assertEquals("complete",old.imageMode)
        assertEquals("batch",ChatRequestOptions.parse(JSONObject(old.copy(imageMode="batch").json())).imageMode)
        val fs=files(5); val c=CountingClient()
        val fixed=visual.copy(model="qwen3-vl-flash",provider="aliyun",baseUrl="https://dashscope.aliyuncs.com/compatible-mode/v1")
        agent(c).run("","INBOX",emptyList(),"说明图片",visual,fixed,conversationId="c",localMaterials=fs,options=old.copy(imageMode="batch"))
        assertEquals(listOf(3,2,0),c.uploads); assertTrue(c.profiles.all { it.model==visual.model })
        ask(c,fs,question="编辑后的问题"); assertEquals(0,c.uploads.last())
        val next=CountingClient(); ask(next,files(5,"next")); assertEquals(listOf(5),next.uploads)
    }

    @Test fun fiveImagesDirectOneCallThenReuseAppendAndRestart(): Unit=runBlocking {
        val five=files(5); val c=CountingClient()
        val first=ask(c,five)
        assertEquals(listOf(5),c.uploads); assertEquals(5,processed)
        assertTrue(first.sources.all { it.assetKey.isNotBlank() })
        ask(c,five,question="重新编辑后的追问")
        assertEquals(listOf(5,0),c.uploads); assertEquals(5,processed)
        assertTrue(c.messages.last().toString().contains("此前分析"))
        val six=files(6); ask(c,six)
        assertEquals(listOf(5,0,1),c.uploads); assertEquals(6,processed)
        // A new agent/store instance (same persisted DAO) still has all evidence.
        ask(c,six,p=visual.copy(model="qwen3-vl-plus",provider="aliyun",baseUrl="https://dashscope.aliyuncs.com/compatible-mode/v1"))
        assertEquals(0,c.uploads.last())
    }
    @Test fun textMainUsesOneHelperThenOneAnswerAndReuses(): Unit=runBlocking {
        val fs=files(5); val c=CountingClient(); val text=visual.copy(model="deepseek-v4-flash")
        ask(c,fs,text,visual)
        assertEquals(listOf(5,0),c.uploads)
        ask(c,fs,text,visual,question="补充说明")
        assertEquals(listOf(5,0,0),c.uploads)
        assertEquals(5,db.dao().visualEvidence("c","").size)
    }
    @Test fun failedAnswerIsNotCachedAndScopesCannotReuse(): Unit=runBlocking {
        val fs=files(1); val c=CountingClient().apply { failure="read_timeout" }
        assertTrue(runCatching { ask(c,fs) }.isFailure)
        assertTrue(db.dao().visualEvidence("c","").isEmpty())
        c.failure=null; ask(c,fs)
        assertTrue(VisualEvidenceStore(db.dao(),"c","other-account").lookup(listOf(source(1)),emptySet()).records.isEmpty())
        ask(c,files(1,"other")); assertEquals(listOf(1,1,1),c.uploads)
    }
    @Test fun foreignScopeAndCheckpointAreRejectedBeforeProcessing(): Unit=runBlocking {
        val fs=files(1); val c=CountingClient()
        db.dao().putConversation(Conversation(id="c",accountId="owner"))
        assertTrue(runCatching { ask(c,fs) }.isFailure)
        assertEquals(0,processed); assertTrue(c.uploads.isEmpty())
        db.dao().putConversation(Conversation(id="c"))
        db.dao().putConversation(Conversation(id="foreign",accountId="owner"))
        val turn=TurnSnapshot("foreign-run","foreign","owner","INBOX","[]",1,requestJson="{\"marker\":24}")
        db.dao().putTurn(turn)
        assertTrue(runCatching { ask(c,fs,run=turn.id) }.isFailure)
        assertEquals(turn.requestJson,db.dao().turn(turn.id)!!.requestJson)
        assertEquals(0,processed); assertTrue(c.uploads.isEmpty())
    }
    @Test fun legacyObservationsRequireMatchingPixelsAndDoNotCrossSnapshotScope(): Unit=runBlocking {
        db.dao().putConversation(Conversation(id="c")); val store=VisualEvidenceStore(db.dao(),"c","")
        val current=source(1).copy(attachmentId="file")
        val legacyFile=File(app.filesDir,"legacy24.png").also { File(current.imagePath).copyTo(it,overwrite=true) }
        val old=current.copy(id="T1:S9",assetKey="",imagePath=legacyFile.path,isModelObservation=true,text="可见金额 24 [T1:S9]")
        val entry=ChatEntry(id="legacy",conversationId="c",role="assistant",text="已完成",sourcesJson=JsonCodec.sources(listOf(old)))
        store.importVerified(listOf(entry),listOf(current))
        val reuse=store.lookup(listOf(current.copy(id="T7:S1")),emptySet())
        assertTrue(reuse.missing.isEmpty()); assertTrue(reuse.sources.single().text.contains("[T7:S1]"))
        assertTrue(VisualEvidenceStore(db.dao(),"c","another").lookup(listOf(current),emptySet(),reuse.records).records.isEmpty())
        val changed=source(2).copy(attachmentId="file")
        store.importVerified(listOf(entry),listOf(changed))
        assertEquals(listOf(changed),store.lookup(listOf(changed),emptySet()).missing)
        // Retain legacy preview paths until the owning conversation is removed.
        db.dao().putEntry(entry)
        assertTrue(db.dao().retainedImageSources().flatMap { JsonCodec.sources(it) }.any { it.imagePath==legacyFile.path })
    }
    @Test fun explicitServerSizeLimitRequiresChoiceAndPermissionDoesNotSplit(): Unit=runBlocking {
        val fs=files(5)
        val permission=CountingClient().apply { failure="permission" }
        assertTrue(runCatching { ask(permission,fs) }.isFailure)
        assertEquals(listOf(5),permission.uploads)
        val limited=CountingClient().apply { failure="request_size"; failuresRemaining=1 }
        val failure=runCatching { ask(limited,fs) }.exceptionOrNull() as ModelFailure
        assertEquals("multimodal_choice",failure.info.action)
        assertEquals(listOf(5),limited.uploads)
        agent(limited).run("","INBOX",emptyList(),"说明图片",visual,null,conversationId="c",localMaterials=fs,options=ChatRequestOptions(imageMode="batch"))
        assertEquals(listOf(5,3,2,0),limited.uploads)
    }
    @Test fun manualRecheckUploadsOnlyMarkedImage(): Unit=runBlocking {
        val fs=files(5); val c=CountingClient(); val result=ask(c,fs)
        val forced=result.sources[2].assetKey
        db.dao().putTurn(TurnSnapshot("recheck","c","","INBOX","[]",2,localJson=JSONArray(fs.map { it.fields() }).toString(),requestJson=JSONObject().put("recheckAssets",JSONArray().put(forced)).toString()))
        ask(c,fs,run="recheck"); assertEquals(listOf(5,1),c.uploads)
        val raw=c.messages.last().let { ModelJsonBody(JSONObject().put("messages",it)) }.let { body -> okio.Buffer().also { body.writeTo(it) }.readUtf8() }
        assertEquals(1,Regex("data:image/png;base64").findAll(raw).count())
    }
    @Test fun groupEvidenceNeverAssignsCombinedFactsToSubset(): Unit=runBlocking {
        db.dao().putConversation(Conversation(id="c")); val store=VisualEvidenceStore(db.dao(),"c","")
        val items=(1..2).map(::source)
        store.save(items,"比较两图","第一张金额 999，第二张 24","fixture","answer","r1")
        val subset=store.lookup(items.take(1),emptySet())
        assertTrue(subset.missing.isEmpty()); assertFalse(subset.sources.single().text.contains("999"))
        assertTrue(subset.sources.single().text.contains("重新核对"))
        val full=store.lookup(items.mapIndexed { i,s -> s.copy(id="T9:S${i+1}") },emptySet())
        assertEquals(1,full.sources.count { it.text.contains("999") })
    }
    @Test fun jsonLengthMimeAndBase64MatchActualBytes() {
        for(size in listOf(1,2,3,24575,24576,24577,50000)) {
            val f=File(app.filesDir,"encoding24").apply { writeBytes(ByteArray(size) { (it%251).toByte() }) }
            val p=JSONObject().put("中文\n\"",JSONArray().put("emoji😀\n\\").put(JSONObject.NULL).put(1.2).put(LocalImagePart(source(1).copy(imagePath=f.path))))
            val body=ModelJsonBody(p); val buffer=okio.Buffer(); body.writeTo(buffer)
            assertEquals(body.contentLength(),buffer.size)
            val decoded=JSONObject(buffer.readUtf8()).getJSONArray("中文\n\"").getJSONObject(3).getJSONObject("image_url").getString("url").substringAfter("base64,")
            assertArrayEquals(f.readBytes(),java.util.Base64.getDecoder().decode(decoded))
        }
    }
    @Test fun limitsUseProviderAndTransportAndKeepFiveTogether() {
        val images=(1..10).map(::source)
        assertEquals(1,VisionRequestPlanner.plan(visual,images).batches.size)
        assertEquals(600,VisionRequestPlanner.limits(visual).images)
        assertEquals(32L*1024*1024,VisionRequestPlanner.limits(visual).body)
        val ark=visual.copy(model="doubao-seed-evolving",provider="volcengine",baseUrl="https://ark.cn-beijing.volces.com/api/v3")
        assertEquals(1,VisionRequestPlanner.plan(ark,images).batches.size)
        assertNull(VisionRequestPlanner.limits(ark).images)
        assertNull(VisionRequestPlanner.limits(visual.copy(baseUrl="https://proxy.example/v1")).images)
        val proxy=visual.copy(baseUrl="https://proxy.example/v1",contextTokens=32768)
        assertEquals(1,VisionRequestPlanner.plan(proxy,images).batches.size)
        assertTrue(VisionRequestPlanner.plan(proxy,images,allowBatch=true).batches.size>1)
        val p=JSONObject().put("s","hello")
        assertTrue(runCatching { ModelJsonBody(p,1).contentLength() }.isFailure)
    }
    @Test fun conversationSearchMatchesContentLiterallyWithinAccount(): Unit=runBlocking {
        db.dao().putConversation(Conversation(id="a",accountId="owner",title="普通标题"))
        db.dao().putConversation(Conversation(id="b",accountId="foreign",title="合同金额"))
        db.dao().putEntry(ChatEntry(conversationId="a",role="assistant",text="合同金额 48000 元，Discount 5%_abc"))
        suspend fun search(q: String)=db.dao().conversationPage("owner",true,0,0,"",50,q).map { it.id }
        assertEquals(listOf("a"),search("合同金额")); assertEquals(listOf("a"),search("discount"))
        assertEquals(listOf("a"),search("%_"));assertTrue(search("' OR 1=1 --").isEmpty())
    }
    @Test fun historyPaginationOverFiveHundredAndDeletionRetainsMailAndDraft(): Unit=runBlocking {
        db.dao().putAccount(MailAccount(id="a",email="a@example.test"))
        repeat(503) { i -> db.dao().putConversation(Conversation(id="c$i",accountId="a",createdAt=i.toLong(),lastActivityAt=i.toLong(),pinnedAt=if(i%17==0) 20 else 0)) }
        db.dao().putConversation(Conversation(id="foreign",accountId="b"))
        val all=mutableListOf<ConversationHeader>(); var cursor: ConversationHeader?=null
        do { val page=db.dao().conversationPage("a",cursor==null,cursor?.pinnedAt ?: 0,cursor?.lastActivityAt ?: 0,cursor?.id.orEmpty(),50); all+=page; cursor=page.lastOrNull() } while(cursor!=null)
        assertEquals(503,all.size); assertEquals(503,all.map { it.id }.toSet().size)
        val before=db.dao().conversation("c1")!!; db.dao().renameConversation("c1","新名称"); db.dao().pinConversations(listOf("c1"),123)
        assertEquals(before.lastActivityAt,db.dao().conversation("c1")!!.lastActivityAt)
        db.dao().putDraft(Draft(id="d",accountId="a",body="独立草稿"))
        VisualEvidenceStore(db.dao(),"c1","a").save(listOf(source(1)),"q","观察","m","answer","r")
        db.dao().deleteConversation("c1")
        assertTrue(db.dao().visualEvidence("c1","a").isEmpty()); assertNotNull(db.dao().draft("d"))
    }
}
