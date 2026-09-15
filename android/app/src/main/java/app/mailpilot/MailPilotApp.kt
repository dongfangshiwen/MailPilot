package app.mailpilot

import android.app.Application
import android.content.Context
import androidx.room.Room
import androidx.room.withTransaction
import androidx.work.*
import app.mailpilot.ai.*
import app.mailpilot.attachments.AndroidAttachmentProcessor
import app.mailpilot.data.*
import app.mailpilot.mail.MailRepositoryImpl
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.first
import java.util.concurrent.TimeUnit

class MailPilotApp: Application() {
    lateinit var graph: AppGraph; private set
    override fun onCreate() { super.onCreate(); graph=AppGraph(this) }
}
class AppGraph(val context: Context) {
    val scope=CoroutineScope(SupervisorJob()+Dispatchers.IO)
    val db=Room.databaseBuilder(context,MailDatabase::class.java,"mailpilot.db").build()
    val dao=db.dao(); val secrets=AndroidSecrets(); val preferences=Preferences(context)
    val mail=MailRepositoryImpl(db,secrets,context.filesDir)
    val sync=app.mailpilot.mail.SyncScheduler(context)
    val models=CompatibleModelClient(secrets)
    val attachments=AndroidAttachmentProcessor(context)
    val webSearch=app.mailpilot.services.DirectWebSearchClient(secrets)
    val asr=app.mailpilot.services.QwenAsrClient(secrets)
    val webStorage=java.io.File(context.filesDir,"web-evidence")
    val agent=LocalAgent(dao,mail,attachments,models,webSearch,outputModes={ preferences.flow.first().outputModes },webStorage=webStorage) { preferences.flow.first().contextModes }
        .apply { pageReader=app.mailpilot.services.PublicWebReader(app.mailpilot.services.AndroidWebRenderer(context)) }
    val ready=scope.async {
        preferences.upgradeCompressionDefault()
        // Recover recordings left by process death before any new recorder exists.
        java.io.File(context.cacheDir,"speech").listFiles()?.forEach { if(it.isFile) it.delete() }
        db.withTransaction { dao.recoverDrafts(); dao.recoverAttempts() }
        recoverAgentRuns(dao)
    }
    init { scope.launch { preferences.flow.map { it.syncMinutes }.distinctUntilChanged().collect { schedule(it) } } }
    fun schedule(minutes: Int) {
        val manager=WorkManager.getInstance(context)
        if(minutes==0) manager.cancelUniqueWork("mail-sync") else manager.enqueueUniquePeriodicWork("mail-sync",ExistingPeriodicWorkPolicy.UPDATE,
            PeriodicWorkRequestBuilder<MailSyncWorker>(minutes.toLong(),TimeUnit.MINUTES).setInitialDelay(minutes.toLong(),TimeUnit.MINUTES).build())
    }
}
class MailSyncWorker(context: Context,parameters: WorkerParameters): CoroutineWorker(context,parameters) {
    override suspend fun doWork(): Result {
        val g=(applicationContext as MailPilotApp).graph; g.ready.await()
        for(a in g.dao.allAccounts()) g.sync.start(a.id,"INBOX")
        return Result.success()
    }
}
