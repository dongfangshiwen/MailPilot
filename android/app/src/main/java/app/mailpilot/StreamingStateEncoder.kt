package app.mailpilot

import app.mailpilot.ai.DraftPartial
import app.mailpilot.ai.ReasoningSnapshot
import app.mailpilot.platform.MailState
import org.json.JSONObject

/** One encoder per channel subscription; only public BridgeCodec data crosses the bridge. */
class StreamingStateEncoder(private val snapshot: (MailState) -> String = BridgeCodec::state) {
    private var previous: MailState? = null
    private var sequence = 0L
    private val epoch=app.mailpilot.data.newId()

    private fun stable(s: MailState) = s.copy(
        streaming = "", reasoning = ReasoningSnapshot(), draftPartial = DraftPartial(),
        // Periodic persistence of the live row is not a history/UI structure change.
        entries=if(s.analyzing) s.entries.filter { it.id!=s.responseId } else s.entries,
        reasoningRecords=if(s.analyzing) s.reasoningRecords.filterKeys { it!=s.responseId } else s.reasoningRecords
    )

    fun encode(s: MailState): String? {
        val old = previous
        if (old == s) return null
        val base = sequence
        val frame = JSONObject().put("streamFrame", 1).put("epoch",epoch).put("sequence", base + 1)
        if (old == null || stable(old) != stable(s)) {
            frame.put("state", JSONObject(snapshot(s)))
        } else {
            frame.put("base", base)
                .put("account", s.activeAccount).put("conversation", s.conversationId)
                .put("response", s.responseId)
                .put("streaming", textChange(old.streaming, s.streaming))
                .put("reasoning", JSONObject(s.reasoning.fields()).apply { if(old.reasoning.previous==s.reasoning.previous) remove("previous") }.put("text", textChange(old.reasoning.text, s.reasoning.text)))
                .put("draftPartial", s.draftPartial.json())
        }
        val encoded = frame.toString()
        previous = s
        sequence = base + 1
        return encoded
    }

    private fun textChange(before: String, after: String): JSONObject {
        val append = after.startsWith(before)
        return JSONObject().put("at", if (append) before.length else 0)
            .put("text", if (append) after.substring(before.length) else after)
    }
}
