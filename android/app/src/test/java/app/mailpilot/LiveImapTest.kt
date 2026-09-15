package app.mailpilot

import android.app.Application
import androidx.room.Room
import app.mailpilot.data.*
import app.mailpilot.mail.MailRepositoryImpl
import kotlinx.coroutines.runBlocking
import org.junit.Assert.*
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config

/** Opt-in, read-only live verification. Credentials come from the process only.
 * No SMTP, flags, filesystem attachment downloads, or message-content output. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk=[28],application=Application::class)
class LiveImapTest {
    private fun safeDetail(message: String): String {
        var result=message
        for(key in listOf("MAILPILOT_LIVE_IMAP_USER","MAILPILOT_LIVE_IMAP_PASSWORD")) {
            System.getenv(key)?.takeIf { it.isNotBlank() }?.let { result=result.replace(it,"[redacted]") }
        }
        return result.take(1000)
    }
    private fun account(user: String) = MailAccount(
        email=user,
        imapHost=System.getenv("MAILPILOT_LIVE_IMAP_HOST").orEmpty().ifBlank { "imap.qq.com" }
    )
    @Test fun realAllFoldersFiftyAndWarmIncrementalReadOnly()=runBlocking {
        val user=System.getenv("MAILPILOT_LIVE_IMAP_USER").orEmpty(); val password=System.getenv("MAILPILOT_LIVE_IMAP_PASSWORD").orEmpty()
        assumeTrue("Opt-in real mailbox credentials not provided",user.isNotEmpty() && password.isNotEmpty())
        val ctx: Application=RuntimeEnvironment.getApplication()
        val db=Room.inMemoryDatabaseBuilder(ctx,MailDatabase::class.java).allowMainThreadQueries().build()
        try {
            val account=account(user); db.dao().putAccount(account)
            val secrets=object: SecretStore { override fun encrypt(value: String)=""; override fun decrypt(value: String)=password }
            var stats=0 to 0
            val repo=MailRepositoryImpl(db,secrets,ctx.filesDir,onSyncStats={ d,h -> stats=d to h })
            var start=System.nanoTime()
            val errors=repo.syncAccount(account.id,"INBOX")
            val folders=db.dao().cachedFolders(account.id)
            val cold=folders.associateWith { db.dao().cachedMessages(account.id,it) }
            println("LIVE_IMAP allFolders=${folders.size} coldMs=${(System.nanoTime()-start)/1000000} errors=${errors.size} counts=${folders.map { cold.getValue(it).size }} downloads=${stats.first}")
            if(errors.isNotEmpty()) println("LIVE_IMAP serverErrors=${safeDetail(errors.joinToString("; "))}")
            assertTrue(errors.isEmpty()); assertTrue(cold.values.all { it.size<=50 && it.all { m -> m.bodyState=="READY" } })
            start=System.nanoTime(); val warmErrors=repo.syncAccount(account.id,"INBOX")
            println("LIVE_IMAP allFoldersWarmMs=${(System.nanoTime()-start)/1000000} errors=${warmErrors.size} downloads=${stats.first} cacheHits=${stats.second}")
            assertTrue(warmErrors.isEmpty()); assertEquals(0,stats.first)
            for(name in folders) {
                val warm=db.dao().cachedMessages(account.id,name)
                assertEquals(cold.getValue(name).map { it.id to it.unread },warm.map { it.id to it.unread })
                assertNotNull(db.dao().syncCursor(account.id,name))
            }
        } catch(e: Exception) { throw AssertionError("Live all-folder verification failed: ${e.javaClass.simpleName}") }
          finally { db.close() }
    }
    @Test fun realImapColdAndWarmReadOnly()=runBlocking {
        val user=System.getenv("MAILPILOT_LIVE_IMAP_USER").orEmpty()
        val password=System.getenv("MAILPILOT_LIVE_IMAP_PASSWORD").orEmpty()
        assumeTrue("Opt-in real mailbox credentials not provided",user.isNotEmpty() && password.isNotEmpty())
        val ctx: Application=RuntimeEnvironment.getApplication()
        val db=Room.inMemoryDatabaseBuilder(ctx,MailDatabase::class.java).allowMainThreadQueries().build()
        try {
            val account=account(user)
            db.dao().putAccount(account)
            val secrets=object: SecretStore { override fun encrypt(value: String)=""; override fun decrypt(value: String)=password }
            val stats=mutableListOf<Pair<Int,Int>>()
            val repo=MailRepositoryImpl(db,secrets,ctx.filesDir,onSyncStats={ downloads,hits -> stats+=downloads to hits })
            var start=System.nanoTime()
            val folders=repo.folders(account.id)
            println("LIVE_IMAP folders=${folders.size} elapsedMs=${(System.nanoTime()-start)/1000000}")
            assertTrue(folders.contains("INBOX"))
            start=System.nanoTime()
            val cold=repo.load(account.id,"INBOX",onProgress={ stage -> println("LIVE_IMAP stage=$stage elapsedMs=${(System.nanoTime()-start)/1000000}") })
            println("LIVE_IMAP coldCount=${cold.size} incomplete=${cold.count { it.bodyError.isNotEmpty() }} elapsedMs=${(System.nanoTime()-start)/1000000} downloads=${stats.last().first}")
            assertTrue(cold.isNotEmpty()); assertEquals(0,cold.count { it.bodyError.isNotEmpty() })
            start=System.nanoTime()
            val warm=repo.load(account.id,"INBOX")
            println("LIVE_IMAP warmCount=${warm.size} elapsedMs=${(System.nanoTime()-start)/1000000} downloads=${stats.last().first} cacheHits=${stats.last().second}")
            assertEquals(cold.map { it.id },warm.map { it.id })
            assertEquals(cold.map { it.unread },warm.map { it.unread })
            assertEquals(0,stats.last().first)
        } catch(e: Exception) {
            throw AssertionError("Live IMAP verification failed: ${e.javaClass.simpleName}: ${safeDetail(e.message.orEmpty())}")
        } finally { db.close() }
    }
}
