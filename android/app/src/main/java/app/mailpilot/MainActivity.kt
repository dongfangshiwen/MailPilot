package app.mailpilot

import app.mailpilot.attachments.isImageAttachment
import app.mailpilot.attachments.openMimeType

import android.content.Intent
import androidx.core.content.FileProvider
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.ViewModelStore
import app.mailpilot.data.*
import app.mailpilot.platform.MailCoordinator
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.*
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.sample
import kotlinx.coroutines.flow.onStart
import org.json.JSONObject
import java.io.File

class MainActivity: FlutterActivity() {
    private val store=ViewModelStore()
    private val scope=CoroutineScope(SupervisorJob()+Dispatchers.Main.immediate)
    private lateinit var vm: MailCoordinator
    private var stateJob: Job?=null
    private val tested=mutableMapOf<String,ModelProfile>()
    private var pickerResult: MethodChannel.Result?=null
    private var exportFile: File?=null
    private var pickerConversation=""
    private var pickerDraft: Draft?=null
    private lateinit var speech: app.mailpilot.services.AndroidSpeechInput
    private var speechSink: EventChannel.EventSink?=null
    private var permissionResult: MethodChannel.Result?=null
    private var permissionCloud=false
    @OptIn(FlowPreview::class)
    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        vm=ViewModelProvider(store,ViewModelProvider.AndroidViewModelFactory(application))[MailCoordinator::class.java]
        speech=app.mailpilot.services.AndroidSpeechInput(this,scope,vm.graph.asr) { speechSink?.success(it) }
        EventChannel(engine.dartExecutor.binaryMessenger,"mailpilot/speech").setStreamHandler(object: EventChannel.StreamHandler {
            override fun onListen(arguments: Any?,events: EventChannel.EventSink) { speechSink=events }
            override fun onCancel(arguments: Any?) { speechSink=null; speech.cancel() }
        })
        EventChannel(engine.dartExecutor.binaryMessenger,"mailpilot/state").setStreamHandler(object: EventChannel.StreamHandler {
            override fun onListen(arguments: Any?,events: EventChannel.EventSink) {
                stateJob?.cancel()
                val encoder=StreamingStateEncoder()
                stateJob=scope.launch {
                    vm.state.sample(32).onStart { emit(vm.state.value) }.collect { state ->
                        val frame=withContext(Dispatchers.Default) { encoder.encode(state) }
                        if(frame!=null) events.success(frame)
                    }
                }
            }
            override fun onCancel(arguments: Any?) { stateJob?.cancel(); stateJob=null }
        })
        // Sample accumulated state before deriving deltas. Pauses retain their last
        // chunk; encoding long histories stays off the platform main thread.
        MethodChannel(engine.dartExecutor.binaryMessenger,"mailpilot/actions").setMethodCallHandler { call,result ->
            scope.launch {
                try {
                    vm.graph.ready.await()
                    val j=JSONObject((call.arguments as? Map<*,*>) ?: emptyMap<String,Any>())
                    val id=j.optString("id"); val dao=vm.graph.dao
                    val value: Any?=when(call.method) {
                        "snapshot" -> BridgeCodec.state(vm.state.value)
                        "tab" -> { vm.tab(j.optInt("index")); null }
                        "back" -> { vm.back(); null }
                        "clearFeedback" -> { vm.clearFeedback(); null }
                        "dismissNotice" -> { vm.dismissNotice(j.optString("notice")); null }
                        "plainMailBody" -> app.mailpilot.mail.MailBody.fromMarkdown(j.optString("body"))
                        "account" -> { vm.account(id); null }
                        "folder" -> { vm.folder(j.getString("value")); null }
                        "refresh" -> { vm.refresh(j.optBoolean("more")); null }
                        "cancelSync" -> { vm.cancelSync(); null }
                        "loadFolders" -> { vm.loadFolders(); null }
                        "search" -> { vm.search(j.optString("query"),j.optBoolean("unread"),remote=j.optBoolean("remote",true)); null }
                        "toggleMessage" -> { vm.toggleMessage(id); null }
                        "clearSelection" -> { vm.clearSelection(); null }
                        "openMessage" -> { vm.openMessage(requireNotNull(dao.message(id))); null }
                        "selectAttachment" -> { vm.selectAttachment(requireNotNull(dao.attachment(id))); null }
                        "selectionSummary" -> JSONObject(vm.refreshSelectionSummary()).toString()
                        "selectMessageFiles" -> { vm.selectMessageFiles(id,j.optBoolean("bodyOnly")); null }
                        "editPdf" -> { vm.editPdf(requireNotNull(dao.attachment(id))); null }
                        "pdfThumbnail" -> vm.pdfThumbnail(id,j.getInt("page"),j.getString("token"))
                        "choosePdf" -> { val a=j.getJSONArray("pages"); vm.choosePdf((0 until a.length()).map { a.getInt(it) },j.optString("token").takeIf { it.isNotBlank() }); null }
                        "dismissPdf" -> { vm.dismissPdf(); null }
                        "preview" -> { vm.preview(requireNotNull(dao.attachment(id))); null }
                        "showSource" -> { vm.showSource(if(j.has("source")) BridgeCodec.source(j.getJSONObject("source")) else null); null }
                        "prepareMessageEdit" -> vm.prepareMessageEdit(id)
                        "messageVersions" -> vm.messageVersions(id)
                        "editMessage" -> { vm.editMessage(id,j.getString("question"),ChatRequestOptions.parse(j.optJSONObject("options") ?: JSONObject())); null }
                        "analyze" -> { vm.analyze(j.getString("question"),options=ChatRequestOptions.parse(j.optJSONObject("options") ?: JSONObject())); null }
                        "retryAnalysis" -> { vm.retryAnalysis(id,j.optBoolean("defaults"),useCurrentMaterials=j.optBoolean("useCurrentMaterials"),compatibleFormat=j.optBoolean("compatibleFormat"),batchImages=j.optBoolean("batchImages")); null }
                        "continueResearch" -> { vm.retryAnalysis(id,continueResearch=true); null }
                        "retrySearch" -> { vm.retrySearch(j.optBoolean("webSearch",true)); null }
                        "toggleLocal" -> { vm.toggleLocal(id); null }
                        "localPdf" -> { vm.localPdf(id); null }
                        "fillRecipient" -> { vm.fillRecipient(id,j.getString("address")); null }
                        "latestDraft" -> { vm.latestDraft(id); null }
                        "listConversations" -> vm.conversationPage(j)
                        "renameConversation" -> { vm.renameConversation(id,j.getString("title")); null }
                        "pinConversations" -> { val ids=j.getJSONArray("ids"); vm.pinConversations((0 until ids.length()).map { ids.getString(it) },j.optBoolean("pin",true)); null }
                        "deleteConversations" -> { val ids=j.getJSONArray("ids"); vm.deleteConversations((0 until ids.length()).map { ids.getString(it) }); null }
                        "visualMaterials" -> vm.visualMaterials()
                        "recheckVisual" -> { vm.recheckVisual(j.getString("assetKey")); null }
                        "deleteConversation" -> { vm.deleteConversation(id); null }
                        "saveService", "testService" -> {
                            val isSpeech=j.optBoolean("speech")
                            val cfg=vm.serviceConfig(j,isSpeech,call.method=="saveService")
                            if(call.method=="saveService") "配置已保存"
                            else if(!isSpeech) { vm.graph.webSearch.search(cfg,"天气"); "搜索连接测试成功" }
                            else {
                                val file=File.createTempFile("asr-test-",".wav",cacheDir)
                                try { withContext(Dispatchers.IO) { file.writeBytes(app.mailpilot.services.AndroidSpeechInput.wavHeader(32000)+ByteArray(32000)) }; vm.graph.asr.transcribe(cfg,file,allowEmpty=true); "语音接口已响应；请录音验证识别效果" }
                                finally { file.delete() }
                            }
                        }
                        "speechStart" -> {
                            require(permissionResult==null) { "请先处理麦克风权限" }
                            if(androidx.core.content.ContextCompat.checkSelfPermission(this@MainActivity,android.Manifest.permission.RECORD_AUDIO)!=android.content.pm.PackageManager.PERMISSION_GRANTED) {
                                permissionResult=result; permissionCloud=j.optBoolean("cloud"); requestPermissions(arrayOf(android.Manifest.permission.RECORD_AUDIO),601); return@launch
                            }
                            speech.start(vm.state.value.settings.speech,j.optBoolean("cloud")); null
                        }
                        "speechStop" -> { speech.stop(); null }
                        "speechCancel" -> { speech.cancel(); null }
                        "pickMaterial" -> {
                            require(pickerResult==null) { "请先完成文件选择" }
                            pickerConversation=vm.state.value.conversationId; pickerResult=result
                            startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT).setType(if(j.optBoolean("image")) "image/*" else "*/*").addCategory(Intent.CATEGORY_OPENABLE),503); return@launch
                        }
                        "cancelAnalysis" -> { vm.cancelAnalysis(); null }
                        "newConversation" -> { vm.newConversation(); null }
                        "loadConversation" -> { vm.loadConversation(requireNotNull(dao.conversation(id))); null }
                        "newDraft" -> { vm.newDraft(j.optString("body")); null }
                        "draftFromAnswer" -> { vm.draftFromAnswer(j.getString("id"),ChatRequestOptions.parse(j.optJSONObject("options") ?: JSONObject())); null }
                        "editDraft" -> { vm.editDraft(requireNotNull(dao.draft(id))); null }
                        "reply" -> { vm.reply(requireNotNull(dao.message(id)),j.optBoolean("all"),j.optBoolean("forward")); null }
                        "updateEditor", "saveDraft", "reviewDraftInChat" -> {
                            val old=requireNotNull(vm.state.value.editor)
                            require(old.id==id && old.status in listOf("DRAFT","FAILED")) { "草稿不可编辑" }
                            val d=BridgeCodec.draft(j,old)
                            if(call.method=="reviewDraftInChat") vm.reviewDraftInChat(d) else if(call.method=="saveDraft") vm.saveDraft(d,j.optBoolean("preview")) else vm.updateEditor(d)
                            null
                        }
                        "sendConfirmed" -> { vm.sendConfirmed(); null }
                        "confirmChatSend" -> { vm.confirmChatSend(id); null }
                        "dismissSend" -> { vm.dismissSend(); null }
                        "deleteDraft" -> { vm.deleteDraft(requireNotNull(dao.draft(id))); null }
                        "redraft" -> { vm.redraft(requireNotNull(dao.draft(id)),ChatRequestOptions.parse(j.optJSONObject("options") ?: JSONObject())); null }
                        "resolveUnknown" -> { val d=requireNotNull(dao.draft(id)); require(d.status=="UNKNOWN"); vm.resolveUnknown(d,j.optBoolean("sent")); null }
                        "saveAccount", "testAccount" -> {
                            val a=BridgeCodec.account(j,dao.account(id))
                            if(call.method=="saveAccount") vm.saveAccount(a,j.optString("secret")) else vm.testAccount(a,j.optString("secret"))
                        }
                        "saveModel", "testModel" -> {
                            val old=tested[id] ?: dao.model(id); val m=BridgeCodec.model(j,old)
                            val mode=j.optString("contextMode",app.mailpilot.ai.ModelContextPolicy.mode(m,vm.state.value.settings.contextModes[m.id]))
                            val outputMode=j.optString("outputMode",app.mailpilot.ai.ModelOutputPolicy.mode(m,vm.state.value.settings.outputModes[m.id]))
                            if(call.method=="testModel") { val testedModel=vm.testModel(m,j.optString("secret"),mode,outputMode); tested[testedModel.id]=testedModel; JSONObject(BridgeCodec.model(testedModel)+mapOf("contextMode" to mode,"outputMode" to outputMode)).toString() }
                            else { vm.saveModel(m,j.optString("secret"),mode,outputMode); tested.remove(id); "模型已保存" }
                        }
                        "deleteAccount" -> { vm.deleteAccount(requireNotNull(dao.account(id))); null }
                        "deleteModel" -> { vm.deleteModel(requireNotNull(dao.model(id))); null }
                        "defaultModel" -> { vm.defaultModel(id,j.optBoolean("vision")); null }
                        "theme" -> { vm.theme(j.getString("value")); null }
                        "appLanguage" -> { vm.graph.preferences.appLanguage(j.getString("value")); null }
                        "fastCompression" -> { vm.fastCompression(j.getBoolean("enabled")); null }
                        "sync" -> { vm.syncMinutes(j.getInt("minutes")); null }
                        "clearCache" -> { vm.clearCache(); null }
                        "sourceInfo" -> resolveSource(BridgeCodec.source(j)).toString()
                        "pdfPage" -> {
                            val a=vm.localAttachment(id); vm.graph.attachments.previewPdf(File(a.localPath),j.getInt("page")).absolutePath
                        }
                        "openLink" -> {
                            val uri=android.net.Uri.parse(j.getString("url"))
                            require(uri.scheme in listOf("https","http") && !uri.host.isNullOrBlank() && uri.userInfo==null) { "仅支持打开网页链接" }
                            startActivity(Intent(Intent.ACTION_VIEW,uri).addCategory(Intent.CATEGORY_BROWSABLE)); null
                        }
                        "imageBytes" -> withContext(Dispatchers.IO) { privateFile(j.getString("path")).readBytes().also { require(it.size<=20*1024*1024) } }
                        "openFile" -> { val a=vm.localAttachment(id); val uri=FileProvider.getUriForFile(this@MainActivity,"$packageName.files",privateFile(a.localPath)); startActivity(Intent.createChooser(Intent(Intent.ACTION_VIEW).setDataAndType(uri,a.openMimeType()).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION),"打开附件")); null }
                        "exportFile" -> { require(pickerResult==null) { "请先完成文件选择" }; val a=vm.localAttachment(id); exportFile=privateFile(a.localPath); pickerResult=result; startActivityForResult(Intent(Intent.ACTION_CREATE_DOCUMENT).setType(a.openMimeType()).addCategory(Intent.CATEGORY_OPENABLE).putExtra(Intent.EXTRA_TITLE,a.name),502); return@launch }
                        "pickFile" -> { require(pickerResult==null) { "请先完成文件选择" }; pickerDraft=requireNotNull(vm.state.value.editor); pickerResult=result; startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT).setType("*/*").addCategory(Intent.CATEGORY_OPENABLE),501); return@launch }
                        else -> { result.notImplemented(); return@launch }
                    }
                    result.success(value)
                } catch(e: CancellationException) { result.error("cancelled","操作已取消",null) }
                catch(e: Exception) { result.error("mailpilot",app.mailpilot.mail.friendlyMailError(e),null) }
            }
        }
    }
    private fun privateFile(path: String): File {
        val f=File(path).canonicalFile
        require(listOf(filesDir,cacheDir).any { f.path.startsWith(it.canonicalPath+File.separator) }) { "文件路径不属于本应用" }
        require(f.exists() && f.length()<=20L*1024*1024) { "文件不存在或超限" }; return f
    }
    private suspend fun resolveSource(s: SourceChunk): JSONObject {
        var image=s.imagePath; var count=0; var page=0
        if(s.attachmentId.isNotBlank()) {
            val a=vm.localAttachment(s.attachmentId)
            if(a.name.endsWith(".pdf",true)) {
                count=vm.graph.attachments.pdfCount(File(a.localPath)); page=(Regex("第 (\\d+) 页").find(s.location)?.groupValues?.get(1)?.toInt()?.minus(1) ?: 0).coerceIn(0,maxOf(0,count-1))
                image=vm.graph.attachments.previewPdf(File(a.localPath),page).absolutePath
            } else if(a.isImageAttachment()) image=vm.graph.attachments.previewImage(File(a.localPath)).absolutePath
            else if(image.isNotBlank() && !File(image).exists()) image=vm.graph.attachments.process(a).firstOrNull { it.location==s.location && it.imagePath.isNotBlank() }?.imagePath.orEmpty()
        }
        return JSONObject(BridgeCodec.source(s)).put("imagePath",image).put("count",count).put("page",page)
            .put("text",if(s.kind=="attachment-preview" && image.isBlank()) "可保存此附件，或使用其他应用打开。" else s.text)
    }
    @Deprecated("Android activity result bridge")
    override fun onActivityResult(requestCode: Int,resultCode: Int,data: Intent?) {
        super.onActivityResult(requestCode,resultCode,data)
        if(requestCode !in listOf(501,502,503)) return
        val pending=pickerResult; pickerResult=null
        val uri=data?.data
        if(resultCode!=RESULT_OK || uri==null) { pending?.success(null); return }
        scope.launch {
            try {
                if(requestCode==503) vm.importMaterial(uri,pickerConversation)
                else if(requestCode==501) { val d=requireNotNull(pickerDraft); require(vm.state.value.editor?.id==d.id) { "草稿已切换，请重新选择附件" }; vm.importFile(uri,d) { if(vm.state.value.editor?.id==it.id) vm.updateEditor(it) } }
                else withContext(Dispatchers.IO) { val file=requireNotNull(exportFile); contentResolver.openOutputStream(uri)?.use { output -> file.inputStream().use { it.copyTo(output) } } ?: error("无法保存文件") }
                pending?.success(null)
            } catch(e: Exception) { pending?.error("file",e.message,null) } finally { exportFile=null; pickerDraft=null; pickerConversation="" }
        }
    }
    override fun onRequestPermissionsResult(requestCode: Int,permissions: Array<out String>,grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode,permissions,grantResults)
        if(requestCode!=601) return
        val pending=permissionResult; permissionResult=null
        if(grantResults.firstOrNull()!=android.content.pm.PackageManager.PERMISSION_GRANTED) { pending?.error("microphone","麦克风权限未开启，可在系统设置中授权后重试",null); return }
        try { speech.start(vm.state.value.settings.speech,permissionCloud); pending?.success(null) }
        catch(e: Exception) { pending?.error("speech",e.message,null) }
    }
    override fun onPause() { if(::speech.isInitialized) speech.cancel(); super.onPause() }
    override fun onDestroy() { if(::speech.isInitialized) speech.cancel(); speechSink=null; permissionResult?.error("cancelled","页面已关闭",null); pickerResult?.error("cancelled","页面已关闭",null); scope.cancel(); store.clear(); super.onDestroy() }
}

