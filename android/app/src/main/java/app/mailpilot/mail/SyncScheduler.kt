package app.mailpilot.mail

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import androidx.work.*
import app.mailpilot.MailPilotApp
import app.mailpilot.data.MailQuery
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.*
import java.util.concurrent.TimeUnit

data class SyncStatus(val running: Boolean=false,val label: String="",val outcome: String="",val taskId: String="")

class SyncScheduler(context: Context) {
    private val manager=WorkManager.getInstance(context)
    private fun name(accountId: String)="mail-account-sync-$accountId"
    fun start(accountId: String,folder: String,more: Boolean=false,offset: Int=0) {
        val request=OneTimeWorkRequestBuilder<AccountSyncWorker>()
            .addTag("created:${System.currentTimeMillis()}")
            // WorkManager CONNECTED also requires Android's validation probe.
            // A reachable Chinese mail server must not depend on that probe.
            .setInputData(workDataOf("account" to accountId,"folder" to folder,"more" to more,"offset" to offset))
            .setBackoffCriteria(BackoffPolicy.EXPONENTIAL,30,TimeUnit.SECONDS).build()
        manager.enqueueUniqueWork(name(accountId),ExistingWorkPolicy.KEEP,request)
    }
    fun cancel(accountId: String) { manager.cancelUniqueWork(name(accountId)) }
    fun observe(accountId: String): Flow<SyncStatus> = manager.getWorkInfosForUniqueWorkFlow(name(accountId)).map { rows ->
        val current=rows.firstOrNull { !it.state.isFinished } ?: rows.maxByOrNull { row -> row.tags.firstOrNull { it.startsWith("created:") }?.substringAfter(':')?.toLongOrNull() ?: 0L }
        current?.let {
            val running=!it.state.isFinished
            SyncStatus(running,if(it.state==WorkInfo.State.ENQUEUED) "同步已排队，等待网络" else it.progress.getString("label").orEmpty(),
                if(it.state==WorkInfo.State.CANCELLED) "同步已取消，已下载邮件保留" else it.outputData.getString("outcome").orEmpty(),it.id.toString())
        } ?: SyncStatus()
    }
}

class AccountSyncWorker(context: Context,parameters: WorkerParameters): CoroutineWorker(context,parameters) {
    override suspend fun doWork(): Result {
        val g=(applicationContext as MailPilotApp).graph; g.ready.await()
        val account=inputData.getString("account") ?: return Result.failure()
        if(g.dao.account(account)==null) return Result.failure()
        val connectivity=applicationContext.getSystemService(ConnectivityManager::class.java)
        val network=connectivity.getNetworkCapabilities(connectivity.activeNetwork)
        if(network?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)!=true) return Result.retry()
        val folder=inputData.getString("folder") ?: "INBOX"
        var lastProgress=0L
        fun progress(label: String) {
            val now=System.currentTimeMillis()
            if(now-lastProgress>400) { lastProgress=now; setProgressAsync(workDataOf("label" to label)) }
        }
        return try {
            if(inputData.getBoolean("more",false)) {
                val found=g.mail.load(account,folder,MailQuery(offset=inputData.getInt("offset",0),limit=50),::progress)
                Result.success(workDataOf("outcome" to if(found.isEmpty()) "没有更早的邮件" else "已加载 ${found.size} 封邮件"))
            } else {
                val errors=g.mail.syncAccount(account,folder,::progress)
                Result.success(workDataOf("outcome" to if(errors.isEmpty()) "各文件夹同步完成" else "部分文件夹未完成，可再次同步重试：${errors.joinToString("；").take(1200)}"))
            }
        } catch(e: CancellationException) { throw e }
          catch(e: Exception) { Result.failure(workDataOf("outcome" to "同步未完成，已缓存邮件保留。${friendlyMailError(e)}")) }
    }
}
