package app.mailpilot

import android.app.Application
import app.mailpilot.ai.*
import org.json.*
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk=[28],application=Application::class)
class ActionJsonTest {
    private val registry=AgentActions.forCapabilities(true,true,true)
    private val read="""{"mailpilot_action":"read_web_page","arguments":{"source_ids":["T2:S1","T2:S3"]}}"""
    private fun calls(text: String)=registry.normalize(roleMessage("assistant",text),false).getJSONArray("tool_calls")
    private fun rejected(text: String) { assertTrue(runCatching { calls(text) }.exceptionOrNull() is ModelFailure) }
    @Test fun completeTerminalReadWithProseWorksInBothProtocols() {
        for(native in listOf(false,true)) for(text in listOf(read,"先核对来源。\n$read","先核对来源。\n```json\n$read\n```")) {
            val f=registry.normalize(roleMessage("assistant",text),native).getJSONArray("tool_calls").getJSONObject(0).getJSONObject("function")
            assertEquals("read_web_page",f.getString("name")); assertEquals(2,JSONObject(f.getString("arguments")).getJSONArray("source_ids").length())
        }
    }
    @Test fun multipleReadsPreserveEveryDecisionAndFeedback() {
        val answer=registry.normalize(roleMessage("assistant",read+"\n"+read.replace("T2:S1","T2:S4")),false)
        val a=answer.getJSONArray("tool_calls"); assertEquals(2,a.length())
        val results=JSONArray().apply { for(i in 0..1) put(JSONObject().put("content","source $i")) }
        val feedback=registry.feedback(answer,results,false)
        assertEquals(2,calls(feedback.first().getString("content")).length())
        assertTrue(feedback.first().getString("content").contains("T2:S4"))
    }
    @Test fun splitStringsAndEscapesDoNotLeakOrChangeArguments() {
        val action=JSONObject().put("mailpilot_action","web_search").put("arguments",JSONObject().put("queries",JSONArray(listOf("a {b} \"c\" \\d")))).toString()
        val prefix="核对公开资料。"; val wire=prefix+action
        var prior=""
        for(i in 1..wire.length) {
            val next=registry.visible(wire.take(i)); assertTrue(next.startsWith(prior)); assertTrue(prefix.startsWith(next)); prior=next
        }
        assertEquals("a {b} \"c\" \\d",JSONObject(calls(wire).getJSONObject(0).getJSONObject("function").getString("arguments")).getJSONArray("queries").getString(0))
    }
    @Test fun malformedLastDecisionRejectsWholeBatch() {
        for(text in listOf(read+"\n"+read.dropLast(1),read+"\n{\"other\":1}",read+" 多余文字",read.repeat(5),read.replace("[\"T2:S1\",\"T2:S3\"]","[\"T2:S1\",]"))) rejected(text)
    }
    @Test fun duplicateKeysAndNativeArgumentTailsAreRejected() {
        rejected(read.replace("\"source_ids\":","\"source_ids\":[],\"source_ids\":"))
        val answer=registry.normalize(roleMessage("assistant",read),false)
        val f=answer.getJSONArray("tool_calls").getJSONObject(0).getJSONObject("function")
        f.put("arguments",f.getString("arguments")+"{}")
        assertTrue(runCatching { registry.normalize(answer,true) }.exceptionOrNull() is ModelFailure)
    }
    @Test fun quotedAndNestedExamplesAreNotExecuted() {
        for(text in listOf("示例：`$read`","> $read",JSONObject().put("example",JSONObject(read)).toString(),"{\"example\":\"mailpilot_action\"}")) {
            assertEquals(text,registry.normalize(roleMessage("assistant",text),false).getString("content"))
        }
    }
    @Test fun compatibilityCannotMutateDraftsOrBypassCapabilities() {
        val draft="""{"mailpilot_action":"create_draft","arguments":{"to":"a@example.test","subject":"subject","body":"body"}}"""
        assertEquals(1,calls(draft).length()); rejected("说明。$draft"); rejected(draft+"\n"+read)
        assertTrue(runCatching { AgentActions(JSONArray()).normalize(roleMessage("assistant","说明。$read"),false) }.exceptionOrNull() is ModelFailure)
        rejected(read.replace("read_web_page","smtp_send"))
    }
    @Test fun matchingNativeAndTextualRepresentationsExecuteOnce() {
        val native=registry.normalize(roleMessage("assistant",read),false).put("content","核对来源。$read")
        assertEquals(1,registry.normalize(native,true).getJSONArray("tool_calls").length())
        native.put("content",read.replace("T2:S1","T2:S9"))
        assertTrue(runCatching { registry.normalize(native,true) }.exceptionOrNull() is ModelFailure)
    }
}
