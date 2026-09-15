package app.mailpilot

import android.graphics.Bitmap
import android.view.accessibility.AccessibilityNodeInfo
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import app.mailpilot.ai.ReasoningSnapshot
import app.mailpilot.ai.ReasoningTrace
import app.mailpilot.ai.ModelOutputPolicy
import app.mailpilot.ai.ModelContextPolicy
import app.mailpilot.ai.ContextBudgetPlanner
import app.mailpilot.data.ModelProfile
import app.mailpilot.data.ChatEntry
import app.mailpilot.platform.MailCoordinator
import app.mailpilot.platform.MailState
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File

/** Synthetic platform-state events exercise the real EventChannel and Flutter UI.
 * No mailbox, provider credentials, model request or database fixture is needed. */
@RunWith(AndroidJUnit4::class)
class Stream29DeviceTest {
    private val instrumentation get() = InstrumentationRegistry.getInstrumentation()

    private fun contains(node: AccessibilityNodeInfo?, text: String): Boolean {
        if(node==null) return false
        if(node.text?.contains(text)==true || node.contentDescription?.contains(text)==true) return true
        return (0 until node.childCount).any { contains(node.getChild(it),text) }
    }
    private fun waitFor(text: String) {
        val end=System.nanoTime()+15_000_000_000L
        while(System.nanoTime()<end) {
            if(contains(instrumentation.uiAutomation.rootInActiveWindow,text)) return
            Thread.sleep(100)
        }
        fail("Flutter did not display synthetic stream text: $text")
    }
    private fun capture(name: String) {
        val image=instrumentation.uiAutomation.takeScreenshot()
        val file=File(instrumentation.targetContext.getExternalFilesDir(null),name)
        file.outputStream().use { image.compress(Bitmap.CompressFormat.PNG,100,it) }
        image.recycle()
    }
    @Test fun nativeFramesReachFlutterAndCompletionKeepsAllContent() {
        ActivityScenario.launch(MainActivity::class.java).use { scenario ->
            lateinit var coordinator: MailCoordinator
            lateinit var flow: MutableStateFlow<MailState>
            scenario.onActivity { activity ->
                coordinator=MainActivity::class.java.getDeclaredField("vm").apply { isAccessible=true }.get(activity) as MailCoordinator
                @Suppress("UNCHECKED_CAST")
                val state=MailCoordinator::class.java.getDeclaredField("_state").apply { isAccessible=true }.get(coordinator) as MutableStateFlow<MailState>
                flow=state
            }
            runBlocking { coordinator.graph.ready.await() }
            instrumentation.waitForIdleSync()
            Thread.sleep(1000)
            val before=flow.value
            assertFalse("Do not disturb an active user generation",before.analyzing || before.busy)
            val question=ChatEntry(id="stream29-q",conversationId=before.conversationId,role="user",text="请核对这些演示资料")
            val base=before.copy(tab=1,detail=null,source=null,editor=null,sendPreview=null,pdfChoice=null,entries=listOf(question),analyzing=true,responseId="stream29-r",streaming="",reasoning=ReasoningSnapshot())
            scenario.onActivity { flow.value=base }
            waitFor("请核对这些演示资料")
            var thoughts=""
            val trace=ReasoningTrace(attemptId="device33"); trace.begin("request1","answer")
            try {
                repeat(24) { n ->
                    if(n==12) { trace.finish(); scenario.onActivity { flow.value=base.copy(reasoning=trace.snapshot(),status="正在检索相关网页") }; Thread.sleep(100); trace.begin("request2","answer") }
                    trace.append("第 ${n+1} 项：核对演示资料中的时间、数量与来源。\n")
                    thoughts=trace.snapshot().text
                    scenario.onActivity { flow.value=base.copy(reasoning=trace.snapshot()) }
                    Thread.sleep(60)
                }
                waitFor("第 24 项")
                Thread.sleep(250) // Capture after the smooth follower reaches the visible tail.
                capture("stream29-thinking.png")
                trace.finish()
                var answer=""
                val parts=listOf("核对完成。", "时间和数量", "均已保留，", "来源仍可查看。")
                parts.forEach { part ->
                    answer+=part
                    val current=answer
                    scenario.onActivity { flow.value=base.copy(streaming=current,reasoning=trace.snapshot()) }
                    Thread.sleep(100)
                }
                waitFor(answer)
                // This suffix appears only in the final full state, so matching the
                // earlier streaming answer cannot make the completion check pass.
                val completedAnswer=answer+"\n\n本轮已完整接收。"
                val entry=ChatEntry(id="stream29-r",conversationId=before.conversationId,role="assistant",text=completedAnswer,reasoningText=thoughts,reasoningState="completed",reasoningMillis=1440)
                scenario.onActivity { flow.value=base.copy(analyzing=false,responseId="",entries=listOf(question,entry),reasoning=ReasoningSnapshot()) }
                waitFor("本轮已完整接收。")
                Thread.sleep(250) // Accessibility can precede the rendered frame.
                capture("stream29-completed.png")
                assertEquals(completedAnswer,flow.value.entries.last().text)
            } finally { scenario.onActivity { flow.value=before } }
        }
    }
    @Test fun modelSavePersistsAutomaticMaximumForAllVerifiedProvidersAndCustomOverride()=runBlocking {
        ActivityScenario.launch(MainActivity::class.java).use { scenario ->
            lateinit var coordinator: MailCoordinator
            scenario.onActivity { activity -> coordinator=MainActivity::class.java.getDeclaredField("vm").apply { isAccessible=true }.get(activity) as MailCoordinator }
            val graph=coordinator.graph
            graph.ready.await()
            val settings=graph.preferences.flow.first()
            val originalModels=graph.dao.models().first().map { it.id }.toSet()
            val originalAccounts=graph.dao.allAccounts().map { it.id }.toSet()
            val fixtures=listOf(
                ModelProfile(label="自动输出验证",provider="deepseek",baseUrl="https://api.deepseek.com/v1",model="deepseek-v4-flash-vision-exp"),
                ModelProfile(label="自动输出验证",provider="aliyun",baseUrl="https://dashscope.aliyuncs.com/compatible-mode/v1",model="qwen3.8-max"),
                ModelProfile(label="自动输出验证",provider="volcengine",baseUrl="https://ark.cn-beijing.volces.com/api/v3",model="doubao-seed-evolving")
            )
            val expected=listOf(384000,131072,262144)
            try {
                fixtures.forEachIndexed { index,p ->
                    coordinator.saveModel(p,"","auto","auto")
                    val persisted=graph.dao.model(p.id)!!
                    assertEquals(0,persisted.outputTokens)
                    assertEquals("auto",graph.preferences.flow.first().outputModes[p.id])
                    val actual=ModelContextPolicy.resolve(persisted,"auto")
                    ContextBudgetPlanner.validate(actual)
                    assertEquals(expected[index],ModelOutputPolicy.maximum(actual))
                }
                coordinator.saveModel(fixtures.first().copy(outputTokens=4096),"","auto","custom")
                val custom=graph.dao.model(fixtures.first().id)!!
                assertEquals(4096,ModelOutputPolicy.resolve(custom,graph.preferences.flow.first().outputModes[custom.id]).outputTokens)
            } finally {
                fixtures.forEach { graph.dao.deleteModel(it.id); graph.preferences.contextMode(it.id,null); graph.preferences.outputMode(it.id,null) }
                graph.preferences.set("textModel",settings.textModelId)
            }
            assertEquals(originalModels,graph.dao.models().first().map { it.id }.toSet())
            assertEquals(originalAccounts,graph.dao.allAccounts().map { it.id }.toSet())
        }
    }
}
