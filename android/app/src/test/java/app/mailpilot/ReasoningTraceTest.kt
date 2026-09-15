package app.mailpilot

import android.app.Application
import android.database.sqlite.SQLiteDatabase
import androidx.room.Room
import app.mailpilot.ai.*
import app.mailpilot.data.*
import app.mailpilot.platform.MailState
import kotlinx.coroutines.runBlocking
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import java.io.File

@RunWith(RobolectricTestRunner::class)
@Config(sdk=[28],application=Application::class)
class ReasoningTraceTest {
    @Test fun elapsedTimeCountsOnlyReasoningPhasesAndPreservesText() {
        var now=100L; val trace=ReasoningTrace { now }
        trace.append("第一段"); now=1100; assertEquals(1000,trace.snapshot().elapsedMs)
        trace.finish(); now=5000; assertEquals(1000,trace.snapshot().elapsedMs)
        trace.append("第二段"); now=5300; trace.finish()
        assertEquals("第一段\n\n第二段",trace.snapshot().text)
        assertEquals(1300,trace.snapshot().elapsedMs); assertEquals("completed",trace.snapshot().state)
    }
    @Test fun interruptedTraceKeepsPartialTextAndLimitIsExplicit() {
        val trace=ReasoningTrace { 0L }; trace.append("事实"); trace.finish("interrupted")
        assertEquals("事实",trace.snapshot().text); assertEquals("interrupted",trace.snapshot().state)
        val large=ReasoningTrace { 0L }; large.append("x".repeat(ReasoningTrace.MAX_CHARS-1)+"😀更多")
        large.append("后续"); large.finish()
        assertTrue(large.snapshot().truncated); assertTrue(large.snapshot().text.length<=ReasoningTrace.MAX_CHARS)
        assertFalse(large.snapshot().text.last().isHighSurrogate())
    }
    @Test fun bridgeSeparatesThoughtsFromAnswerAndLiveThoughtsAreResettable() {
        val thought=ReasoningSnapshot("模型返回的思考",1234,"completed")
        val entry=thought.attach(ChatEntry(conversationId="c",role="assistant",text="正文"))
        val json=JSONObject(BridgeCodec.state(MailState(entries=listOf(entry),reasoning=thought)))
        assertEquals(BuildConfig.VERSION_NAME,json.getString("appVersion"))
        assertEquals(BuildConfig.VERSION_CODE,json.getInt("buildNumber"))
        val row=json.getJSONArray("entries").getJSONObject(0)
        assertEquals("正文",row.getString("text")); assertEquals("模型返回的思考",row.getJSONObject("reasoning").getString("text"))
        assertFalse(json.toString().contains("encrypted_content"))
        assertEquals("",JSONObject(BridgeCodec.state(MailState())).getJSONObject("reasoning").getString("text"))
    }
    @Test fun versionThreeMigratesHistoryAndSavesReasoningAcrossReopen()=runBlocking {
        val context: Application=RuntimeEnvironment.getApplication(); val name="reasoning-${System.nanoTime()}.db"
        val path=context.getDatabasePath(name); path.parentFile!!.mkdirs()
        val schema=JSONObject(File(System.getProperty("mailpilot.schemas"),"app.mailpilot.data.MailDatabase/3.json").readText()).getJSONObject("database")
        SQLiteDatabase.openOrCreateDatabase(path,null).use { sqlite ->
            val entities=schema.getJSONArray("entities")
            for(i in 0 until entities.length()) {
                val entity=entities.getJSONObject(i); val table=entity.getString("tableName")
                sqlite.execSQL(entity.getString("createSql").replace("\${TABLE_NAME}",table))
                val indices=entity.optJSONArray("indices") ?: org.json.JSONArray()
                for(j in 0 until indices.length()) sqlite.execSQL(indices.getJSONObject(j).getString("createSql").replace("\${TABLE_NAME}",table))
            }
            val setup=schema.getJSONArray("setupQueries"); for(i in 0 until setup.length()) sqlite.execSQL(setup.getString(i))
            sqlite.execSQL("INSERT INTO conversations VALUES ('c','旧聊天','[]',0,'','INBOX','已有摘要','e',1)")
            sqlite.execSQL("INSERT INTO chat_entries VALUES ('e','c','assistant','完整回答','[]',0)")
            sqlite.version=3
        }
        fun open()=Room.databaseBuilder(context,MailDatabase::class.java,name).allowMainThreadQueries().build()
        try {
            val db=open()
            try {
                val old=db.dao().history("c").single()
                assertEquals("",old.reasoningText); assertEquals("完整回答",old.text)
                assertEquals("已有摘要",db.dao().conversation("c")!!.contextSummary)
                db.dao().putEntry(ReasoningSnapshot("可查看的思考",1500,"completed").attach(old).copy(draftId="draft-link"))
            } finally { db.close() }
            val reopened=open()
            try { val entry=reopened.dao().history("c").single(); assertEquals("可查看的思考",entry.reasoningText); assertEquals(1500,entry.reasoningMillis); assertEquals("完整回答",entry.text); assertEquals("draft-link",entry.draftId) } finally { reopened.close() }
        } finally { context.deleteDatabase(name) }
    }
}
