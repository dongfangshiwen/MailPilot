package app.mailpilot.ai

import app.mailpilot.data.ModelProfile
import kotlinx.coroutines.flow.*
import org.json.JSONArray
import org.json.JSONObject

/** Snapshot protocol data while retaining streamed file references instead of Base64 copies. */
data class PreparedModelRequest(val messages: JSONArray,val tools: JSONArray?,val budget: JSONObject) {
    companion object {
        private fun copy(value: Any?): Any?=when(value) {
            is LocalImagePart -> LocalImagePart(value.source)
            is JSONObject -> JSONObject().apply { value.keys().forEach { put(it,copy(value.opt(it))) } }
            is JSONArray -> JSONArray().apply { for(i in 0 until value.length()) put(copy(value.opt(i))) }
            else -> value
        }
        fun prepare(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,options: ModelRequestOptions): PreparedModelRequest {
            val frozen=copy(messages) as JSONArray; val definitions=copy(tools) as? JSONArray
            try { ContextBudgetPlanner.requireFits(profile,frozen,definitions) }
            catch(e: ModelFailure) {
                throw ModelFailure(e.info.copy(diagnostics=e.info.diagnostics.put("stage",options.stage).put("requestId",options.requestId)),e)
            }
            return PreparedModelRequest(frozen,definitions,ContextBudgetPlanner.report(profile,frozen,definitions)
                .put("stage",options.stage).put("requestId",options.requestId))
        }
    }
}

/** Every workflow, including injected clients, uses the same final preflight. */
fun ModelClient.generateBudgeted(profile: ModelProfile,messages: JSONArray,tools: JSONArray?=null,
    forceStream: Boolean?=null,options: ModelRequestOptions=ModelRequestOptions()): Flow<ModelEvent> = flow {
    val request=PreparedModelRequest.prepare(profile,messages,tools,options)
    emit(ModelEvent.Diagnostics(request.budget))
    emitAll(generateRequest(profile,request.messages,request.tools,forceStream,options))
}
