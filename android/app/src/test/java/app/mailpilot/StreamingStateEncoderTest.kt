package app.mailpilot

import android.app.Application
import app.mailpilot.ai.ReasoningSnapshot
import app.mailpilot.data.ChatEntry
import app.mailpilot.platform.MailState
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk=[28],application=Application::class)
class StreamingStateEncoderTest {
    private val start = MailState(activeAccount="a",conversationId="c",responseId="r",analyzing=true)

    @Test fun streamFramesAreOrderedAndKeepFullSnapshotsForStructuralChanges() {
        var snapshots=0
        val encoder=StreamingStateEncoder { snapshots++; BridgeCodec.state(it) }
        assertTrue(JSONObject(encoder.encode(start)!!).has("state"))
        val thinking=start.copy(reasoning=ReasoningSnapshot("核对😀",20,"thinking"))
        val second=JSONObject(encoder.encode(thinking)!!)
        assertEquals(1,second.getLong("base")); assertEquals(2,second.getLong("sequence"))
        assertEquals("核对😀",second.getJSONObject("reasoning").getJSONObject("text").getString("text"))
        val next=thinking.copy(reasoning=ReasoningSnapshot("核对😀资料",40,"thinking"))
        val third=JSONObject(encoder.encode(next)!!)
        assertEquals(4,third.getJSONObject("reasoning").getJSONObject("text").getInt("at"))
        assertEquals("资料",third.getJSONObject("reasoning").getJSONObject("text").getString("text"))
        assertEquals(1,snapshots)
        assertNull(encoder.encode(next))
        assertTrue(JSONObject(encoder.encode(next.copy(activeAccount="b",conversationId="other"))!!).has("state"))
        assertEquals(2,snapshots)
        assertTrue(JSONObject(encoder.encode(start.copy(analyzing=false,responseId=""))!!).has("state"))
    }

    @Test fun retryReplacementAndThinkingCompletionDoNotAppendStaleText() {
        val e=StreamingStateEncoder()
        val old=start.copy(streaming="旧的部分回答",reasoning=ReasoningSnapshot("已核对",50,"thinking"))
        e.encode(old)
        val reset=JSONObject(e.encode(old.copy(streaming="新回答",reasoning=old.reasoning.copy(state="completed")))!!)
        assertEquals(0,reset.getJSONObject("streaming").getInt("at"))
        assertEquals("新回答",reset.getJSONObject("streaming").getString("text"))
        assertEquals("completed",reset.getJSONObject("reasoning").getString("state"))
    }

    @Test fun savingActiveRowDoesNotRetransmitHistoryOrPreviousAttempts() {
        val old=ReasoningSnapshot("上次内容",30,"completed",attemptId="previous",runComplete=true)
        val trace=ReasoningSnapshot("当前",40,"thinking",attemptId="current",previous=listOf(old))
        val initial=start.copy(reasoning=trace)
        val encoder=StreamingStateEncoder(); encoder.encode(initial)
        val saved=initial.copy(entries=listOf(trace.attach(ChatEntry(id="r",conversationId="c",role="assistant",text="",resultStatus="running"))),reasoningRecords=mapOf("r" to trace))
        val delta=JSONObject(encoder.encode(saved)!!)
        assertFalse(delta.has("state")); assertFalse(delta.getJSONObject("reasoning").has("previous"))
        val final=JSONObject(encoder.encode(saved.copy(analyzing=false,responseId=""))!!)
        assertTrue(final.has("state"))
    }
    @Test fun longHistoryIsNotSerializedAgainForEveryThinkingFragment() {
        val history=(0 until 100).map { ChatEntry(id="h$it",conversationId="c",role="assistant",text="历史资料".repeat(250)) }
        val base=start.copy(entries=history)
        val encoder=StreamingStateEncoder()
        encoder.encode(base)
        var fullBytes=0L; var deltaBytes=0L
        repeat(100) { n ->
            val state=base.copy(reasoning=ReasoningSnapshot("核对".repeat(n+1),n*32L,"thinking"))
            fullBytes+=BridgeCodec.state(state).toByteArray().size
            val encoded=encoder.encode(state)!!
            assertFalse(JSONObject(encoded).has("state"))
            deltaBytes+=encoded.toByteArray().size
        }
        println("stream29 fullSnapshotBytes=$fullBytes deltaFrameBytes=$deltaBytes frames=100 historyEntries=100")
        assertTrue("Avoid repeatedly transporting history and model catalog",deltaBytes*100<fullBytes)
    }
}
