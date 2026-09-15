package app.mailpilot

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.lifecycle.*
import app.mailpilot.data.*
import app.mailpilot.platform.MailCoordinator
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.first
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class Chat102DeviceTest {
    @Test fun editFreezesOriginalTurnPreservesAuditAndNeverTreatsEditedTextAsSend(): Unit=runBlocking {
        val app=InstrumentationRegistry.getInstrumentation().targetContext.applicationContext as MailPilotApp
        val g=app.graph; g.ready.await(); val prefs=g.preferences.flow.first()
        val account=MailAccount(email="chat102@example.test",imapHost="unused.invalid",smtpHost="unused.invalid")
        // Deliberately invalid scheme rejects locally, without a model or mail request.
        val model=ModelProfile(label="local validation fixture",baseUrl="http://127.0.0.1",model="fixture",apiKeyCipher=g.secrets.encrypt("fixture"))
        val store=ViewModelStore(); lateinit var vm: MailCoordinator
        val chat=Conversation(accountId=account.id,contextSummary="旧回答中的过时结论",summaryThroughId="old-answer",summarizedEntries=2)
        val first=newId(); val other=newId(); val user=ChatEntry(conversationId=chat.id,role="user",text="原始问题",createdAt=System.currentTimeMillis()-1000)
        val answer=ChatEntry(id="old-answer",conversationId=chat.id,role="assistant",text="旧回答",createdAt=user.createdAt+1)
        try {
            g.dao.putAccount(account); g.dao.putModel(model); g.preferences.set("account",account.id); g.preferences.set("textModel",model.id)
            g.dao.putMessages(listOf(first,other).mapIndexed { i,id -> MailMessage(id,account.id,"INBOX",1,i+1L,"本地测试$i","sender","sender@example.test",sentAt=0,body="资料$i",unread=false) })
            g.dao.putConversation(chat); g.dao.putEntry(user); g.dao.putEntry(answer)
            val oldSelection=JsonCodec.selections(listOf(Selection(first)))
            g.dao.putTurn(TurnSnapshot(answer.id,chat.id,account.id,"INBOX",oldSelection,1,requestJson=JSONObject().put("question",user.text).put("userEntryId",user.id).toString()))
            withContext(Dispatchers.Main) { vm=ViewModelProvider(store,ViewModelProvider.AndroidViewModelFactory.getInstance(app))[MailCoordinator::class.java] }
            withTimeout(10000) { vm.state.first { it.ready && it.activeAccount==account.id && it.models.any { m -> m.id==model.id } } }
            withContext(Dispatchers.Main) { vm.loadConversation(chat); vm.toggleMessage(other) }
            withTimeout(10000) { vm.state.first { it.entries.size==2 } }
            val prepared=withContext(Dispatchers.Main) { JSONObject(vm.prepareMessageEdit(user.id)) }
            assertEquals(user.text,prepared.getString("text")); assertEquals(2,g.dao.history(chat.id).size)
            withContext(Dispatchers.Main) { vm.editMessage(user.id,"确认发送",ChatRequestOptions()) }
            withTimeout(20000) { vm.state.first { !it.analyzing && it.entries.any { e -> e.action=="edit_user" } && it.entries.last().role=="assistant" } }
            val all=g.dao.history(chat.id); val active=ChatBranch.active(all)
            assertEquals(4,all.size); assertEquals(2,active.size); assertEquals("确认发送",active.first().text)
            assertEquals("failed",active.last().resultStatus)
            assertEquals(oldSelection,g.dao.turn(active.last().id)!!.selectionJson)
            assertEquals(2,g.dao.turn(active.last().id)!!.number)
            assertEquals(other,vm.state.value.selection.single().messageId)
            assertEquals("",g.dao.conversation(chat.id)!!.contextSummary)
            val versions=org.json.JSONArray(vm.messageVersions(active.first().id))
            assertEquals(2,versions.length())
            val original=versions.getJSONObject(0).getJSONArray("entries")
            assertEquals(user.text,original.getJSONObject(0).getString("text"))
            assertEquals(answer.text,original.getJSONObject(1).getString("text"))
            assertTrue(original.getJSONObject(1).getBoolean("historical"))
            assertFalse(original.getJSONObject(1).getJSONObject("review").getBoolean("canSend"))
            // Reopening reconstructs the new branch from persisted rows.
            withContext(Dispatchers.Main) { vm.loadConversation(g.dao.conversation(chat.id)!!) }
            withTimeout(10000) { vm.state.first { it.entries.firstOrNull()?.id==active.first().id } }
            assertEquals(2,vm.state.value.entryVersionCounts[active.first().id])
        } finally {
            withContext(Dispatchers.Main) { store.clear() }
            g.preferences.set("account",prefs.accountId); g.preferences.set("textModel",prefs.textModelId)
            g.dao.deleteAccountEntries(account.id); g.dao.deleteAccountConversations(account.id); g.dao.deleteMessages(account.id); g.dao.deleteAccount(account.id); g.dao.deleteModel(model.id)
        }
    }
}
