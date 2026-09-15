package app.mailpilot

import android.app.Application
import android.database.sqlite.SQLiteDatabase
import androidx.room.Room
import app.mailpilot.data.*
import kotlinx.coroutines.runBlocking
import org.json.JSONObject
import org.junit.Test
import org.junit.Assert.*
import org.junit.runner.RunWith
import org.robolectric.*
import org.robolectric.annotation.Config
import java.io.File

@RunWith(RobolectricTestRunner::class)
@Config(sdk=[28],application=Application::class)
class Migration160Test {
    @Test fun versionFiveKeepsEncryptedAccountsMailDraftsAndChats()=runBlocking {
        val context: Application=RuntimeEnvironment.getApplication(); val name="migration160-${System.nanoTime()}.db"
        val path=context.getDatabasePath(name); path.parentFile!!.mkdirs()
        val schema=JSONObject(File(System.getProperty("mailpilot.schemas"),"app.mailpilot.data.MailDatabase/5.json").readText()).getJSONObject("database")
        SQLiteDatabase.openOrCreateDatabase(path,null).use { sqlite ->
            val entities=schema.getJSONArray("entities")
            for(i in 0 until entities.length()) {
                val entity=entities.getJSONObject(i); val table=entity.getString("tableName")
                sqlite.execSQL(entity.getString("createSql").replace("\${TABLE_NAME}",table))
                val indices=entity.optJSONArray("indices") ?: org.json.JSONArray()
                for(j in 0 until indices.length()) sqlite.execSQL(indices.getJSONObject(j).getString("createSql").replace("\${TABLE_NAME}",table))
            }
            fun insert(table: String,values: Map<String,Any>) {
                val entity=(0 until entities.length()).map { entities.getJSONObject(it) }.first { it.getString("tableName")==table }
                val fields=entity.getJSONArray("fields"); val columns=(0 until fields.length()).map { fields.getJSONObject(it) }
                val args=columns.map { values[it.getString("columnName")] ?: if(it.getString("affinity")=="TEXT") "" else 0 }.toTypedArray()
                sqlite.execSQL("INSERT INTO $table (${columns.joinToString(",") { "["+it.getString("columnName")+"]" }}) VALUES (${columns.joinToString(",") { "?" }})",args)
            }
            insert("accounts",mapOf("id" to "a","email" to "old@example.test","passwordCipher" to "encrypted-fixture"))
            insert("messages",mapOf("id" to "m","accountId" to "a","folder" to "INBOX","uidValidity" to 1,"uid" to 1,"body" to "旧正文"))
            insert("drafts",mapOf("id" to "d","accountId" to "a","body" to "旧草稿","filesJson" to "[]","status" to "DRAFT","revision" to 3))
            insert("conversations",mapOf("id" to "c","accountId" to "a","selectionJson" to "[]","contextSummary" to "保留摘要"))
            insert("chat_entries",mapOf("id" to "e","conversationId" to "c","role" to "assistant","text" to "旧回答","sourcesJson" to "[]"))
            val queries=schema.getJSONArray("setupQueries"); for(i in 0 until queries.length()) sqlite.execSQL(queries.getString(i))
            sqlite.version=5
        }
        try {
            val db=Room.databaseBuilder(context,MailDatabase::class.java,name).allowMainThreadQueries().build()
            try {
                assertEquals("encrypted-fixture",db.dao().account("a")!!.passwordCipher)
                assertEquals("旧正文",db.dao().message("m")!!.body); assertEquals("READY",db.dao().message("m")!!.bodyState)
                assertEquals(3L,db.dao().draft("d")!!.revision); assertEquals("旧草稿",db.dao().draft("d")!!.body)
                assertEquals("旧回答",db.dao().history("c").single().text); assertEquals("保留摘要",db.dao().conversation("c")!!.contextSummary)
                db.dao().putTurn(TurnSnapshot("t","c","a","INBOX","[]",1)); assertNotNull(db.dao().turn("t"))
                db.dao().putSyncCursor(SyncCursor("a","INBOX",1,12)); assertEquals(12L,db.dao().syncCursor("a","INBOX")!!.lastUid)
            } finally { db.close() }
        } finally { context.deleteDatabase(name) }
    }
}
