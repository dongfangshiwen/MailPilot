package app.mailpilot.services

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.media.*
import android.os.Bundle
import android.speech.*
import androidx.core.content.ContextCompat
import app.mailpilot.data.*
import kotlinx.coroutines.*
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.RandomAccessFile
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.Base64
import java.util.Locale

interface SpeechInputService {
    fun start(config: ServiceConfig,forceCloud: Boolean=false)
    fun stop()
    fun cancel()
}

class QwenAsrClient(private val secrets: SecretStore,private val http: JsonHttp=JsonHttp()) {
    suspend fun transcribe(config: ServiceConfig,audio: File,allowEmpty: Boolean=false): String {
        require(config.keyCipher.isNotBlank()) { "请先配置千问语音识别服务" }
        require(audio.length() in 45..2_000_000) { "录音为空或超过 60 秒限制" }
        val options=JSONObject().put("enable_itn",false)
        if(config.language in listOf("zh","en")) options.put("language",config.language)
        val body=JSONObject().put("model",config.model).put("stream",false).put("asr_options",options)
            .put("messages",JSONArray().put(JSONObject().put("role","user").put("content",JSONArray().put(JSONObject().put("type","input_audio")
                .put("input_audio",JSONObject().put("data","data:audio/wav;base64,"+Base64.getEncoder().encodeToString(audio.readBytes())))))))
        val base=config.baseUrl.trimEnd('/')
        val j=http.post(if(base.endsWith("/chat/completions")) base else "$base/chat/completions",secrets.decrypt(config.keyCipher),body)
        val text=j.getJSONArray("choices").getJSONObject(0).getJSONObject("message").optString("content").takeUnless { it=="null" }.orEmpty()
        require(allowEmpty || text.isNotBlank()) { "未识别到语音，请重新录音" }; return text
    }
}

