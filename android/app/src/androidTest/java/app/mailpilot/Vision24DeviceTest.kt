package app.mailpilot

import android.graphics.Bitmap
import androidx.room.Room
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import app.mailpilot.ai.*
import app.mailpilot.attachments.*
import app.mailpilot.data.*
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import org.json.*
import org.junit.Test
import org.junit.Assert.*
import org.junit.runner.RunWith
import java.io.File

@RunWith(AndroidJUnit4::class)
class Vision24DeviceTest {
    @Test fun processedImagesAndEvidenceSurviveDatabaseReopen(): Unit=runBlocking {
        val context=InstrumentationRegistry.getInstrumentation().targetContext
        val name="device24-${System.nanoTime()}.db"
        var db=Room.databaseBuilder(context,MailDatabase::class.java,name).build()
        val raw=File(context.cacheDir,"fixture24-${System.nanoTime()}.png")
        try {
            db.dao().putConversation(Conversation(id="c"))
            val b=Bitmap.createBitmap(640,480,Bitmap.Config.ARGB_8888); b.eraseColor(0xff3060a0.toInt())
            raw.outputStream().use { b.compress(Bitmap.CompressFormat.PNG,100,it) }; b.recycle()
            val processor=AndroidAttachmentProcessor(context)
            val prepared=processor.previewImage(raw); val again=processor.previewImage(raw)
            assertEquals(prepared.path,again.path)
            val items=(1..10).map { SourceChunk(id="T1:S$it",messageId="",title="样例 $it",location="图片",imagePath=prepared.path,assetKey="asset$it",imageWidth=640,imageHeight=480) }
            val profile=ModelProfile(model="doubao-seed-evolving",provider="volcengine",baseUrl="https://ark.cn-beijing.volces.com/api/v3",contextTokens=1048576)
            assertEquals(1,VisionRequestPlanner.plan(profile,items).batches.size)
            val body=ModelJsonBody(JSONObject().put("messages",JSONArray().put(VisionRequestPlanner.message("逐图说明",items))))
            val encoded=okio.Buffer(); body.writeTo(encoded); assertEquals(body.contentLength(),encoded.size)
            val json=JSONObject(encoded.readUtf8()); val parts=json.getJSONArray("messages").getJSONObject(0).getJSONArray("content")
            assertEquals(10,(0 until parts.length()).count { parts.getJSONObject(it).optString("type")=="image_url" })
            VisualEvidenceStore(db.dao(),"c","").save(items,"原问题","此前完整分析。","fixture","answer","r1")
            db.close(); db=Room.databaseBuilder(context,MailDatabase::class.java,name).build()
            val store=VisualEvidenceStore(db.dao(),"c","")
            assertTrue(store.lookup(items,emptySet()).missing.isEmpty())
            assertEquals(1,store.lookup(items,setOf("asset4")).missing.size)
            assertTrue(VisualEvidenceStore(db.dao(),"c","different-account").lookup(items,emptySet()).records.isEmpty())
            db.dao().deleteConversation("c"); assertTrue(db.dao().visualEvidence("c","").isEmpty())
        } finally { db.close(); context.deleteDatabase(name); raw.delete() }
    }
}
