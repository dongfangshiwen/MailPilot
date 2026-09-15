package app.mailpilot

import androidx.room.Room
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import app.mailpilot.ai.*
import app.mailpilot.attachments.AndroidAttachmentProcessor
import app.mailpilot.data.*
import app.mailpilot.mail.MailRepositoryImpl
import app.mailpilot.services.*
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import org.json.*
import org.junit.Test
import org.junit.Assert.*
import org.junit.runner.RunWith

/** Full Android Agent, synthetic public sources, in-memory Room, no saved credentials. */
@RunWith(AndroidJUnit4::class)
class ContextReviewDevice41Test {
    @Test fun repeatedSearchRebindsFetchedPageWithoutAnotherNetworkAcquisition()=runBlocking {
        val context=InstrumentationRegistry.getInstrumentation().targetContext
        val db=Room.inMemoryDatabaseBuilder(context,MailDatabase::class.java).build()
        try {
            db.dao().putConversation(Conversation(id="context41"))
            for(native in listOf(false,true)) {
                var requests=0; var searches=0; var pages=0
                val fact="Verified public fixture amount 730."
                val client=object: ModelClient {
                    override suspend fun test(profile: ModelProfile)=profile
                    override fun generate(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?)=flow {
                        requests++
                        if(requests==4) {
                            val latest=(0 until messages.length()).map { messages.getJSONObject(it) }.last { it.optString("role")=="tool" || it.optString("content").startsWith("应用动作执行结果") }
                            assertTrue(latest.optString("content").contains(fact))
                            emit(ModelEvent.Completed(roleMessage("assistant","已核对。[S1]")))
                        } else {
                            val name=if(requests==2) "read_web_page" else "web_search"
                            val args=if(requests==2) JSONObject().put("source_ids",JSONArray(listOf("S1"))) else JSONObject().put("queries",JSONArray(listOf("public fixture")))
                            emit(ModelEvent.Completed(roleMessage("assistant",JSONObject().put("mailpilot_action",name).put("arguments",args).toString())))
                        }
                    }
                }
                val agent=LocalAgent(db.dao(),MailRepositoryImpl(db,AndroidSecrets(),context.cacheDir),AndroidAttachmentProcessor(context),client,
                    object: WebSearchClient { override suspend fun search(config: ServiceConfig,query: String): List<SourceChunk> {
                        searches++; return listOf(SourceChunk(messageId="",title="fixture",location="search",kind="web",url="https://example.org/record",text="Search excerpt only"))
                    } }).apply { pageReader=WebPageReader { pages++; WebPage(fact,"complete") } }
                val result=agent.run("","INBOX",emptyList(),"核对公开资料",ModelProfile(thinkingMode="disabled",supportsTools=native),null,
                    conversationId="context41",options=ChatRequestOptions(webSearch=true))
                assertEquals(4,requests); assertEquals(1,searches); assertEquals(1,pages); assertFalse(result.partial); assertTrue(db.dao().allDrafts().isEmpty())
            }
        } finally { db.close() }
    }
}
