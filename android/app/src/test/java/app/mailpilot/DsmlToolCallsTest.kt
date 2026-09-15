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
class DsmlToolCallsTest {
    private val actions=AgentActions.forCapabilities(true,true,true)
    private fun wire(marker: String="｜DSML｜",container: String="tool_calls",space: String="") =
        """<$marker$space$container><$marker${space}invoke name="web_search"><$marker${space}parameter name="queries" string="false">["public product specifications","public manufacturer documentation"]</$marker${space}parameter></$marker${space}invoke></$marker$space$container>"""
    private fun normalize(text: String,native: Boolean=false)=actions.normalize(roleMessage("assistant",text),native)
    private fun rejected(text: String,registry: AgentActions=actions) {
        val failure=runCatching { registry.normalize(roleMessage("assistant",text),false) }.exceptionOrNull()
        assertTrue("Expected typed failure: $failure",failure is ModelFailure)
        assertEquals("action_format",(failure as ModelFailure).info.type)
    }

    @Test fun canonicalLegacyAndObservedDialectsUseOneRegistry() {
        for(marker in listOf("｜DSML｜","｜｜DSML｜｜","|DSML|","||DSML||"))
            for(container in listOf("tool_calls","function_calls","calls"))
                for(space in listOf(""," ","\u00a0")) for(native in listOf(false,true)) {
                    val text=wire(marker,container,space)
                    val result=normalize("先核对公开资料。"+text,native)
                    val calls=result.getJSONArray("tool_calls")
                    assertEquals("",result.getString("content")); assertEquals(1,calls.length())
                    val function=calls.getJSONObject(0).getJSONObject("function")
                    assertEquals("web_search",function.getString("name"))
                    assertEquals(2,JSONObject(function.getString("arguments")).getJSONArray("queries").length())
                    assertEquals(calls.toString(),normalize("先核对公开资料。"+text,native).getJSONArray("tool_calls").toString())
                }
    }

    @Test fun everyFragmentOfEscapedAndUnicodeFramesIsHiddenWithoutRetraction() {
        for(text in listOf(wire(),wire("｜｜DSML｜｜","calls","\u00a0"),wire("|DSML|","function_calls"))) {
            val escaped=text.replace("web_search","web\\_search").replace("<","\\<").replace(">","\\>")
            for(raw in listOf(text,escaped)) {
                val prefix="正在核对。"; var previous=""
                for(i in 1..(prefix+raw).length) {
                    val visible=actions.visible((prefix+raw).take(i))
                    assertTrue(visible.startsWith(previous)); assertTrue(prefix.startsWith(visible)); previous=visible
                }
                assertEquals(prefix,previous); assertEquals(1,normalize(raw).getJSONArray("tool_calls").length())
                assertFalse(DraftPresentation.readable(prefix+raw).contains("DSML"))
            }
        }
    }

    @Test fun allIncompleteSuffixesFailClosedWithoutPartialExecution() {
        val raw=wire()
        for(i in raw.indexOf("DSML")+4 until raw.length) rejected(raw.take(i))
        for(rawBad in listOf(wire().replace("tool_calls","unknown_calls"),wire()+"extra prose",wire().repeat(5),
            wire().replace("string=\"false\"","string=\"maybe\""),
            wire().replace("name=\"queries\"","name=\"queries\" name=\"query\""),
            wire().replace("</｜DSML｜invoke>","</｜｜DSML｜｜invoke>"),
            wire().replace("[\"public product specifications\",\"public manufacturer documentation\"]","[\"ok\",]"),
            wire().replace("[\"public product specifications\",\"public manufacturer documentation\"]","{\"x\":1,\"x\":2}"),
            wire().replace("[\"public product specifications\",\"public manufacturer documentation\"]","null null"),
            wire().replace("public product specifications","&secret;"),
            wire().replace("public product specifications","x".repeat(128_000)))) rejected(rawBad)
    }

    @Test fun argumentEscapesAndUnicodeAreNotRewritten() {
        val query="资料 A_B \\_ path C:\\docs \"quote\""
        val raw=wire().replace("[\"public product specifications\",\"public manufacturer documentation\"]",JSONArray().put(query).toString())
            .replace("web_search","web\\_search")
        val function=normalize(raw).getJSONArray("tool_calls").getJSONObject(0).getJSONObject("function")
        assertEquals(query,JSONObject(function.getString("arguments")).getJSONArray("queries").getString(0))
    }

    @Test fun quotedExamplesRemainDisplayOnlyAndOldLeaksCannotClaimSearch() {
        val raw=wire()
        for(example in listOf("`$raw`","```xml\n$raw\n```","> $raw",JSONObject().put("example",raw).toString())) {
            assertEquals(example,normalize(example).getString("content"))
            assertEquals(example,DraftPresentation.readable(example))
        }
        assertTrue(DraftPresentation.readable(raw).contains("不能据此确认已完成检索"))
        rejected(raw,AgentActions.forCapabilities(false,false,false))
        rejected(raw.replace("web_search","smtp_send")); rejected(raw.replace("web_search","create_draft"))
        rejected(raw.replace("name=\"queries\"","name=\"query\""))
    }

    @Test fun nativeDuplicateAndMultipleReadCallsKeepExactlyOnceSemantics() {
        val raw=wire(); val native=normalize(raw,true).put("content",raw)
        assertEquals(1,actions.normalize(native,true).getJSONArray("tool_calls").length())
        native.getJSONArray("tool_calls").getJSONObject(0).getJSONObject("function").put("arguments","{\"queries\":[\"conflict\"]}")
        assertTrue(runCatching { actions.normalize(native,true) }.exceptionOrNull() is ModelFailure)
        val read="""<｜DSML｜invoke name="read_evidence"><｜DSML｜parameter name="source_id">S1</｜DSML｜parameter><｜DSML｜parameter name="start" string="false">0</｜DSML｜parameter><｜DSML｜parameter name="max_chars" string="false">300</｜DSML｜parameter></｜DSML｜invoke>"""
        val batch=raw.replace("</｜DSML｜tool_calls>",read+"</｜DSML｜tool_calls>")
        val result=normalize(batch); assertEquals(2,result.getJSONArray("tool_calls").length())
        val feedback=actions.feedback(result,JSONArray().put(roleMessage("tool","result1")).put(roleMessage("tool","result2")),false)
        assertFalse(feedback.toString().contains("DSML")); assertTrue(feedback.toString().contains("read_evidence"))
        rejected(batch.replace("name=\"start\"","name=\"bad_field\""))
    }
}
