package app.mailpilot

import android.graphics.Color
import android.graphics.Paint
import android.graphics.pdf.PdfDocument
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import app.mailpilot.attachments.AndroidAttachmentProcessor
import app.mailpilot.attachments.isImageAttachment
import app.mailpilot.attachments.openMimeType
import app.mailpilot.data.*
import app.mailpilot.platform.MailCoordinator
import app.mailpilot.ai.ModelCapabilityResolver
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import kotlinx.coroutines.flow.first
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File

@RunWith(AndroidJUnit4::class)
class NativePlatformTest {
    private val context get()=InstrumentationRegistry.getInstrumentation().targetContext
    @Test fun selectedImagePreviewIsIndependentOfAnalysisAndReusesCache()=runBlocking {
        val mislabeled=Attachment("image","mail","PHOTO.JPG","application/octet-stream",100,"1")
        assertTrue(mislabeled.isImageAttachment()); assertEquals("image/jpeg",mislabeled.openMimeType())
        assertFalse(mislabeled.copy(name="document.docx").isImageAttachment())
        val input=File(context.cacheDir,"image-preview-fixture.bin")
        val processor=AndroidAttachmentProcessor(context)
        val bitmap=android.graphics.Bitmap.createBitmap(96,48,android.graphics.Bitmap.Config.ARGB_8888)
        bitmap.eraseColor(Color.BLUE)
        input.outputStream().use { bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG,100,it) }; bitmap.recycle()
        var preview: File?=null
        try {
            val original=input.readBytes()
            preview=processor.previewImage(input)
            val decoded=android.graphics.BitmapFactory.decodeFile(preview.absolutePath)
            assertNotNull(decoded); assertEquals(96,decoded.width); assertEquals(48,decoded.height); decoded.recycle()
            assertEquals(preview.absolutePath,processor.previewImage(input).absolutePath)
            assertArrayEquals(original,input.readBytes())
            val corrupt=File(context.cacheDir,"invalid-preview.png").apply { writeText("not an image") }
            try { assertTrue(runCatching { processor.previewImage(corrupt) }.exceptionOrNull()?.message.orEmpty().contains("图片格式")) }
            finally { corrupt.delete() }
        } finally { input.delete(); preview?.delete() }
    }
    @Test fun attachmentPreviewNavigationDoesNotDownloadOrSelectOtherAttachments()=runBlocking {
        val app=context.applicationContext as MailPilotApp; app.graph.ready.await()
        val store=androidx.lifecycle.ViewModelStore(); lateinit var vm: MailCoordinator
        val instrumentation=InstrumentationRegistry.getInstrumentation()
        instrumentation.runOnMainSync { vm=androidx.lifecycle.ViewModelProvider(store,androidx.lifecycle.ViewModelProvider.AndroidViewModelFactory.getInstance(app))[MailCoordinator::class.java] }
        try {
            withTimeout(10000) { vm.state.first { it.ready } }
            // No database row/file exists. Navigation must not look up or fetch it.
            val selected=Attachment("preview-only","mail-fixture","photo.PNG","application/octet-stream",1024,"1")
            instrumentation.runOnMainSync { vm.preview(selected) }
            assertEquals(selected.id,vm.state.value.source?.attachmentId)
            assertFalse(vm.state.value.busy); assertTrue(vm.state.value.selection.isEmpty())
            instrumentation.runOnMainSync { vm.showSource(null) }
            assertNull(vm.state.value.source)
        } finally { instrumentation.runOnMainSync { store.clear() } }
    }
    @Test fun modelCredentialVersionSurvivesSaveAndReloadWithoutMakingDiagnosticsAGate()=runBlocking {
        val app=context.applicationContext as MailPilotApp; val graph=app.graph; graph.ready.await()
        val original=graph.preferences.flow.first().textModelId
        val store=androidx.lifecycle.ViewModelStore(); lateinit var vm: MailCoordinator
        InstrumentationRegistry.getInstrumentation().runOnMainSync { vm=androidx.lifecycle.ViewModelProvider(store,androidx.lifecycle.ViewModelProvider.AndroidViewModelFactory.getInstance(app))[MailCoordinator::class.java] }
        val initial=ModelProfile(model="doubao-seed-evolving",baseUrl="https://ark.cn-beijing.volces.com/api/v3",apiKeyCipher=graph.secrets.encrypt("fixture-key"),credentialVersion="fixture-revision")
        val tested=initial.copy(diagnosticIdentity=ModelCapabilityResolver.identity(initial),diagnosticsJson="{\"图片\":{\"status\":\"failed\",\"type\":\"permission\"}}")
        try {
            withTimeout(10000) { vm.state.first { it.ready } }
            vm.saveModel(tested,"fixture-key")
            var saved=graph.dao.model(initial.id)!!
            assertTrue(ModelCapabilityResolver.diagnosticCurrent(saved))
            vm.saveModel(saved.copy(label="renamed",thinkingMode="enabled",reasoningEffort="high"),"")
            saved=graph.dao.model(initial.id)!!
            assertTrue(ModelCapabilityResolver.diagnosticCurrent(saved))
            assertEquals("supported",ModelCapabilityResolver.vision(saved))
            vm.saveModel(saved,"replacement-fixture-key")
            saved=graph.dao.model(initial.id)!!
            assertFalse(ModelCapabilityResolver.diagnosticCurrent(saved))
            assertEquals("replacement-fixture-key",graph.secrets.decrypt(saved.apiKeyCipher))
            assertEquals("supported",ModelCapabilityResolver.vision(saved))
            assertFalse(org.json.JSONObject(BridgeCodec.model(saved)).toString().contains("replacement-fixture-key"))
        } finally { graph.dao.deleteModel(initial.id); graph.preferences.set("textModel",original); InstrumentationRegistry.getInstrumentation().runOnMainSync { store.clear() } }
    }
    @Test fun voicePermissionAndCloudCancellationKeepAudioLocalAndDeleteIt()=runBlocking {
        val instrumentation=InstrumentationRegistry.getInstrumentation()
        val events=java.util.concurrent.CopyOnWriteArrayList<Map<String,Any>>()
        val scope=kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.SupervisorJob()+kotlinx.coroutines.Dispatchers.Main)
        var service: app.mailpilot.services.AndroidSpeechInput?=null
        androidx.test.core.app.ActivityScenario.launch(MainActivity::class.java).use { scenario ->
            try {
                scenario.onActivity { activity ->
                    service=app.mailpilot.services.AndroidSpeechInput(activity,scope,(context.applicationContext as MailPilotApp).graph.asr) { events+=it }
                    assertTrue(runCatching { service!!.start(ServiceConfig()) }.exceptionOrNull()?.message.orEmpty().contains("麦克风权限"))
                }
                instrumentation.uiAutomation.grantRuntimePermission(instrumentation.targetContext.packageName,android.Manifest.permission.RECORD_AUDIO)
                scenario.onActivity { activity ->
                    if(!android.speech.SpeechRecognizer.isRecognitionAvailable(activity)) {
                        assertTrue(runCatching { service!!.start(ServiceConfig()) }.exceptionOrNull()?.message.orEmpty().contains("系统语音服务"))
                    }
                    // Cancelling while recording must never contact the configured cloud endpoint.
                    service!!.start(ServiceConfig(mode="cloud",baseUrl="https://unused.invalid/v1",keyCipher="unused-test-key"),true)
                }
                kotlinx.coroutines.delay(700)
                scenario.onActivity { service!!.cancel() }
                kotlinx.coroutines.delay(500)
                assertTrue(events.none { it["state"]=="result" })
                assertTrue(File(context.cacheDir,"speech").listFiles().orEmpty().isEmpty())
            } finally { scenario.onActivity { service?.cancel() }; scope.coroutineContext[kotlinx.coroutines.Job]?.cancel() }
        }
    }
    @Test fun phoneMaterialSelectionIsSeparateFromMailAndDraftAttachments()=runBlocking {
        val graph=(context.applicationContext as MailPilotApp).graph; graph.ready.await()
        val store=androidx.lifecycle.ViewModelStore(); lateinit var vm: MailCoordinator
        val input=File(context.cacheDir,"preview/phone-test.txt").apply { parentFile!!.mkdirs(); writeText("手机上的资料") }
        InstrumentationRegistry.getInstrumentation().runOnMainSync { vm=androidx.lifecycle.ViewModelProvider(store,androidx.lifecycle.ViewModelProvider.AndroidViewModelFactory.getInstance(context.applicationContext as MailPilotApp))[MailCoordinator::class.java] }
        try {
            withTimeout(10000) { vm.state.first { it.ready } }
            val id=vm.state.value.conversationId
            vm.importMaterial(androidx.core.content.FileProvider.getUriForFile(context,"app.mailpilot.files",input),id)
            withTimeout(10000) { vm.state.first { it.localMaterials.isNotEmpty() } }
            assertTrue(vm.state.value.selection.isEmpty()); assertNull(vm.state.value.editor)
            val imported=vm.state.value.localMaterials.single()
            assertEquals("手机上的资料",File(imported.path).readText())
            assertNotNull(androidx.core.content.FileProvider.getUriForFile(context,"app.mailpilot.files",File(imported.path)))
            kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.Main) { vm.clearSelection() }
            withTimeout(10000) { vm.state.first { it.localMaterials.none { m -> m.selected } } }
            assertEquals(id,vm.state.value.conversationId); assertTrue(File(imported.path).exists())
            InstrumentationRegistry.getInstrumentation().runOnMainSync { vm.deleteConversation(id) }
            withTimeout(10000) { vm.state.first { it.conversationId!=id && !it.busy } }
            assertFalse(File(imported.path).exists())
        } finally { input.delete(); InstrumentationRegistry.getInstrumentation().runOnMainSync { store.clear() } }
    }
    @Test fun optInRealImapTlsWithRoutedSocket() {
        org.junit.Assume.assumeTrue(InstrumentationRegistry.getArguments().getString("liveImapTls")=="true")
        val host="imap.qq.com"
        val properties=java.util.Properties().apply {
            put("mail.imap.socketFactory",app.mailpilot.mail.RouteSocketFactory())
            put("mail.imap.socketFactory.fallback","false")
            put("mail.imap.ssl.checkserveridentity","true")
            put("mail.imap.connectiontimeout","15000")
            put("mail.imap.timeout","20000")
            put("mail.imap.writetimeout","20000")
        }
        org.eclipse.angus.mail.util.SocketFetcher.getSocket(host,993,properties,"mail.imap",true).use { tls ->
            assertTrue(tls is javax.net.ssl.SSLSocket)
            val greeting=tls.inputStream.bufferedReader(Charsets.US_ASCII).readLine()
            assertTrue(greeting.startsWith("* OK"))
            // Actual Angus TLS, including write timeout wrapper and hostname
            // checking. No authentication, mail read or SMTP transmission.
        }
    }
    @Test fun startupUsesCacheAndOnlyManualRefreshConnects(): Unit=runBlocking {
        val app=context.applicationContext as MailPilotApp; val graph=app.graph
        graph.ready.await()
        val original=graph.preferences.flow.first()
        val socket=java.net.ServerSocket(0,1,java.net.InetAddress.getByName("127.0.0.1"))
        val account=MailAccount(label="startup-test",email="fixture@example.test",passwordCipher=graph.secrets.encrypt("fixture"),imapHost="127.0.0.1",imapPort=socket.localPort,smtpHost="127.0.0.1")
        val store=androidx.lifecycle.ViewModelStore()
        lateinit var vm: MailCoordinator
        try {
            graph.dao.putAccount(account); graph.preferences.set("account",account.id)
            InstrumentationRegistry.getInstrumentation().runOnMainSync {
                vm=androidx.lifecycle.ViewModelProvider(store,androidx.lifecycle.ViewModelProvider.AndroidViewModelFactory.getInstance(app))[MailCoordinator::class.java]
            }
            withTimeout(10000) { vm.state.first { it.ready && it.activeAccount==account.id } }
            socket.soTimeout=1500
            assertTrue(runCatching { socket.accept().close() }.exceptionOrNull() is java.net.SocketTimeoutException)
            assertFalse(vm.state.value.busy)
            InstrumentationRegistry.getInstrumentation().runOnMainSync { vm.refresh() }
            socket.soTimeout=10000; socket.accept().close()
        } finally {
            graph.sync.cancel(account.id)
            InstrumentationRegistry.getInstrumentation().runOnMainSync { store.clear() }
            socket.close(); graph.preferences.set("account",original.accountId); graph.dao.deleteAccount(account.id)
        }
    }
    @Test fun changingSelectionsAndFoldersRetainsTheCurrentChatWithoutConnecting(): Unit=runBlocking {
        val app=context.applicationContext as MailPilotApp; val g=app.graph; g.ready.await()
        val original=g.preferences.flow.first(); val account=MailAccount(label="selection-fixture",email="selection@example.test")
        val vmStore=androidx.lifecycle.ViewModelStore(); lateinit var vm: MailCoordinator
        val main=InstrumentationRegistry.getInstrumentation()
        try {
            g.dao.putAccount(account); g.preferences.set("account",account.id)
            main.runOnMainSync { vm=androidx.lifecycle.ViewModelProvider(vmStore,androidx.lifecycle.ViewModelProvider.AndroidViewModelFactory.getInstance(app))[MailCoordinator::class.java] }
            withTimeout(10000) { vm.state.first { it.activeAccount==account.id && it.ready } }
            val id=vm.state.value.conversationId
            g.dao.putConversation(Conversation(id=id,title="保留聊天",accountId=account.id))
            g.dao.putEntry(ChatEntry(conversationId=id,role="assistant",text="上一轮的分析"))
            g.dao.putMessages(listOf(MailMessage("selection-mail",account.id,"INBOX",1,1,"示例","sender","sender@example.test",sentAt=0,body="正文",unread=false)))
            val attachment=Attachment("selection-file","selection-mail","说明.txt","text/plain",12,"0")
            g.dao.putAttachments(listOf(attachment))
            withTimeout(10000) { vm.state.first { it.entries.isNotEmpty() } }
            kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.Main) { vm.toggleMessage("selection-mail"); vm.selectAttachment(attachment); vm.clearSelection(); vm.toggleMessage("selection-mail"); vm.folder("Sent") }
            assertEquals(id,vm.state.value.conversationId); assertEquals("上一轮的分析",vm.state.value.entries.single().text)
            assertEquals("selection-mail",vm.state.value.selection.single().messageId)
            assertFalse(vm.state.value.busy); assertFalse(vm.state.value.syncing)
            main.runOnMainSync { vm.newConversation() }
            assertNotEquals(id,vm.state.value.conversationId)
        } finally {
            main.runOnMainSync { vmStore.clear() }; g.preferences.set("account",original.accountId)
            g.dao.deleteMessages(account.id); g.dao.purgeOrphanAttachments(); g.dao.deleteAccountEntries(account.id); g.dao.deleteAccountConversations(account.id); g.dao.deleteAccount(account.id)
        }
    }
    @Test fun channelListsUsePreviewAndOnlyDetailsCarryFullBody() {
        val message=MailMessage("channel-mail","fixture","INBOX",1,1,"主题","测试","test@example.test",sentAt=0,preview="简短预览",body="full-body-only-in-details")
        val listing=BridgeCodec.state(app.mailpilot.platform.MailState(messages=listOf(message)))
        assertTrue(listing.contains("简短预览"))
        assertFalse(listing.contains(message.body))
        assertTrue(BridgeCodec.state(app.mailpilot.platform.MailState(detail=message)).contains(message.body))
    }
    @Test fun nativePdfRendersVectorAndScannedPagesWithoutOcr(): Unit=runBlocking {
        val pdf=File(context.cacheDir,"platform-test.pdf")
        val doc=PdfDocument()
        try {
            repeat(2) { index ->
                val page=doc.startPage(PdfDocument.PageInfo.Builder(595,842,index+1).create())
                val paint=Paint().apply { color=Color.BLACK; textSize=24f }
                page.canvas.drawColor(Color.WHITE)
                if(index==0) page.canvas.drawText("Vector budget: 12000",40f,80f,paint)
                else {
                    val bitmap=android.graphics.Bitmap.createBitmap(595,842,android.graphics.Bitmap.Config.ARGB_8888)
                    try {
                        val canvas=android.graphics.Canvas(bitmap); canvas.drawColor(Color.WHITE)
                        canvas.drawText("扫描页面 / Scanned budget: 12000",30f,80f,paint)
                        page.canvas.drawBitmap(bitmap,0f,0f,null)
                    } finally { bitmap.recycle() }
                }
                doc.finishPage(page)
            }
            pdf.outputStream().use { doc.writeTo(it) }
        } finally { doc.close() }
        val processor=AndroidAttachmentProcessor(context)
        try {
            assertEquals(2,processor.pdfCount(pdf))
            val attachment=Attachment("platform-pdf","platform-mail","预算.pdf","application/pdf",pdf.length(),"0",pdf.absolutePath)
            val pages=processor.process(attachment,listOf(0,1))
            assertEquals(2,pages.size)
            assertEquals("第 2 页",pages.last().location)
            pages.forEach { assertTrue(File(it.imagePath).length()>0) }
            assertNotNull(runCatching { processor.process(attachment,emptyList()) }.exceptionOrNull())
            assertNotNull(runCatching { processor.process(attachment,(0..20).toList()) }.exceptionOrNull())
        } finally { pdf.delete() }
    }
    @Test fun keystoreEncryptsUniquelyAndChannelOmitsCredentials() {
        val secrets=AndroidSecrets(); val value="platform-test-secret"
        val first=secrets.encrypt(value); val second=secrets.encrypt(value)
        assertNotEquals(first,second); assertFalse(first.contains(value))
        assertEquals(value,secrets.decrypt(first)); assertEquals(value,secrets.decrypt(second))
        val account=BridgeCodec.account(MailAccount(passwordCipher=first))
        val model=BridgeCodec.model(ModelProfile(apiKeyCipher=second))
        assertEquals(true,account["hasSecret"]); assertEquals(true,model["hasSecret"])
        assertFalse(account.containsKey("passwordCipher")); assertFalse(model.containsKey("apiKeyCipher"))
    }
    @Test fun androidMailProvidersAndChineseMimeRemainUsable() {
        val session=jakarta.mail.Session.getInstance(java.util.Properties())
        session.getStore("imap").use { assertFalse(it.isConnected) }
        session.getTransport("smtp").use { assertFalse(it.isConnected) }
        val message=jakarta.mail.internet.MimeMessage(session).apply {
            setFrom("test@example.test"); setRecipients(jakarta.mail.Message.RecipientType.TO,"recipient@example.test")
            setSubject("中文附件测试","UTF-8"); setText("预算为 12000 元。","UTF-8"); saveChanges()
        }
        val bytes=java.io.ByteArrayOutputStream().also { message.writeTo(it) }.toByteArray()
        val parsed=jakarta.mail.internet.MimeMessage(session,bytes.inputStream())
        assertEquals("中文附件测试",parsed.subject)
        assertTrue(app.mailpilot.mail.MimeReader.parse(parsed,"fixture").plain.contains("12000"))
    }
}

