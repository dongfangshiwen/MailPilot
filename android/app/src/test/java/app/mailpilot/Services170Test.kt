package app.mailpilot

import android.app.Application
import app.mailpilot.data.*
import app.mailpilot.services.*
import app.mailpilot.mail.*
import kotlinx.coroutines.*
import okhttp3.mockwebserver.*
import org.json.JSONObject
import org.junit.*
import org.junit.Assert.*
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import java.io.File

@RunWith(RobolectricTestRunner::class)
@Config(sdk=[28],application=Application::class)
class Services170Test {
    private val secrets=PlainTestSecrets()
    @Test fun bothSearchProvidersUseTheirOfficialWireFormats()=runBlocking {
        MockWebServer().use { server ->
            server.start()
            val client=DirectWebSearchClient(secrets,JsonHttp(allowHttpForTests=true))
            for(provider in listOf("volcengine","bocha")) {
                val json=if(provider=="volcengine") """{"Result":{"WebResults":[{"Title":"官方资料","Url":"https://example.test/page","Content":"实际返回内容"}]}}"""
                    else """{"code":200,"data":{"webPages":{"value":[{"name":"官方资料","url":"https://example.test/page","summary":"实际返回内容"}]}}}"""
                server.enqueue(MockResponse().setBody(json))
                val result=client.search(ServiceConfig(provider=provider,baseUrl=server.url("/").toString(),keyCipher="fixture-secret"),"搜索对象")
                val request=server.takeRequest(); val body=JSONObject(request.body.readUtf8())
                assertEquals("Bearer fixture-secret",request.getHeader("Authorization"))
                assertEquals(5,body.getInt(if(provider=="volcengine") "Count" else "count"))
                assertEquals("搜索对象",body.getString(if(provider=="volcengine") "Query" else "query"))
                if(provider=="volcengine") { assertTrue(body.getJSONObject("Filter").getBoolean("NeedContent")); assertEquals("text",body.getString("ContentFormats")) }
                assertEquals("实际返回内容",result.single().text); assertEquals("web",result.single().kind)
            }
        }
    }
    @Test fun searchErrorsAreExplicitAndCancelledCallsDoNotRetry()=runBlocking {
        MockWebServer().use { server ->
            server.start(); val client=DirectWebSearchClient(secrets,JsonHttp(allowHttpForTests=true))
            val config=ServiceConfig(baseUrl=server.url("/").toString(),keyCipher="fixture")
            for(code in listOf(401,429)) { server.enqueue(MockResponse().setResponseCode(code)); assertNotNull(runCatching { client.search(config,"query") }.exceptionOrNull()) }
            server.enqueue(MockResponse().setSocketPolicy(SocketPolicy.NO_RESPONSE))
            assertTrue(runCatching { withTimeout(300) { client.search(config,"query") } }.exceptionOrNull() is TimeoutCancellationException)
            assertEquals(3,server.requestCount)
        }
    }
    @Test fun sourcesRoundTripAndDuplicatesKeepOnlyEightSafeLinks() {
        val values=(1..10).map { SourceChunk(messageId="",title="Page $it",location="web",url="https://example.test/$it",kind="web") }
        assertEquals(8,DirectWebSearchClient.deduplicate(values+values).size)
        assertEquals(values,JsonCodec.sources(JsonCodec.sources(values)))
        assertThrows(IllegalArgumentException::class.java) { DirectWebSearchClient.parse("volcengine",JSONObject("""{"ResponseMetadata":{"Error":{"Code":"AuthFailed"}}}""")) }
    }
    @Test fun qwenReceivesInlineAudioAndLanguageWithoutChatOrToolInstructions()=runBlocking {
        MockWebServer().use { server ->
            server.start(); server.enqueue(MockResponse().setBody("""{"choices":[{"message":{"content":"确认发送 hello"}}]}"""))
            val wav=File.createTempFile("asr",".wav").apply { writeBytes(AndroidSpeechInput.wavHeader(32000)+ByteArray(32000)) }
            try {
                val client=QwenAsrClient(secrets,JsonHttp(allowHttpForTests=true))
                val result=client.transcribe(ServiceConfig(baseUrl=server.url("/v1").toString(),keyCipher="fixture",language="zh"),wav)
                assertEquals("确认发送 hello",result)
                val request=server.takeRequest(); assertEquals("/v1/chat/completions",request.path)
                val body=JSONObject(request.body.readUtf8()); assertEquals("zh",body.getJSONObject("asr_options").getString("language"))
                assertFalse(body.has("tools")); assertEquals(1,body.getJSONArray("messages").length())
                assertTrue(body.getJSONArray("messages").getJSONObject(0).getJSONArray("content").getJSONObject(0).getJSONObject("input_audio").getString("data").startsWith("data:audio/wav;base64,")); assertFalse(body.toString().contains("确认发送"))
            } finally { wav.delete() }
        }
    }
    @Test fun reviewExplainsMissingRecipientAndInvalidatesOldRevision() {
        val d=Draft(id="d",accountId="a",body="正文")
        assertEquals("recipient",DraftReviewState.content(d).action)
        assertEquals("invalid_address",DraftReviewState.content(d.copy(to="bad")).code)
        assertTrue(DraftReviewState.content(d.copy(to="target@example.test")).canSend)
        for(status in listOf("UNKNOWN","SENDING","SENT")) assertFalse(DraftReviewState.content(d.copy(status=status)).canSend)
        val entry=ChatEntry(id="e",conversationId="c",role="assistant",text="",draftId=d.id,draftPreviewJson="""{"revision":0,"senderEmail":"sender@example.test"}""")
        val account=MailAccount(id="a",email="sender@example.test")
        assertEquals("outdated",DraftReviewState.forEntry(entry,"e",listOf(d.copy(revision=1)),listOf(account)).code)
        assertEquals("deleted",DraftReviewState.forEntry(entry,"e",emptyList(),listOf(account)).code)
    }
    @Test fun generatedTextRemovesFormattingCitationsAndUnknownSignature() {
        val body=MailBody.generated("# 主题\n\n**你好** [T12:S3]\n\n| 项目 | 金额 |\n|---|---|\n| A | 12 |\n\n[您的姓名/团队]")
        assertFalse(body.contains("**")); assertFalse(body.contains("T12:S3")); assertFalse(body.contains("[您的")); assertTrue(body.contains("12"))
        val model=ModelProfile(thinkingMode="enabled",thinkingBudget=2000)
        assertEquals("disabled",ChatRequestOptions("disabled").apply(model).thinkingMode)
        assertEquals("enabled",model.thinkingMode)
    }
}
