package app.mailpilot

import app.mailpilot.ai.*
import app.mailpilot.data.*
import app.mailpilot.services.*
import android.app.Application
import java.net.InetAddress
import org.json.*
import org.junit.*
import org.junit.Assert.*
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk=[28],application=Application::class)
class Research34Test {
    @Test fun rangeUnionAndContentVersionsMeasureOnlyNewEvidence() {
        val p=ResearchProgress(JSONObject()); val s=SourceChunk(id="s",messageId="",title="T",location="",text="x".repeat(100))
        p.source(s); val n=p.count; p.source(s); assertEquals(n,p.count)
        p.read(s,0,20); p.read(s,10,30); val after=p.count
        p.read(s,0,30); p.read(s,100,100); assertEquals(after,p.count)
        p.read(s,30,50); assertEquals(after+1,p.count)
        p.source(s.copy(text="different")); assertEquals(after+2,p.count)
        repeat(2) { p.finishRound(p.count) }; assertTrue(p.finishing)
        p.resume(); assertFalse(p.finishing); assertEquals(after+2,p.count)
    }
    @Test fun sevenGatherRoundsReserveFinalAnswer() {
        val p=ResearchProgress(JSONObject())
        repeat(7) { val n=p.count; p.source(SourceChunk(id="s$it",messageId="",title="",location="",text="new $it")); p.finishRound(n) }
        assertTrue(p.finishing); assertEquals(7,p.rounds)
    }
    @Test fun activitiesHaveStableOrderAndIgnoreLateDuplicateEvents() {
        val t=ReasoningTrace(); t.begin("req1","answer"); t.append("先思考"); t.finish()
        t.activity(AgentEvent.ToolActivity("search1","web_search","running"))
        t.activity(AgentEvent.ToolActivity("search1","web_search","completed",2,listOf("example.org"),2))
        val revision=t.snapshot().revision
        t.activity(AgentEvent.ToolActivity("search1","web_search","running")); assertEquals(revision,t.snapshot().revision)
        t.begin("req2","answer"); t.append("根据结果回答"); t.end()
        val s=ReasoningSnapshot.from(JSONObject(t.snapshot().fields()))
        assertEquals(1,s.activities.size); val order=(s.activities.single()["order"] as Number).toLong()
        assertTrue(s.segments[0].order<order && order<s.segments[1].order)
        assertEquals(2,s.activities.single()["count"])
    }
    @Test fun publicReaderBlocksSpecialAddressesIncludingMappedIpv4() {
        for(host in listOf("127.0.0.1","10.1.2.3","172.16.0.1","192.168.0.1","169.254.169.254","100.64.0.1","198.18.0.1","0.0.0.0","::1","fc00::1","fe80::1","::ffff:127.0.0.1","2001:db8::1","2002:7f00:1::"))
            assertFalse(host,PublicWebReader.publicAddress(InetAddress.getByName(host)))
        assertTrue(PublicWebReader.publicAddress(InetAddress.getByName("8.8.8.8")))
        assertTrue(PublicWebReader.publicAddress(InetAddress.getByName("2606:4700:4700::1111")))
        for(url in listOf("file:///a","https://user:pass@example.org","http://localhost","http://example.org:8080")) assertTrue(runCatching { PublicWebReader.endpoint(url) }.isFailure)
    }
    @Test fun webpageExtractionDistinguishesUnsupportedLoginAndDynamicPages() {
        assertEquals("unsupported_type",PublicWebReader.extract("%PDF","application/pdf").status)
        assertEquals("login_required",PublicWebReader.extract("<input type=password>","text/html").status)
        assertEquals("needs_render",PublicWebReader.extract("<script>content</script>","text/html").status)
        val result=PublicWebReader.extract("<nav>omit</nav><main>"+"事实内容。".repeat(20)+"<script>secret</script></main>","text/html")
        assertEquals("needs_render",result.status); assertFalse(result.text.contains("secret")); assertFalse(result.text.contains("omit"))
    }
}
