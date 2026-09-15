package app.mailpilot

import android.app.Application
import android.database.sqlite.SQLiteDatabase
import androidx.room.Room
import app.mailpilot.ai.ReasoningOptions
import app.mailpilot.data.MailDatabase
import app.mailpilot.data.ModelProfile
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
class ReasoningOptionsTest {
    @Test fun existingProfilesSendNoNewParametersByDefault() {
        for(url in listOf("https://api.deepseek.com","https://ark.cn-beijing.volces.com/api/v3","https://dashscope.aliyuncs.com/compatible-mode/v1")) {
            assertEquals(0,ReasoningOptions.apply(ModelProfile(baseUrl=url),JSONObject()).length())
        }
        assertEquals("compatible",ReasoningOptions.provider(ModelProfile(baseUrl="https://api.deepseek.com.evil.invalid")))
    }
    @Test fun deepseekAndVolcanoHaveDistinctWireParametersAndEfforts() {
        val deepseek=ModelProfile(provider="deepseek",thinkingMode="enabled",reasoningEffort="max")
        val d=ReasoningOptions.apply(deepseek,JSONObject())
        assertEquals("enabled",d.getJSONObject("thinking").getString("type")); assertEquals("max",d.getString("reasoning_effort")); assertFalse(d.has("extra_body"))
        val volcano=deepseek.copy(provider="volcengine",thinkingMode="auto",reasoningEffort="minimal")
        val v=ReasoningOptions.apply(volcano,JSONObject())
        assertEquals("auto",v.getJSONObject("thinking").getString("type")); assertEquals("minimal",v.getString("reasoning_effort"))
        assertThrows(IllegalArgumentException::class.java) { ReasoningOptions.apply(volcano.copy(reasoningEffort="max"),JSONObject()) }
    }
    @Test fun aliyunBudgetAndEffortAreExclusiveAndDisabledModeOmitsBoth() {
        val p=ModelProfile(provider="aliyun",model="qwen3.8-plus",thinkingMode="enabled",thinkingBudget=1024,outputTokens=4096)
        val budget=ReasoningOptions.apply(p,JSONObject())
        assertTrue(budget.getBoolean("enable_thinking")); assertEquals(1024,budget.getInt("thinking_budget")); assertFalse(budget.has("reasoning_effort"))
        val effort=ReasoningOptions.apply(p.copy(thinkingBudget=0,reasoningEffort="xhigh"),JSONObject())
        assertEquals("xhigh",effort.getString("reasoning_effort")); assertFalse(effort.has("thinking_budget"))
        assertThrows(IllegalArgumentException::class.java) { ReasoningOptions.apply(p.copy(reasoningEffort="low"),JSONObject()) }
        assertThrows(IllegalArgumentException::class.java) { ReasoningOptions.apply(p.copy(thinkingBudget=4096),JSONObject()) }
        val off=ReasoningOptions.apply(p.copy(thinkingMode="disabled",reasoningEffort="low"),JSONObject())
        assertFalse(off.getBoolean("enable_thinking")); assertEquals(1,off.length())
    }
    @Test fun bridgePreservesSecretsAndCapabilityReportAfterThinkingChanges() {
        val old=ModelProfile(id="old",model="deepseek-v4-pro",baseUrl="https://api.deepseek.com",apiKeyCipher="encrypted-test-only",supportsStreaming=true,textVerified=true)
        val payload=JSONObject(BridgeCodec.model(old)).put("thinkingMode","enabled").put("reasoningEffort","max")
        val changed=BridgeCodec.model(payload,old)
        assertEquals(old.apiKeyCipher,changed.apiKeyCipher); assertTrue(changed.textVerified)
        assertEquals("max",BridgeCodec.model(changed)["reasoningEffort"])
        assertFalse(JSONObject(BridgeCodec.model(changed)).toString().contains("encrypted-test-only"))
    }
    @Test fun databaseVersionOneMigratesWithoutLosingModelsOrDrafts()=runBlocking {
        val context=RuntimeEnvironment.getApplication()
        val name="migration-${System.nanoTime()}.db"; val path=context.getDatabasePath(name)
        path.parentFile!!.mkdirs()
        val schema=JSONObject(File(System.getProperty("mailpilot.schemas"),"app.mailpilot.data.MailDatabase/1.json").readText()).getJSONObject("database")
        SQLiteDatabase.openOrCreateDatabase(path,null).use { sqlite ->
            val entities=schema.getJSONArray("entities")
            for(i in 0 until entities.length()) {
                val entity=entities.getJSONObject(i)
                sqlite.execSQL(entity.getString("createSql").replace("\${TABLE_NAME}",entity.getString("tableName")))
                val indices=entity.optJSONArray("indices") ?: org.json.JSONArray()
                for(j in 0 until indices.length()) sqlite.execSQL(indices.getJSONObject(j).getString("createSql").replace("\${TABLE_NAME}",entity.getString("tableName")))
            }
            val setup=schema.getJSONArray("setupQueries"); for(i in 0 until setup.length()) sqlite.execSQL(setup.getString(i))
            sqlite.execSQL("INSERT INTO models VALUES ('old','原有模型','https://api.deepseek.com','cipher','deepseek-chat',32768,2048,1,0,0,1,'max_tokens','测试通过')")
            sqlite.execSQL("INSERT INTO drafts VALUES ('draft','account','to@example.test','','','待发主题','保留正文','[]','','',7,'DRAFT','',0)")
            sqlite.version=1
        }
        val db=Room.databaseBuilder(context,MailDatabase::class.java,name).allowMainThreadQueries().build()
        try {
            val model=db.dao().model("old")!!
            assertEquals("cipher",model.apiKeyCipher); assertEquals("auto",model.provider); assertEquals("default",model.thinkingMode); assertEquals(0,model.thinkingBudget)
            assertEquals("保留正文",db.dao().draft("draft")!!.body)
            assertEquals(7L,db.dao().draft("draft")!!.revision)
            db.dao().putModel(model.copy(provider="deepseek",thinkingMode="enabled",reasoningEffort="max"))
            assertEquals("max",db.dao().model("old")!!.reasoningEffort)
        } finally { db.close(); context.deleteDatabase(name) }
    }
}
