package app.mailpilot.data

import android.content.Context
import androidx.datastore.preferences.core.*
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.map

private val Context.settingsStore by preferencesDataStore("settings")
data class UserSettings(val accountId: String = "", val textModelId: String = "", val visionModelId: String = "", val theme: String = "system", val syncMinutes: Int = 0,val search: ServiceConfig=ServiceConfig(),val speech: ServiceConfig=ServiceConfig.parse("",true),val contextModes: Map<String,String> = emptyMap(),val outputModes: Map<String,String> = emptyMap(),val fastCompression: Boolean=true,val appLanguage: String="zh")
class Preferences(private val context: Context) {
    suspend fun upgradeCompressionDefault() { context.settingsStore.edit { p ->
        val version=intPreferencesKey("compressionDefaultVersion")
        if((p[version] ?: 0)<33) { p[stringPreferencesKey("fastCompression")]="true"; p[version]=33 }
    } }
    val flow = context.settingsStore.data.map { p -> UserSettings(p[stringPreferencesKey("account")] ?: "",p[stringPreferencesKey("textModel")] ?: "",p[stringPreferencesKey("visionModel")] ?: "",p[stringPreferencesKey("theme")] ?: "system",p[intPreferencesKey("sync")] ?: 0,ServiceConfig.parse(p[stringPreferencesKey("searchConfig")] ?: ""),ServiceConfig.parse(p[stringPreferencesKey("speechConfig")] ?: "",true),modes(p[stringPreferencesKey("modelContextModes")]),modes(p[stringPreferencesKey("modelOutputModes")]),p[stringPreferencesKey("fastCompression")]=="true",AppLanguage.normalize(p[stringPreferencesKey("appLanguage")])) }
    suspend fun appLanguage(code: String) {
        require(code in AppLanguage.supported) { "Unsupported app language" }
        set("appLanguage",code)
    }
    private fun modes(raw: String?): Map<String,String> = runCatching { val j=org.json.JSONObject(raw ?: "{}"); j.keys().asSequence().associateWith { j.getString(it) } }.getOrDefault(emptyMap())
    suspend fun ensureContextModes(models: List<ModelProfile>) { context.settingsStore.edit { p ->
        val key=stringPreferencesKey("modelContextModes"); val old=modes(p[key]); val next=old.toMutableMap()
        models.forEach { if(it.id !in next) next[it.id]=app.mailpilot.ai.ModelContextPolicy.mode(it) }
        if(next!=old) p[key]=org.json.JSONObject(next).toString()
    } }
    suspend fun contextMode(id: String,mode: String?) = modelMode("modelContextModes",id,mode)
    suspend fun outputMode(id: String,mode: String?) = modelMode("modelOutputModes",id,mode)
    private suspend fun modelMode(name: String,id: String,mode: String?) { context.settingsStore.edit { p ->
        require(mode==null || mode in setOf("auto","custom"))
        val key=stringPreferencesKey(name); val next=modes(p[key]).toMutableMap()
        if(mode==null) next.remove(id) else next[id]=mode
        p[key]=org.json.JSONObject(next).toString()
    } }
    suspend fun set(key: String,value: String) { context.settingsStore.edit { it[stringPreferencesKey(key)] = value } }
    suspend fun sync(minutes: Int) { require(minutes == 0 || minutes >= 15); context.settingsStore.edit { it[intPreferencesKey("sync")] = minutes } }
}
