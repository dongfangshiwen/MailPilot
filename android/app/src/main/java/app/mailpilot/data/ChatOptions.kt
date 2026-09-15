package app.mailpilot.data

import androidx.room.*
import org.json.JSONArray
import org.json.JSONObject

data class ChatRequestOptions(val thinking: String="default",val webSearch: Boolean=false,val reasoningEffort: String?=null,val thinkingBudget: Int?=null,val imageMode: String="complete",val fastCompression: Boolean=false) {
    init { require(thinking in listOf("default","enabled","disabled")); require(imageMode in setOf("complete","batch")) }
    fun json()=JSONObject().put("thinking",thinking).put("webSearch",webSearch).put("reasoningEffort",reasoningEffort).put("thinkingBudget",thinkingBudget).put("imageMode",imageMode).apply { if(fastCompression) put("fastCompression",true) }.toString()
    fun apply(model: ModelProfile)=model.copy(thinkingMode=if(thinking=="default") model.thinkingMode else thinking,reasoningEffort=reasoningEffort ?: model.reasoningEffort,thinkingBudget=thinkingBudget ?: model.thinkingBudget)
    fun freeze(model: ModelProfile)=copy(thinking=model.thinkingMode.takeIf { it!="auto" } ?: "default",reasoningEffort=model.reasoningEffort,thinkingBudget=model.thinkingBudget)
    companion object { fun parse(j: JSONObject)=ChatRequestOptions(j.optString("thinking","default"),j.optBoolean("webSearch"),if(j.has("reasoningEffort") && !j.isNull("reasoningEffort")) j.getString("reasoningEffort") else null,if(j.has("thinkingBudget") && !j.isNull("thinkingBudget")) j.getInt("thinkingBudget") else null,j.optString("imageMode","complete"),j.optBoolean("fastCompression")) }
}

data class ServiceConfig(val provider: String="volcengine",val baseUrl: String="https://open.feedcoopapi.com/search_api/web_search",val keyCipher: String="",val model: String="qwen3-asr-flash",val language: String="auto",val mode: String="system") {
    fun json()=JSONObject().put("provider",provider).put("baseUrl",baseUrl).put("keyCipher",keyCipher).put("model",model).put("language",language).put("mode",mode).toString()
    fun publicFields()=mapOf("provider" to provider,"baseUrl" to baseUrl,"hasSecret" to keyCipher.isNotBlank(),"model" to model,"language" to language,"mode" to mode)
    companion object {
        fun parse(raw: String,speech: Boolean=false): ServiceConfig {
            val j=runCatching { JSONObject(raw) }.getOrDefault(JSONObject())
            return ServiceConfig(j.optString("provider",if(speech) "qwen" else "volcengine"),j.optString("baseUrl",if(speech) "https://dashscope.aliyuncs.com/compatible-mode/v1" else "https://open.feedcoopapi.com/search_api/web_search"),j.optString("keyCipher"),j.optString("model","qwen3-asr-flash"),j.optString("language","auto"),j.optString("mode","system"))
        }
    }
}

@Entity(tableName="local_materials",indices=[Index("conversationId")],foreignKeys=[ForeignKey(entity=Conversation::class,parentColumns=["id"],childColumns=["conversationId"],onDelete=ForeignKey.CASCADE)])
data class LocalMaterial(@PrimaryKey val id: String=newId(),val conversationId: String,val name: String,val mime: String,val path: String,val size: Long,val selected: Boolean=true,val pagesJson: String="[]") {
    fun attachment()=Attachment(id,"",name,mime,size,"",path)
    fun pages(): List<Int> = JSONArray(pagesJson).let { a -> (0 until a.length()).map { a.getInt(it) } }
    fun fields()=mapOf("id" to id,"name" to name,"mime" to mime,"size" to size,"selected" to selected,"pages" to pages())
}
