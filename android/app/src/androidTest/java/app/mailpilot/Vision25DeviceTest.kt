package app.mailpilot

import androidx.room.Room
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import app.mailpilot.ai.*
import app.mailpilot.attachments.AndroidAttachmentProcessor
import app.mailpilot.data.*
import app.mailpilot.mail.MailRepositoryImpl
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import org.json.*
import org.junit.Assert.*
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File

/** Opt-in real service test through the same LocalAgent, processor and HTTP client shipped in the APK.
 * Only synthetic local files are used. The credential is injected into private app storage externally.
 * Default device regression runs skip live calls when that private file is absent. */
@RunWith(AndroidJUnit4::class)
class Vision25DeviceTest {
    @Test fun arkFiveAndTenThroughFullAgent(): Unit=runBlocking {
        val context=InstrumentationRegistry.getInstrumentation().targetContext
        val secretFile=File(context.filesDir,"test25-ark-key")
        assumeTrue("Real Ark credential was not supplied",secretFile.isFile)
        val key=secretFile.readText().trim()
        secretFile.delete()
        val dbName="live25-${System.nanoTime()}.db"
        var db=Room.databaseBuilder(context,MailDatabase::class.java,dbName).build()
        val secrets=AndroidSecrets()
        val report=JSONArray()
        try {
            for(count in listOf(5,10)) {
                val dao=db.dao(); val conversation="live-$count"
                dao.putAccount(MailAccount(id="synthetic25",email="synthetic@example.test"))
                dao.putConversation(Conversation(id=conversation,accountId="synthetic25"))
                dao.putMessages(listOf(MailMessage("mail$count","synthetic25","INBOX",1,count.toLong(),"Synthetic verification","sender","sender@example.test",sentAt=0,
                    body="The batch label is ORDER-25. Include this label in your answer together with all images.")))
                val materials=(1..count).map { n ->
                    val file=File(context.filesDir,"test25-images/ark-image-${n.toString().padStart(2,'0')}.jpg")
                    check(file.isFile) { "Synthetic fixture missing" }
                    LocalMaterial(id="$conversation-file$n",conversationId=conversation,name="sample$n.jpg",mime="image/jpeg",path=file.path,size=file.length()).also { dao.putMaterial(it) }
                }
                val selection=listOf(Selection("mail$count"))
                val profile=ModelProfile(label="火山套餐合成资料验证",provider="volcengine",model="doubao-seed-evolving",baseUrl="https://ark.cn-beijing.volces.com/api/plan/v3",
                    apiKeyCipher=secrets.encrypt(key),contextTokens=32768,outputTokens=4096,thinkingMode="disabled")
                val options=ChatRequestOptions(thinking="disabled")
                val prompt="Read the order label from the selected mail text and inspect every attached image. Reply as plain Markdown, one line for each image with its printed number, color (red/blue/green/orange/purple) and shape (circle/rectangle). Do not skip any image or invent details."
                val turnId="run-$count"
                dao.putTurn(TurnSnapshot(turnId,conversation,"synthetic25","INBOX",JsonCodec.selections(selection),1,options.json(),localJson=JSONArray(materials.map { it.fields() }).toString(),requestJson=JSONObject().put("question",prompt).toString()))
                val events=mutableListOf<JSONObject>(); val progress=mutableListOf<String>()
                val real=CompatibleModelClient(secrets)
                var payloads=0; var firstDeltaMs: Long?=null
                val start=System.nanoTime()
                // Inspect request structure in process; record only counts, never text or credentials.
                val client=object: ModelClient {
                    override suspend fun test(profile: ModelProfile)=error("No diagnostics during live analysis")
                    override fun generate(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?)=generateRequest(profile,messages,tools,forceStream)
                    override fun generateRequest(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?,options: ModelRequestOptions): Flow<ModelEvent> {
                        payloads++
                        if(payloads==1) {
                            assertEquals(count,VisionRequestPlanner.imageCount(messages))
                            val text=(0 until messages.length()).joinToString("\n") { n ->
                                val content=messages.getJSONObject(n).opt("content")
                                if(content is JSONArray) (0 until content.length()).joinToString("\n") { content.getJSONObject(it).optString("text") } else content.toString()
                            }
                            assertTrue("Selected mail body missing",text.contains("ORDER-25")); assertTrue("Original question missing",text.contains(prompt))
                            assertFalse(messages.toString().contains("文档视觉阅读助手")); assertEquals("disabled",profile.thinkingMode)
                        }
                        return real.generateRequest(profile,messages,tools,forceStream,options)
                    }
                }
                val agent=LocalAgent(dao,MailRepositoryImpl(db,secrets,context.filesDir),AndroidAttachmentProcessor(context),client)
                val result=agent.run("synthetic25","INBOX",selection,prompt,profile,null,conversationId=conversation,requestId=turnId,localMaterials=materials,options=options,
                    onDelta={ if(it.isNotEmpty() && firstDeltaMs==null) firstDeltaMs=(System.nanoTime()-start)/1_000_000 },onProgress={ progress+=it },onEvent={ if(it is AgentEvent.Diagnostics) events+=JSONObject(it.value.toString()) })
                assertEquals(1,payloads)
                assertTrue(result.text.contains("ORDER-25"))
                assertTrue(progress.none { it.contains("批") })
                for(n in 1..count) assertTrue("Missing image number $n",Regex("(?<![0-9])$n(?![0-9])").containsMatchIn(result.text))
                val transfer=events.filter { it.optString("event")=="request_body_sent" }
                assertEquals(1,transfer.size); assertEquals(count,transfer.single().getInt("imagesInRequest"))
                val item=JSONObject().put("images",count).put("generationRequests",payloads).put("uploadRequests",transfer.size).put("bodyBytes",transfer.single().getLong("bodyBytes"))
                    .put("firstDeltaMs",firstDeltaMs).put("elapsedMs",(System.nanoTime()-start)/1_000_000).put("model",profile.model).put("endpointKind","ark_plan")
                    .put("contextTokens",32768).put("thinking","disabled").put("mailTextAndQuestionInSameRequest",true).put("allPrintedNumbersPresent",true)
                // Close/reopen the database and create a new agent: follow-up must not re-upload.
                db.close(); db=Room.databaseBuilder(context,MailDatabase::class.java,dbName).build()
                var followUploads=-1
                val reuseClient=object: ModelClient {
                    override suspend fun test(profile: ModelProfile)=profile
                    override fun generate(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?)=flow {
                        followUploads=VisionRequestPlanner.imageCount(messages)
                        assertTrue(messages.toString().contains("此前分析"))
                        emit(ModelEvent.Completed(roleMessage("assistant","已使用此前完成的图片分析。")))
                    }
                }
                LocalAgent(db.dao(),MailRepositoryImpl(db,secrets,context.filesDir),AndroidAttachmentProcessor(context),reuseClient)
                    .run("synthetic25","INBOX",selection,"继续依据此前分析解释",profile,null,conversationId=conversation,localMaterials=materials)
                assertEquals(0,followUploads)
                item.put("reopenedCacheUploadsMockFollowup",followUploads)
                report.put(item)
                File(context.filesDir,"test25-live-report.json").writeText(JSONObject().put("path","APK LocalAgent -> AndroidAttachmentProcessor -> CompatibleModelClient").put("results",report).toString(2))
            }
        } finally { db.close(); context.deleteDatabase(dbName); secretFile.delete() }
    }
}
