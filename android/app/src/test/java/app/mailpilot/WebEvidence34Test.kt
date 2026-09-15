package app.mailpilot

import android.app.Application
import app.mailpilot.ai.WebEvidenceStore
import app.mailpilot.data.*
import org.junit.*
import org.junit.Assert.*
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import java.nio.file.Files

@RunWith(RobolectricTestRunner::class)
@Config(sdk=[28],application=Application::class)
class WebEvidence34Test {
    private val root=Files.createTempDirectory("web34-").toFile()
    private val source=SourceChunk(id="S1",messageId="",title="large page",location="web",text="事实与来源。".repeat(200_000),kind="web",retrieval="webpage",url="https://example.org")
    @After fun cleanup() { root.deleteRecursively() }
    @Test fun largePagesKeepRowsSmallAndRestoreAfterRestart() {
        val stored=WebEvidenceStore(root,"a","c").save(source)
        val json=JsonCodec.sources(List(8) { stored.copy(id="S$it") })
        assertTrue(json.toByteArray().size<128_000)
        assertEquals(source.text,WebEvidenceStore(root,"a","c").restore(JsonCodec.sources(json).first()).text)
        assertEquals(source.text.length,stored.text.length)
    }
    @Test fun accountAndConversationCannotReadEachOthersFiles() {
        val stored=JsonCodec.sources(JsonCodec.sources(listOf(WebEvidenceStore(root,"a","c").save(source)))).single()
        assertEquals("excerpt",WebEvidenceStore(root,"b","c").restore(stored).retrieval)
        assertEquals("excerpt",WebEvidenceStore(root,"a","d").restore(stored).retrieval)
        assertEquals("excerpt",WebEvidenceStore(root,"a","c").restore(stored.copy(contentKey="../../secret")).retrieval)
    }
    @Test fun missingOrChangedFilesAreNotPresentedAsCompletePages() {
        val store=WebEvidenceStore(root,"a","c"); val saved=store.save(source)
        root.walkTopDown().single { it.extension=="txt" }.writeText("changed")
        assertEquals("excerpt",store.restore(saved.copy(text="preview")).retrieval)
        store.clear()
        assertEquals("",store.restore(saved.copy(text="preview")).contentKey)
        assertEquals("preview",store.restore(saved.copy(text="preview")).text)
    }
    @Test fun deletingOneConversationKeepsOtherAccountAndConversation() {
        val a=WebEvidenceStore(root,"a","c"); val b=WebEvidenceStore(root,"a","d"); val other=WebEvidenceStore(root,"b","c")
        val saved=a.save(source); b.save(source); other.save(source)
        a.clear(); assertEquals("webpage",b.restore(saved).retrieval)
        WebEvidenceStore.clearAccount(root,"a")
        assertEquals("excerpt",b.restore(saved).retrieval); assertEquals("webpage",other.restore(saved).retrieval)
    }
}
