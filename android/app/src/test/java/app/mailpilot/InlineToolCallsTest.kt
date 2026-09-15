package app.mailpilot

import android.app.Application
import app.mailpilot.ai.*
import app.mailpilot.data.ChatEntry
import org.json.*
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk=[28],application=Application::class)
class InlineToolCallsTest {
    private val actions=AgentActions.forCapabilities(true,true,true)
    private val prefix="我来联网检索采购方的公司背景，以及塑料酒吧收纳盒的公开产品信息。"
    private val call="""seed:tool_call<function name="web_search"><parameter name="queries" string="false">["Makito makito.es promotional products company Spain", "plastic bar caddy PS promotional napkin holder compartments"]</parameter></function></seed:tool_call>"""
    private fun normalized(text: String,native: Boolean=false)=actions.normalize(roleMessage("assistant",text),native)
    private fun rejected(text: String,registry: AgentActions=actions) {
        val error=runCatching { registry.normalize(roleMessage("assistant",text),false) }.exceptionOrNull()
        assertTrue("Expected typed failure, got $error",error is ModelFailure)
        assertEquals("action_format",(error as ModelFailure).info.type)
    }

    @Test fun terminalEnvelopeBecomesValidatedSearchInBothModes() {
        for(native in listOf(false,true)) {
            val result=normalized(prefix+call,native)
            assertEquals("",result.getString("content"))
            val calls=result.getJSONArray("tool_calls")
            assertEquals(1,calls.length())
            val f=calls.getJSONObject(0).getJSONObject("function")
            assertEquals("web_search",f.getString("name"))
            assertEquals(2,JSONObject(f.getString("arguments")).getJSONArray("queries").length())
            assertEquals(calls.toString(),normalized(prefix+call,native).getJSONArray("tool_calls").toString())
        }
    }
    @Test fun everyStreamSplitHoldsControlSyntaxWithoutRetractingProse() {
        for(opener in listOf("seed:tool_call","seed:tool_call>","<seed:tool_call>")) {
            val wire=prefix+call.replaceFirst("seed:tool_call",opener)
            var prior=""
            for(i in 1..wire.length) {
                val visible=actions.visible(wire.take(i))
                assertTrue(visible.startsWith(prior)); assertTrue(prefix.startsWith(visible))
                prior=visible
            }
            assertEquals(prefix,prior)
        }
    }
    @Test fun markdownEscapedControlTokensDoNotLeakOrAlterArguments() {
        val escaped=call.replace("_","\\_").replace("<","\\<").replace(">","\\>")
        val expected=normalized(call).getJSONArray("tool_calls").getJSONObject(0).getJSONObject("function")
        val actual=normalized(escaped).getJSONArray("tool_calls").getJSONObject(0).getJSONObject("function")
        assertTrue(InlineToolCalls.sameValue(expected,actual))
        for(i in 1..escaped.length) assertEquals(prefix,actions.visible(prefix+escaped.take(i)))
        assertFalse(DraftPresentation.readable(prefix+escaped).contains("seed:"))
    }
    @Test fun incompleteMalformedAndOverLimitCallsNeverBecomeAnswers() {
        for(text in listOf(call.removeSuffix("</seed:tool_call>"),"<seed:tool_ca",call+"多余正文",
            call.replace("string=\"false\"","string=\"maybe\""),
            call.replace("</function>","<parameter name=\"queries\">重复参数</parameter></function>"),
            call.replace("[\"Makito", "[\"Makito".repeat(5000)),
            call.replace("<function", "<!DOCTYPE x SYSTEM \"file:///private\"><function"),
            call.replace("[\"Makito", "[\"&secret;Makito"),
            call.replace("[\"Makito", "[".repeat(1000)+"\"Makito"),call.repeat(5))) rejected(text)
    }
    @Test fun schemaAndCapabilitiesRemainAuthoritative() {
        rejected(call,AgentActions.forCapabilities(false,false,false))
        rejected(call.replace("web_search","smtp_send"))
        rejected(call.replace("web_search","create_draft"))
        rejected(call.replace("name=\"queries\"","name=\"query\""))
        rejected(call.replace("string=\"false\"","string=\"true\""))
        rejected(call.replace("queries\" string", "queries\" unexpected=\"yes\" string"))
    }
    @Test fun codeExamplesAndOrdinaryWordsAreNotExecuted() {
        for(text in listOf("示例：`$call`", "```xml\n$call\n```", "~~~xml\n$call\n~~~", "> $call", "seeds", "文件名 myseed:tool_call.txt",
            JSONObject().put("example",call).toString())) {
            assertEquals(text,normalized(text).getString("content"))
            assertEquals(text,DraftPresentation.readable(text))
        }
        val draft=roleMessage("assistant",JSONObject().put("mailpilot_action","create_draft").put("arguments",JSONObject().put("to","me@example.test").put("subject","协议示例").put("body",call)).toString())
        assertEquals("create_draft",actions.normalize(draft,false).getJSONArray("tool_calls").getJSONObject(0).getJSONObject("function").getString("name"))
    }
    @Test fun standardAndInlineDuplicateIsExecutedOnlyOnceButConflictsFail() {
        val standard=normalized(call,true).put("content",prefix+call)
        assertEquals(1,actions.normalize(standard,true).getJSONArray("tool_calls").length())
        standard.getJSONArray("tool_calls").getJSONObject(0).getJSONObject("function").put("arguments","{\"queries\":[\"different\"]}")
        assertTrue(runCatching { actions.normalize(standard,true) }.exceptionOrNull() is ModelFailure)
        val wrongType=normalized(call,true)
        wrongType.getJSONArray("tool_calls").getJSONObject(0).put("type","custom")
        assertTrue(runCatching { actions.normalize(wrongType,true) }.exceptionOrNull() is ModelFailure)
    }
    @Test fun multipleEnvelopesAndTypedParametersAreSupported() {
        val read="""<seed:tool_call><function name='read_evidence'><parameter name='source_id'>T1:S1</parameter><parameter name='start' string='false'>0</parameter><parameter name='max_chars' string='false'>300</parameter></function></seed:tool_call>"""
        assertEquals(2,normalized(call+"\n"+read).getJSONArray("tool_calls").length())
        val feedback=actions.feedback(normalized(call+read),JSONArray().put(roleMessage("tool","第一项结果")).put(roleMessage("tool","第二项结果")),false)
        assertTrue(feedback.all { it.getString("role")!="tool" })
        assertFalse(feedback.toString().contains("seed:tool_call"))
    }
    @Test fun oldStoredLeakIsReadableButNeverTreatedAsCompletedSearch() {
        val readable=DraftPresentation.readable(prefix+call)
        assertTrue(readable.startsWith(prefix)); assertTrue(readable.contains("不能据此确认已完成检索"))
        assertFalse(readable.contains("seed:tool_call")); assertFalse(readable.contains("<parameter"))
        assertEquals(call,DraftPresentation.reference(ChatEntry(conversationId="c",role="user",text=call)))
    }
}
