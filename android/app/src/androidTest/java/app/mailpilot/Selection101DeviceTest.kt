package app.mailpilot

import android.graphics.*
import android.graphics.pdf.PdfDocument
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.lifecycle.*
import app.mailpilot.attachments.*
import app.mailpilot.ai.contentFingerprint
import app.mailpilot.data.*
import app.mailpilot.platform.MailCoordinator
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.first
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File

@RunWith(AndroidJUnit4::class)
class Selection101DeviceTest {
    private val app get()=InstrumentationRegistry.getInstrumentation().targetContext.applicationContext as MailPilotApp
    private fun pdf(count: Int): File {
        val file=File.createTempFile("selection101-",".pdf",app.cacheDir)
        val doc=PdfDocument()
        try {
            repeat(count) { i ->
                val page=doc.startPage(PdfDocument.PageInfo.Builder(595,842,i+1).create())
                page.canvas.drawColor(Color.WHITE)
                page.canvas.drawText("Document page ${i+1}",30f,70f,Paint().apply { color=Color.BLACK; textSize=24f })
                doc.finishPage(page)
            }
            file.outputStream().use { doc.writeTo(it) }
        } finally { doc.close() }
        return file
    }
    @Test fun realPdfCountsLazy480ThumbnailsFullPreviewAndCache(): Unit=runBlocking {
        val processor=AndroidAttachmentProcessor(app)
        for(count in listOf(1,9,10,11,20,80)) {
            val file=pdf(count); val root=File(app.cacheDir,"preview")
            val prefix=stableId(contentFingerprint(file)+"pdf-v1")
            try {
                assertEquals(count,processor.pdfCount(file))
                assertTrue(root.listFiles().orEmpty().none { it.name.startsWith(prefix) })
                val thumb=processor.thumbnailPdf(file,count-1)
                BitmapFactory.decodeFile(thumb.path).also { bitmap -> assertEquals(480,maxOf(bitmap.width,bitmap.height)); bitmap.recycle() }
                val timestamp=thumb.lastModified()
                assertEquals(thumb.path,processor.thumbnailPdf(file,count-1).path)
                assertEquals(timestamp,thumb.lastModified())
                assertEquals(1,root.listFiles().orEmpty().count { it.name.startsWith(prefix) })
                val full=processor.previewPdf(file,count-1)
                BitmapFactory.decodeFile(full.path).also { bitmap -> assertEquals(2048,maxOf(bitmap.width,bitmap.height)); bitmap.recycle() }
                assertNotEquals(thumb.path,full.path)
                assertEquals(2,root.listFiles().orEmpty().count { it.name.startsWith(prefix) })
                assertTrue(runCatching { processor.thumbnailPdf(file,count) }.isFailure)
            } finally { root.listFiles().orEmpty().filter { it.name.startsWith(prefix) }.forEach { it.delete() }; file.delete() }
        }
        val bad=File.createTempFile("selection101-invalid-",".pdf",app.cacheDir).apply { writeText("not a PDF") }
        try { assertTrue(runCatching { processor.pdfCount(bad) }.isFailure) } finally { bad.delete() }
    }
    @Test fun metadataDefaultsManualOverridesAndPdfCommitPreserveChat(): Unit=runBlocking {
        val g=app.graph; g.ready.await(); val original=g.preferences.flow.first()
        val account=MailAccount(email="selection101@example.test",imapHost="unused.invalid")
        val store=ViewModelStore(); lateinit var vm: MailCoordinator
        val id=newId(); val file=pdf(9)
        val p=Attachment(newId(),id,"报价.pdf","application/pdf",file.length(),"1",file.path)
        val txt=Attachment(newId(),id,"说明.txt","text/plain",100,"2")
        val legacy=Attachment(newId(),id,"旧文档.doc","application/msword",100,"3")
        try {
            g.dao.putAccount(account); g.preferences.set("account",account.id)
            g.dao.putMessages(listOf(MailMessage(id,account.id,"INBOX",1,1,"资料测试","sender","sender@example.test",sentAt=0,unread=false,attachmentCount=4)))
            g.dao.putAttachments(listOf(p,txt,legacy))
            withContext(Dispatchers.Main) { vm=ViewModelProvider(store,ViewModelProvider.AndroidViewModelFactory.getInstance(app))[MailCoordinator::class.java] }
            withTimeout(10000) { vm.state.first { it.ready && it.activeAccount==account.id } }
            val chat=vm.state.value.conversationId
            g.dao.putConversation(Conversation(id=chat,accountId=account.id))
            withContext(Dispatchers.Main) { vm.toggleMessage(id) }
            assertEquals(setOf(p.id,txt.id),vm.state.value.selection.single().attachmentIds.toSet())
            assertNull(vm.state.value.pdfChoice); assertFalse(vm.state.value.busy)
            withTimeout(10000) { vm.state.first { it.selectionGroups.isNotEmpty() } }
            assertEquals(true,vm.state.value.selectionGroups.single()["pending"])
            withContext(Dispatchers.Main) { vm.selectAttachment(txt); vm.folder("Sent") }
            assertEquals(listOf(p.id),vm.state.value.selection.single().attachmentIds)
            val late=txt.copy(id=newId(),name="后来同步的.txt")
            g.dao.putAttachments(listOf(late))
            vm.refreshSelectionSummary()
            withTimeout(10000) { vm.state.first { it.selectionGroups.singleOrNull()?.get("pending")==false } }
            assertEquals(listOf(p.id),vm.state.value.selection.single().attachmentIds)
            withContext(Dispatchers.Main) { vm.editPdf(p) }
            withTimeout(10000) { vm.state.first { it.pdfChoice?.loading==false } }
            assertEquals((0..8).toList(),vm.state.value.pdfChoice!!.selected)
            val firstToken=vm.state.value.pdfChoice!!.token
            withContext(Dispatchers.Main) { vm.dismissPdf(); vm.editPdf(p) }
            withTimeout(10000) { vm.state.first { it.pdfChoice?.loading==false } }
            withContext(Dispatchers.Main) { vm.choosePdf(emptyList(),firstToken) }
            assertNotNull(vm.state.value.pdfChoice)
            withContext(Dispatchers.Main) { vm.choosePdf(listOf(2,4),vm.state.value.pdfChoice!!.token) }
            assertEquals(listOf(2,4),vm.state.value.selection.single().pdfPages[p.id])
            assertTrue(vm.state.value.selection.single().defaultPdfIds.isEmpty())
            withContext(Dispatchers.Main) { vm.toggleMessage(id); vm.toggleMessage(id) }
            assertEquals(setOf(p.id,txt.id,late.id),vm.state.value.selection.single().attachmentIds.toSet())
            assertEquals(listOf(p.id),vm.state.value.selection.single().defaultPdfIds)
            assertEquals(chat,vm.state.value.conversationId)
            withTimeout(10000) { while(JsonCodec.selections(g.dao.conversation(chat)!!.selectionJson)!=vm.state.value.selection) delay(50) }
            // Persisted explicit legacy selection remains unchanged on reopening.
            val legacyChat=Conversation(id=chat,accountId=account.id,selectionJson="""[{"messageId":"$id","attachmentIds":[],"pdfPages":{}}]""")
            withContext(Dispatchers.Main) { vm.loadConversation(legacyChat) }
            assertTrue(vm.state.value.selection.single().attachmentIds.isEmpty())
            // Clearing also persists phone-file deselection, without changing frozen turns or deleting files.
            val local=LocalMaterial(conversationId=chat,name="手机资料.pdf",mime="application/pdf",path=file.path,size=file.length(),pagesJson="[0]")
            g.dao.putMaterial(local)
            withTimeout(10000) { vm.state.first { it.localMaterials.any { m -> m.id==local.id && m.selected } } }
            withContext(Dispatchers.Main) { vm.selectMessageFiles(id,false) }
            val frozen=TurnSnapshot(newId(),chat,account.id,"INBOX",JsonCodec.selections(vm.state.value.selection),1,localJson=org.json.JSONArray(listOf(local.fields())).toString())
            g.dao.putTurn(frozen)
            withContext(Dispatchers.Main) {
                // Start reads concurrently; the final clear must win over every earlier toggle.
                coroutineScope {
                    repeat(12) { launch(start=CoroutineStart.UNDISPATCHED) { vm.toggleMessage(id) } }
                    launch(start=CoroutineStart.UNDISPATCHED) { vm.clearSelection() }
                }
            }
            assertTrue(vm.state.value.selection.isEmpty())
            assertTrue(vm.state.value.localMaterials.none { it.selected })
            assertTrue(JsonCodec.selections(g.dao.conversation(chat)!!.selectionJson).isEmpty())
            assertFalse(g.dao.material(local.id)!!.selected)
            assertEquals(frozen,g.dao.turn(frozen.id)); assertTrue(file.isFile)
            val saved=g.dao.conversation(chat)!!
            withContext(Dispatchers.Main) { vm.loadConversation(saved) }
            withTimeout(10000) { vm.state.first { it.localMaterials.any { m -> m.id==local.id } } }
            assertTrue(vm.state.value.selection.isEmpty()); assertFalse(vm.state.value.localMaterials.single { it.id==local.id }.selected)
            withContext(Dispatchers.Main) { vm.toggleMessage(id) }
            assertEquals(setOf(p.id,txt.id,late.id),vm.state.value.selection.single().attachmentIds.toSet())
            assertFalse(vm.state.value.localMaterials.single { it.id==local.id }.selected)
            assertFalse(vm.state.value.analyzing); assertEquals(chat,vm.state.value.conversationId)
            // An invalid retained attachment must block preflight, rather than silently disappearing from totals.
            val missing=saved.copy(selectionJson=JsonCodec.selections(listOf(Selection(id,listOf("removed-file")))))
            withContext(Dispatchers.Main) { vm.loadConversation(missing) }
            assertEquals(true,vm.selectionSummary()["blocked"])
        } finally {
            withContext(Dispatchers.Main) { store.clear() }
            g.preferences.set("account",original.accountId)
            g.dao.deleteAccountEntries(account.id); g.dao.deleteAccountConversations(account.id)
            g.dao.purgeOrphanTurns()
            g.dao.deleteMessages(account.id); g.dao.purgeOrphanAttachments(); g.dao.deleteAccount(account.id); file.delete()
        }
    }
}
