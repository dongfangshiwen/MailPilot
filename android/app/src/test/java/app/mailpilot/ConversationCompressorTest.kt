package app.mailpilot

import android.app.Application
import android.database.sqlite.SQLiteDatabase
import androidx.room.Room
import app.mailpilot.ai.*
import app.mailpilot.data.*
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.flow
import org.json.JSONArray
import org.json.JSONObject
import org.junit.*
import org.junit.Assert.*
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import java.io.File
import java.io.IOException

@RunWith(RobolectricTestRunner::class)
@Config(sdk=[28],application=Application::class)
class ConversationCompressorTest {
    private lateinit var db: MailDatabase
    private val model=ModelProfile(model="test",contextTokens=16384,outputTokens=1024)
    @Before fun setup() { db=Room.inMemoryDatabaseBuilder(RuntimeEnvironment.getApplication(),MailDatabase::class.java).allowMainThreadQueries().build() }
    @After fun close() { db.close() }
    private class FakeClient(val answer: String="用户预算 500 元，周五交付；保持中文回答，未完成事项是核对清单。"): ModelClient {
        val requests=mutableListOf<String>()
        var failure: Exception?=null
        var during: (suspend () -> Unit)?=null
        override fun generate(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?)=flow {
            assertNull(tools); requests+=messages.toString()
            during?.invoke(); failure?.let { throw it }
            emit(ModelEvent.Completed(roleMessage("assistant",answer)))
        }
        override suspend fun test(profile: ModelProfile)=profile
    }
    private fun entries(count: Int=20,size: Int=120)=(0 until count).map {
        ChatEntry(id="entry-$it",conversationId="chat",role=if(it%2==0) "user" else "assistant",text="唯一事实-$it 周五交付，预算 500 元。"+"资料".repeat(size/2),createdAt=it.toLong())
    }
    private suspend fun store(history: List<ChatEntry>): Conversation {
        val scope=Conversation(id="chat",title="测试对话")
        db.dao().putConversation(scope); history.forEach { db.dao().putEntry(it) }; return scope
    }
    @Test fun shortHistoryIncludesOlderMessagesWithoutExtraRequests()=runBlocking {
        val history=entries(10,10); val scope=store(history); val client=FakeClient()
        val reference=ConversationCompressor(db.dao(),client).prepareBudget(scope,history,8000,model)
        assertTrue(client.requests.isEmpty())
        history.forEach { assertTrue(reference.contains(it.text)) }
    }
    @Test fun summaryPersistsReusesCheckpointAndNeverDeletesRawMessages()=runBlocking {
        val history=entries(); val scope=store(history); val client=FakeClient(); val compressor=ConversationCompressor(db.dao(),client)
        val reference=compressor.prepareBudget(scope,history,2300,model)
        val saved=db.dao().conversation("chat")!!
        assertTrue(saved.contextSummary.contains("500")); assertTrue(saved.summarizedEntries>0)
        assertEquals(history,db.dao().history("chat")); assertTrue(reference.length<=900)
        assertTrue(reference.contains(history.last().text))
        val calls=client.requests.size
        assertEquals(reference,ConversationCompressor(db.dao(),client).prepareBudget(saved,history,2300,model))
        assertEquals(calls,client.requests.size)
        val extended=history+(20..25).map { ChatEntry(id="entry-$it",conversationId="chat",role=if(it%2==0) "user" else "assistant",text="新增事实-$it "+"新增".repeat(60),createdAt=it.toLong()) }
        compressor.prepareBudget(saved,extended,2300,model)
        assertTrue(client.requests.size>calls)
        assertFalse(client.requests.last().contains("唯一事实-0"))
        assertTrue(client.requests.last().contains("previous_summary"))
    }
    @Test fun cancellationAndProviderFailureDoNotOverwriteMemory()=runBlocking {
        val history=entries(); val scope=store(history)
        for(failure in listOf(IOException("offline"),CancellationException("stopped"))) {
            val client=FakeClient().apply { this.failure=failure }
            val error=runCatching { ConversationCompressor(db.dao(),client).prepareBudget(scope,history,2300,model) }.exceptionOrNull()
            assertNotNull(error); assertEquals(scope,db.dao().conversation("chat")); assertEquals(history,db.dao().history("chat"))
        }
    }
    @Test fun oversizedSummaryIsRejectedWithoutTruncatingSavedHistory()=runBlocking {
        val history=entries(); val scope=store(history)
        assertNotNull(runCatching { ConversationCompressor(db.dao(),FakeClient("过长".repeat(1500))).prepareBudget(scope,history,2300,model) }.exceptionOrNull())
        assertEquals(scope,db.dao().conversation("chat")); assertEquals(history,db.dao().history("chat"))
    }
    @Test fun reducingContextRecompressesOldSummaryInBoundedBatches()=runBlocking {
        val history=entries(20,40); var scope=store(history)
        scope=scope.copy(contextSummary="历史摘要".repeat(900),summaryThroughId="entry-15",summarizedEntries=16)
        db.dao().putConversation(scope)
        val client=FakeClient("用户预算 500 元，周五交付。")
        val smallModel=model.copy(contextTokens=8192)
        val reference=ConversationCompressor(db.dao(),client).prepareBudget(scope,history,1500,smallModel)
        assertTrue(client.requests.size>1); assertTrue(reference.length<=600)
        client.requests.forEach { assertTrue(it.length*2+smallModel.outputTokens<=smallModel.contextTokens) }
        assertEquals(history,db.dao().history("chat"))
    }
    @Test fun changedSelectionKeepsMemoryButOtherConversationsAndAccountsStayIsolated()=runBlocking {
        val history=entries(); val scope=store(history); val client=FakeClient()
        assertNotNull(runCatching { ConversationCompressor(db.dao(),client).prepareBudget(scope,history+history.first().copy(conversationId="other"),2300,model) }.exceptionOrNull())
        assertTrue(client.requests.isEmpty())
        client.during={ db.dao().putConversation(scope.copy(selectionJson="[{\"messageId\":\"new\"}]")) }
        ConversationCompressor(db.dao(),client).prepareBudget(scope,history,2300,model)
        assertTrue(db.dao().conversation("chat")!!.contextSummary.isNotBlank())
        assertTrue(db.dao().conversation("chat")!!.selectionJson.contains("new"))
        client.during={ db.dao().putConversation(scope.copy(accountId="another-account")) }
        assertNotNull(runCatching { ConversationCompressor(db.dao(),client).prepareBudget(scope,history,2300,model) }.exceptionOrNull())
    }
    @Test fun databaseVersionTwoMigratesAndSummarySurvivesReopen()=runBlocking {
        val context: Application=RuntimeEnvironment.getApplication(); val name="context-${System.nanoTime()}.db"
        val path=context.getDatabasePath(name); path.parentFile!!.mkdirs()
        val schema=JSONObject(File(System.getProperty("mailpilot.schemas"),"app.mailpilot.data.MailDatabase/2.json").readText()).getJSONObject("database")
        SQLiteDatabase.openOrCreateDatabase(path,null).use { sqlite ->
            val entities=schema.getJSONArray("entities")
            for(i in 0 until entities.length()) {
                val entity=entities.getJSONObject(i)
                sqlite.execSQL(entity.getString("createSql").replace("\${TABLE_NAME}",entity.getString("tableName")))
                val indices=entity.optJSONArray("indices") ?: JSONArray()
                for(j in 0 until indices.length()) sqlite.execSQL(indices.getJSONObject(j).getString("createSql").replace("\${TABLE_NAME}",entity.getString("tableName")))
            }
            val setup=schema.getJSONArray("setupQueries"); for(i in 0 until setup.length()) sqlite.execSQL(setup.getString(i))
            sqlite.execSQL("INSERT INTO conversations VALUES ('chat','旧聊天','[]',0,'','INBOX')")
            sqlite.execSQL("INSERT INTO chat_entries VALUES ('entry','chat','user','完整历史','[]',0)")
            sqlite.version=2
        }
        fun open()=Room.databaseBuilder(context,MailDatabase::class.java,name).allowMainThreadQueries().build()
        try {
            val migrated=open()
            try {
                val old=migrated.dao().conversation("chat")!!
                assertEquals("",old.contextSummary); assertEquals("完整历史",migrated.dao().history("chat").single().text)
                assertEquals(1,migrated.dao().updateContext("chat","","已整理事实","entry",1))
            } finally { migrated.close() }
            val reopened=open()
            try { assertEquals("已整理事实",reopened.dao().conversation("chat")!!.contextSummary); assertEquals(1,reopened.dao().history("chat").size) } finally { reopened.close() }
        } finally { context.deleteDatabase(name) }
    }
}

