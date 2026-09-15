package app.mailpilot

import android.app.Application
import app.mailpilot.ai.*
import app.mailpilot.data.*
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import java.io.File

@RunWith(RobolectricTestRunner::class)
@Config(sdk=[28],application=Application::class)
class Vision180Test {
    private val volc=ModelProfile(baseUrl="https://ark.cn-beijing.volces.com/api/v3",model="doubao-seed-evolving",apiKeyCipher="fixture",credentialVersion="key-version")
    @Test fun catalogIsGenericAndIndependentOfLegacyFailures() {
        for(entry in ModelCapabilityResolver.catalog) {
            val p=volc.copy(provider=entry.provider,model=entry.name,supportsVision=false)
            assertEquals(if(entry.vision) "supported" else "unsupported",ModelCapabilityResolver.vision(p))
            assertFalse(ModelCapabilityResolver.diagnosticCurrent(p))
        }
        assertEquals("unknown",ModelCapabilityResolver.vision(volc.copy(model="custom-vl")))
        assertEquals("unsupported",ModelCapabilityResolver.vision(volc.copy(provider="deepseek",model="deepseek-v4-flash")))
        val diagnostic=volc.copy(diagnosticIdentity=ModelCapabilityResolver.identity(volc),supportsVision=true)
        assertTrue(ModelCapabilityResolver.diagnosticCurrent(diagnostic.copy(label="renamed",thinkingMode="enabled",reasoningEffort="high")))
        assertFalse(ModelCapabilityResolver.diagnosticCurrent(diagnostic.copy(credentialVersion="new-key")))
        assertFalse(ModelCapabilityResolver.diagnosticCurrent(diagnostic.copy(model="different")))
        assertFalse(ModelCapabilityResolver.diagnosticCurrent(diagnostic.copy(baseUrl="https://other.invalid/v1")))
    }
    @Test fun autoRouteNeverRewritesEndpointOrTransfersKeyAcrossRegionOrProduct() {
        val automatic=VisionRouter.candidates(volc,null,emptyList())
        assertEquals("doubao-seed-evolving",automatic.first().model)
        assertEquals("doubao-seed-2-0-lite-260428",automatic.last().model)
        assertTrue(automatic.all { it.baseUrl==volc.baseUrl && it.apiKeyCipher==volc.apiKeyCipher })
        for(url in listOf("https://unknown.proxy/v1","https://ark.cn-beijing.volces.com/api/coding/v3","https://ark.cn-beijing.volces.com.evil.test/api/v3","http://ark.cn-beijing.volces.com/api/v3","https://ark.cn-beijing.volces.com/api/v3?key=other")) assertNull(ModelCapabilityResolver.defaultHelper(volc.copy(baseUrl=url)))
        val ali=volc.copy(baseUrl="https://dashscope-intl.aliyuncs.com/compatible-mode/v1",model="text")
        assertEquals(ali.baseUrl,ModelCapabilityResolver.defaultHelper(ali)!!.baseUrl)
        assertEquals("qwen3-vl-flash",ModelCapabilityResolver.defaultHelper(ali)!!.model)
        val fixed=ali.copy(id="helper",thinkingMode="enabled",thinkingBudget=200)
        val routes=VisionRouter.candidates(volc,fixed,listOf(ali))
        assertEquals("helper",routes.first().id); assertEquals("default",routes.first().thinkingMode); assertEquals(0,routes.first().thinkingBudget)
    }
    @Test fun errorsOnlyClassifyExplicitImageUnsupportedAndActualThinkingRejections() {
        for(status in listOf(401,403,429,500)) assertNotEquals("image_unsupported",FailureInfo.http(status,"""{"error":{"message":"image not supported"}}""").type)
        assertEquals("image_unsupported",FailureInfo.http(400,"""{"error":{"message":"This model does not support image"}}""").type)
        assertEquals("request",FailureInfo.http(400,"""{"error":{"message":"Invalid image URL"}}""").type)
        assertEquals("thinking_default",FailureInfo.http(400,"""{"error":{"message":"reasoning_effort unsupported"}}""").action)
        assertNotEquals("thinking_default",FailureInfo.from(IllegalStateException("视觉缺失")).action)
        assertEquals("read_timeout",FailureInfo.from(java.net.SocketTimeoutException()).type)
    }
    @Test fun diagnosticFailuresDoNotDisableKnownVisionAndSaveDoesNotInvalidateIt()=runBlocking {
        val server=MockWebServer(); server.start()
        try {
            repeat(4) { server.enqueue(MockResponse().setResponseCode(401).setBody("""{"error":{"message":"private key fixture"}}""")) }
            val p=volc.copy(baseUrl=server.url("/api/v3").toString(),provider="volcengine")
            val checked=CompatibleModelClient(PlainTestSecrets(),allowHttpForTests=true).test(p)
            assertEquals(4,server.requestCount); assertFalse(checked.supportsVision)
            assertEquals("supported",ModelCapabilityResolver.vision(checked))
            assertTrue(ModelCapabilityResolver.diagnosticCurrent(checked))
            val json=JSONObject(BridgeCodec.model(checked)).put("thinkingMode","enabled").put("reasoningEffort","high").put("secret","fixture")
            val saved=BridgeCodec.model(json,checked)
            assertTrue(ModelCapabilityResolver.diagnosticCurrent(saved))
            assertFalse(saved.testReport.contains("private key fixture"))
            assertEquals("permission",JSONObject(saved.diagnosticsJson).getJSONObject("图片").getString("type"))
        } finally { server.shutdown() }
    }
    private class FakeClient(val replies: MutableList<Any>): ModelClient {
        val requests=mutableListOf<Pair<ModelProfile,JSONArray>>()
        override fun generate(profile: ModelProfile,messages: JSONArray,tools: JSONArray?,forceStream: Boolean?)=flow<ModelEvent> {
            requests+=profile to messages
            when(val next=replies.removeAt(0)) { is Throwable -> throw next; else -> emit(ModelEvent.Completed(roleMessage("assistant",next.toString()))) }
        }
        override suspend fun test(profile: ModelProfile)=profile
    }
    @Test fun batchRecoveryRetriesOnlyMissingImagesAndBindsTheirSources()=runBlocking {
        val file=File.createTempFile("vision180",".png"); file.writeBytes(byteArrayOf(0x89.toByte(),0x50,0x4e,0x47))
        try {
            val a=SourceChunk("T4:S1","",title="selected-one",location="PDF 第 1 页",imagePath=file.path)
            val b=a.copy(id="T4:S2",title="selected-two",location="PDF 第 2 页")
            val client=FakeClient(mutableListOf("""{"results":[{"id":"T4:S1","text":"可见表格：金额 12"},{"id":"foreign","text":"不接受"}]}""","第 2 页有曲线，不确定具体数值"))
            val (observations,route)=VisionReader(client).read(listOf(a,b),"解释内容",listOf(volc),{})
            assertEquals(setOf(a.id,b.id),observations.keys); assertEquals(volc.model,route)
            assertEquals(2,client.requests.size)
            val second=client.requests[1].second.toString()
            assertTrue(second.contains("T4:S2")); assertFalse(second.contains("T4:S1"))
            val encoded=okio.Buffer(); ModelJsonBody(JSONObject().put("messages",client.requests[1].second)).writeTo(encoded)
            val content=JSONObject(encoded.readUtf8()).getJSONArray("messages").getJSONObject(1).getJSONArray("content")
            assertTrue(content.getJSONObject(2).getJSONObject("image_url").getString("url").startsWith("data:image/png;base64,")); assertFalse(second.contains("foreign"))
        } finally { file.delete() }
    }
    @Test fun explicitUnsupportedFallsBackButPermissionAndCancellationNeverDo()=runBlocking {
        val file=File.createTempFile("vision180",".jpg"); file.writeBytes(byteArrayOf(1,2,3))
        try {
            val images=listOf(SourceChunk("T1:S1","",title="图",location="图",imagePath=file.path))
            val candidates=VisionRouter.candidates(volc,null,emptyList())
            val success=FakeClient(mutableListOf(ModelFailure(FailureInfo("image_unsupported","unsupported")),"实际观察"))
            assertEquals(candidates.last().model,VisionReader(success).read(images,"问题",candidates,{}).second)
            for(error in listOf(ModelFailure(FailureInfo("permission","无权限")),CancellationException("stop"))) {
                val failed=FakeClient(mutableListOf(error,"must never call"))
                assertNotNull(runCatching { VisionReader(failed).read(images,"问题",candidates,{}) }.exceptionOrNull())
                assertEquals(1,failed.requests.size)
            }
        } finally { file.delete() }
    }
}
