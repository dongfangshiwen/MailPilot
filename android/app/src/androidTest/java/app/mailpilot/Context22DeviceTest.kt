package app.mailpilot

import androidx.room.Room
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import app.mailpilot.ai.*
import app.mailpilot.data.*
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import org.json.*
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.io.IOException

@RunWith(AndroidJUnit4::class)
class Context22DeviceTest {
    @Test fun compressionCheckpointSurvivesDatabaseReopenWithoutOverwritingMemory(): Unit=runBlocking {
        val context=InstrumentationRegistry.getInstrumentation().targetContext
        val name="context22-${System.nanoTime()}.db"
        var db=Room.databaseBuilder(context,MailDatabase::class.java,name).build()
        val profile=ModelProfile(model="local-fixture",contextTokens=16384,outputTokens=1024,thinkingMode="disabled")
        val blocks=listOf("A".repeat(4500),"B".repeat(4500),"C".repeat(4500))
        val facts="姓名李明，周五交付，预算500元；修改：收件人稍后确认。[T1:S1]"
        class Client(val failSecond: Boolean): ModelClient {
            val requests=mutableListOf<String>()
            override suspend fun test(profile: ModelProfile)=profile
            override fun generate(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?)=flow {
                ContextBudgetPlanner.requireFits(profile,messages,tools); assertNull(tools)
                requests+=messages.toString()
                if(failSecond && requests.size==2) throw IOException("local fixture interruption")
                emit(ModelEvent.Completed(roleMessage("assistant",facts)))
            }
        }
        try {
            db.dao().putConversation(Conversation(id="c",contextSummary="旧记忆",summaryThroughId="old",summarizedEntries=1))
            db.dao().putEntry(ChatEntry(id="old",conversationId="c",role="user",text="旧原文"))
            db.dao().putTurn(TurnSnapshot("run","c","","INBOX","[]",2))
            assertNotNull(runCatching { ContextReducer(db.dao(),Client(true)).reduce(blocks,"",600,profile,"run") }.exceptionOrNull())
            assertEquals(1,AgentRunCheckpoint.from(db.dao().turn("run")).data.getJSONObject("compression").getJSONObject("history").getInt("batch"))
            db.close(); db=Room.databaseBuilder(context,MailDatabase::class.java,name).build()
            assertEquals("旧记忆",db.dao().conversation("c")!!.contextSummary)
            val client=Client(false)
            assertEquals(facts,ContextReducer(db.dao(),client).reduce(blocks,"",600,profile,"run"))
            assertFalse(client.requests.first().contains("A".repeat(100)))
            assertEquals(1,db.dao().commitContext("c","","旧记忆","old",facts,"old",1))
            assertEquals("旧原文",db.dao().history("c").single().text)
            assertTrue(db.dao().allDrafts().isEmpty())
            val preferences=Preferences(context)
            val official=profile.copy(id="context22-device",baseUrl="https://ark.cn-beijing.volces.com/api/v3",model="doubao-seed-evolving",contextTokens=32768)
            preferences.ensureContextModes(listOf(official))
            assertEquals(1048576,ModelContextPolicy.resolve(official,Preferences(context).flow.first().contextModes[official.id]).contextTokens)
            preferences.contextMode(official.id,"custom")
            assertEquals(32768,ModelContextPolicy.resolve(official,Preferences(context).flow.first().contextModes[official.id]).contextTokens)
            preferences.contextMode(official.id,null)
        } finally { db.close(); context.deleteDatabase(name) }
    }
}