/** All lifecycle methods run on the activity main thread. No transcript invokes an agent action. */
class AndroidSpeechInput(private val activity: Activity,private val scope: CoroutineScope,private val cloud: QwenAsrClient,private val emit: (Map<String,Any>)->Unit): SpeechInputService {
    private var recognizer: SpeechRecognizer?=null
    private var recorder: AudioRecord?=null
    private var job: Job?=null
    private var timer: Job?=null
    private var generation=0
    @Volatile private var recording=false
    private var active=false
    private var file: File?=null
    private fun event(state: String,text: String="",cloudAvailable: Boolean=false) = emit(mapOf("state" to state,"text" to text,"cloudAvailable" to cloudAvailable))
    @android.annotation.SuppressLint("MissingPermission")
    override fun start(config: ServiceConfig,forceCloud: Boolean) {
        require(!active) { "请先完成当前语音输入" }
        require(ContextCompat.checkSelfPermission(activity,Manifest.permission.RECORD_AUDIO)==PackageManager.PERMISSION_GRANTED) { "需要麦克风权限才能语音输入" }
        val useCloud=forceCloud || config.mode=="cloud" || !SpeechRecognizer.isRecognitionAvailable(activity)
        if(useCloud) require(config.keyCipher.isNotBlank()) { "手机没有可用的系统语音服务，请在设置中配置千问 ASR 后重试" }
        active=true; val token=++generation
        if(useCloud) startCloud(config,token) else {
            try {
                recognizer=SpeechRecognizer.createSpeechRecognizer(activity).also { r ->
                    r.setRecognitionListener(object: RecognitionListener {
                        override fun onReadyForSpeech(params: Bundle?) {}
                        override fun onBeginningOfSpeech() {}
                        override fun onRmsChanged(rmsdB: Float) {}
                        override fun onBufferReceived(buffer: ByteArray?) {}
                        override fun onEndOfSpeech() { if(token==generation) { event("processing"); timer?.cancel(); timer=scope.launch { delay(15000); if(token==generation) fail("语音识别超时，请重新录音",config) } } }
                        override fun onPartialResults(partialResults: Bundle?) {}
                        override fun onEvent(eventType: Int,params: Bundle?) {}
                        override fun onError(error: Int) {
                            if(token==generation) fail(when(error) {
                                SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "麦克风权限被拒绝"
                                SpeechRecognizer.ERROR_NO_MATCH,SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "未识别到语音，请重新录音"
                                SpeechRecognizer.ERROR_NETWORK,SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "系统语音服务网络不可用"
                                SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "系统语音服务忙，请稍后重试"
                                else -> "系统识别失败（$error），请重试或切换云端重新录音"
                            },config)
                        }
                        override fun onResults(results: Bundle?) {
                            if(token!=generation) return
                            val text=results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull().orEmpty()
                            if(text.isBlank()) fail("未识别到语音，请重新录音",config) else { cleanup(); event("result",text) }
                        }
                    })
                    val intent=Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL,RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                        .putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS,false).putExtra(RecognizerIntent.EXTRA_MAX_RESULTS,1)
                        .putExtra(RecognizerIntent.EXTRA_LANGUAGE,when(config.language) { "zh" -> "zh-CN"; "en" -> "en-US"; else -> Locale.getDefault().toLanguageTag() })
                    r.startListening(intent)
                }
                event("listening_system")
                timer=scope.launch { delay(60000); if(token==generation) stop() }
            } catch(e: Exception) { fail("无法启动系统识别，请重试或切换云端重新录音",config) }
        }
    }
    @android.annotation.SuppressLint("MissingPermission") // start() checks runtime permission; failures are reported and cleaned up.
    private fun startCloud(config: ServiceConfig,token: Int) {
        recording=true; event("listening_cloud")
        job=scope.launch {
            var target: File?=null
            try {
                target=withContext(Dispatchers.IO) {
                    val dir=File(activity.cacheDir,"speech").apply { mkdirs() }
                    val wav=File.createTempFile("voice-",".wav",dir); target=wav; file=wav
                    val min=AudioRecord.getMinBufferSize(16000,AudioFormat.CHANNEL_IN_MONO,AudioFormat.ENCODING_PCM_16BIT)
                    require(min>0) { "麦克风不支持 16 kHz 录音" }
                    val r=AudioRecord(MediaRecorder.AudioSource.MIC,16000,AudioFormat.CHANNEL_IN_MONO,AudioFormat.ENCODING_PCM_16BIT,maxOf(min,4096)); recorder=r
                    try {
                        require(r.state==AudioRecord.STATE_INITIALIZED) { "麦克风初始化失败" }; r.startRecording()
                        RandomAccessFile(wav,"rw").use { out ->
                            out.write(ByteArray(44)); val buffer=ByteArray(4096); var bytes=0
                            while(recording && bytes<16000*2*60) {
                                currentCoroutineContext().ensureActive()
                                val n=r.read(buffer,0,minOf(buffer.size,16000*2*60-bytes))
                                if(!recording) break
                                require(n>0) { "麦克风录音中断" }; out.write(buffer,0,n); bytes+=n
                            }
                            out.seek(0); out.write(wavHeader(bytes))
                        }
                    } finally { runCatching { r.stop() }; r.release(); if(recorder===r) recorder=null }
                    wav
                }
                currentCoroutineContext().ensureActive()
                if(token!=generation) return@launch
                recording=false; event("processing")
                val result=withContext(Dispatchers.IO) { cloud.transcribe(config,target!!) }
                if(token==generation) { active=false; event("result",result) }
            } catch(e: CancellationException) { throw e }
            catch(e: Exception) { if(token==generation) { active=false; recording=false; event("error",e.message ?: "语音识别失败，请重新录音") } }
            finally { target?.delete(); if(file==target) file=null; if(token==generation) active=false }
        }
    }
    override fun stop() {
        if(!active) return
        if(recognizer!=null) { recognizer?.stopListening(); event("processing"); timer?.cancel(); val token=generation; timer=scope.launch { delay(15000); if(token==generation) { cleanup(); event("error","语音识别超时，请重新录音") } } }
        else { recording=false; runCatching { recorder?.stop() } }
    }
    private fun fail(message: String,config: ServiceConfig) { cleanup(); event("error",message,config.keyCipher.isNotBlank()) }
    private fun cleanup() { generation++; active=false; recording=false; timer?.cancel(); recognizer?.let { it.cancel(); it.destroy() }; recognizer=null }
    override fun cancel() { cleanup(); runCatching { recorder?.stop() }; job?.cancel(); file?.delete(); event("idle") }
    companion object {
        fun wavHeader(size: Int): ByteArray=ByteBuffer.allocate(44).order(ByteOrder.LITTLE_ENDIAN).apply {
            put("RIFF".toByteArray()); putInt(size+36); put("WAVEfmt ".toByteArray()); putInt(16); putShort(1); putShort(1); putInt(16000); putInt(32000); putShort(2); putShort(16); put("data".toByteArray()); putInt(size)
        }.array()
    }
}
