package app.mailpilot

import android.app.Application
import app.mailpilot.ai.*
import app.mailpilot.data.*
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.runBlocking
import okhttp3.*
import okhttp3.ResponseBody.Companion.toResponseBody
import okio.Buffer
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk=[28],application=Application::class)
class ModelOutput29Test {
    private fun profile(provider: String, model: String)=ModelProfile(provider=provider,model=model,baseUrl=when(provider) {
        "deepseek" -> "https://api.deepseek.com/v1"
        "aliyun" -> "https://dashscope.aliyuncs.com/compatible-mode/v1"
        else -> "https://ark.cn-beijing.volces.com/api/v3"
    })
    private fun auto(p: ModelProfile)=ModelOutputPolicy.resolve(ModelContextPolicy.resolve(p),"auto")
    @Test fun allCatalogModelsUseOwnMaximumWithoutReservingTheEntireOutputWindow() {
        val messages=JSONArray().put(roleMessage("user","你好"))
        ModelCapabilityResolver.catalog.forEach { entry ->
            val p=auto(profile(entry.provider,entry.name)).copy(thinkingMode="disabled")
            ContextBudgetPlanner.validate(p)
            val actual=ModelOutputPolicy.requestTokens(p,messages)
            assertEquals(minOf(entry.output,p.contextTokens-ContextBudgetPlanner.estimate(messages,profile=p)),actual)
            assertTrue(ContextBudgetPlanner.limits(p).input>4096)
        }
    }
    @Test fun legacyDefaultAndExplicitCustomAndUnverifiedEndpointsAreDistinct() {
        val p=profile("deepseek","deepseek-v4-flash-vision-exp")
        assertEquals(0,ModelOutputPolicy.resolve(p).outputTokens)
        assertEquals(4096,ModelOutputPolicy.resolve(p,"custom").outputTokens)
        assertEquals(8192,ModelOutputPolicy.resolve(p.copy(outputTokens=8192)).outputTokens)
        for(url in listOf("https://proxy.example/v1","https://api.deepseek.com.evil.test/v1","https://ark.cn-beijing.volces.com/api/plan/v3")) {
            val unknown=auto(p.copy(baseUrl=url))
            assertEquals(4096,ModelOutputPolicy.maximum(unknown))
            assertEquals(32768,unknown.contextTokens)
        }
        val saved=BridgeCodec.model(JSONObject().put("outputMode","auto").put("outputTokens",384000),p)
        assertEquals(0,saved.outputTokens)
        val visible=BridgeCodec.model(auto(p))
        assertEquals(384000,visible["outputTokens"])
        assertEquals("auto",visible["outputMode"])
    }
    @Test fun contextSpaceAdjustsAutomaticCapAndCustomStillValidates() {
        val p=auto(profile("deepseek","deepseek-v4-flash-vision-exp")).copy(contextTokens=32768)
        val messages=JSONArray().put(roleMessage("user","资料".repeat(1000)))
        val cap=ModelOutputPolicy.requestTokens(p,messages)
        assertEquals(p.contextTokens-ContextBudgetPlanner.estimate(messages,profile=p),cap)
        assertTrue(cap in 128..32768)
        val custom=auto(profile("deepseek","deepseek-v4-pro")).copy(outputTokens=384000)
        ContextBudgetPlanner.validate(custom)
        assertTrue(runCatching { ContextBudgetPlanner.validate(custom.copy(outputTokens=384001)) }.isFailure)
        assertTrue(runCatching { ContextBudgetPlanner.validate(custom.copy(contextTokens=32768)) }.isFailure)
    }
    @Test fun automaticHelperHasItsOwnCeilingAndKeepsEndpoint() {
        val main=auto(profile("aliyun","qwen3.8-max"))
        val helper=ModelCapabilityResolver.defaultHelper(main)!!
        assertEquals(main.baseUrl,helper.baseUrl)
        assertEquals(0,helper.outputTokens)
        assertEquals(32768,ModelOutputPolicy.maximum(helper))
        assertEquals(131072,ModelOutputPolicy.maximum(main))
    }
    @Test fun actualChatAndVisionWireRequestsCarryTheMaximumNotZeroOrOld4096()=runBlocking {
        val payloads=mutableListOf<JSONObject>()
        val http=OkHttpClient.Builder().addInterceptor { chain ->
            val buffer=Buffer(); chain.request().body!!.writeTo(buffer)
            payloads+=JSONObject(buffer.readUtf8())
            Response.Builder().request(chain.request()).protocol(Protocol.HTTP_1_1).code(200).message("OK")
                .body("""{"choices":[{"message":{"role":"assistant","content":"核对完成"},"finish_reason":"stop"}]}""".toResponseBody()).build()
        }.build()
        val client=CompatibleModelClient(PlainTestSecrets(),http)
        val p=auto(profile("deepseek","deepseek-v4-flash-vision-exp"))
        for(stage in listOf("chat","vision","draft")) {
            client.generateRequest(p,JSONArray().put(roleMessage("user","核对演示资料")),forceStream=false,options=ModelRequestOptions(stage=stage)).toList()
        }
        assertEquals(listOf(384000,384000,384000),payloads.map { it.getInt("max_tokens") })
    }
}
