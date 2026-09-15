package app.mailpilot.ai

import app.mailpilot.data.*
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.*
import org.json.*

/** Metadata only; retries never share timing counters. */
object RunTelemetry {
    suspend fun begin(dao: MailDao,id: String,attempt: String) = AgentCheckpoints.update(dao,id) { cp ->
        cp.put("activeAttemptId",attempt)
        val list=cp.optJSONArray("runAttempts") ?: JSONArray()
        list.put(JSONObject().put("id",attempt).put("startedAt",System.currentTimeMillis()).put("requests",JSONArray()))
        while(list.length()>3) list.remove(0)
        cp.put("runAttempts",list)
    }
    suspend fun request(dao: MailDao,id: String,attempt: String,sample: JSONObject) = AgentCheckpoints.update(dao,id) { cp ->
        val list=cp.optJSONArray("runAttempts") ?: return@update
        for(i in 0 until list.length()) {
            val run=list.getJSONObject(i); if(run.optString("id")!=attempt) continue
            val requests=run.getJSONArray("requests"); requests.put(sample)
            while(requests.length()>128) requests.remove(0)
        }
    }
    suspend fun end(dao: MailDao,id: String,status: String) = AgentCheckpoints.update(dao,id) { cp ->
        val list=cp.optJSONArray("runAttempts") ?: return@update
        if(list.length()>0) list.getJSONObject(list.length()-1).put("status",status).put("finishedAt",System.currentTimeMillis())
    }
}

class RecordingModelClient(private val dao: MailDao,private val delegate: ModelClient): ModelClient {
    override suspend fun test(profile: ModelProfile)=delegate.test(profile)
    override fun generate(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?)=delegate.generate(profile,messages,tools,forceStream)
    override fun generateRequest(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?,options: ModelRequestOptions)=flow {
        val attempt=AgentRunCheckpoint.from(dao.turn(options.requestId)).data.optString("activeAttemptId")
        val start=System.nanoTime(); fun elapsed()=(System.nanoTime()-start)/1_000_000
        val sample=JSONObject().put("id",options.invocationId).put("stage",options.stage).put("model",profile.model)
            .put("host",runCatching { java.net.URI(profile.baseUrl).host }.getOrNull()).put("thinking",profile.thinkingMode)
            .put("images",VisionRequestPlanner.imageCount(messages)).put("inputEstimate",ContextBudgetPlanner.estimate(messages,tools,profile))
        try {
            delegate.generateRequest(profile,messages,tools,forceStream,options).collect { e ->
                when(e) {
                    is ModelEvent.Thinking -> if(!sample.has("firstThinkingMs")) sample.put("firstThinkingMs",elapsed())
                    is ModelEvent.Delta -> if(!sample.has("firstTextMs")) sample.put("firstTextMs",elapsed())
                    is ModelEvent.Diagnostics -> for(k in listOf("attemptId","providerRequestId","finishReason","firstByteMs","lastByteMs","httpStatus","bodyBytes","requestedOutputTokens")) if(e.value.has(k)) sample.put(k,e.value.get(k))
                    is ModelEvent.Completed -> sample.put("status","complete")
                }
                emit(e)
            }
        } catch(e: Exception) { sample.put("status",if(e is CancellationException) "stopped" else "failed").put("exceptionType",e.javaClass.simpleName); throw e }
        finally { kotlinx.coroutines.withContext(kotlinx.coroutines.NonCancellable) {
            val duration=elapsed()
            if(sample.has("firstThinkingMs")) sample.put("thinkingIntervalMs",(sample.optLong("firstTextMs",duration)-sample.getLong("firstThinkingMs")).coerceAtLeast(0))
            RunTelemetry.request(dao,options.requestId,attempt,sample.put("elapsedMs",duration))
        } }
    }
}
