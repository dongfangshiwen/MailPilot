package app.mailpilot.data

import androidx.room.*
import kotlinx.coroutines.flow.Flow

@Dao
interface MailDao {
    @Query("SELECT id,title,accountId,createdAt,lastActivityAt,pinnedAt FROM conversations ORDER BY pinnedAt DESC,lastActivityAt DESC,id DESC") fun conversationHeaders(): Flow<List<ConversationHeader>>
    @Query("SELECT id,title,accountId,createdAt,lastActivityAt,pinnedAt FROM conversations WHERE (accountId='' OR accountId=:accountId) AND (:search='' OR instr(lower(title),lower(:search))>0 OR EXISTS (SELECT 1 FROM chat_entries e WHERE e.conversationId=conversations.id AND instr(lower(e.text),lower(:search))>0)) AND (:first OR pinnedAt<:pin OR (pinnedAt=:pin AND lastActivityAt<:activity) OR (pinnedAt=:pin AND lastActivityAt=:activity AND id<:afterId)) ORDER BY pinnedAt DESC,lastActivityAt DESC,id DESC LIMIT :limit")
    suspend fun conversationPage(accountId: String,first: Boolean,pin: Long,activity: Long,afterId: String,limit: Int,search: String=""): List<ConversationHeader>
    @Query("UPDATE conversations SET title=:title WHERE id=:id") suspend fun renameConversation(id: String,title: String)
    @Query("UPDATE conversations SET pinnedAt=:time WHERE id IN (:ids)") suspend fun pinConversations(ids: List<String>,time: Long)
    @Query("UPDATE conversations SET lastActivityAt=:time WHERE id=:id") suspend fun touchConversation(id: String,time: Long)
    @Query("SELECT * FROM visual_evidence WHERE conversationId=:conversationId AND accountId=:accountId ORDER BY createdAt DESC,id DESC") suspend fun visualEvidence(conversationId: String,accountId: String): List<VisualEvidence>
    @Upsert suspend fun putVisualEvidence(value: VisualEvidence)
    @Query("SELECT * FROM processed_materials WHERE id=:id AND conversationId=:conversationId AND accountId=:accountId") suspend fun processedMaterial(id: String,conversationId: String,accountId: String): ProcessedMaterial?
    @Upsert suspend fun putProcessedMaterial(value: ProcessedMaterial)
    @Query("SELECT sourcesJson FROM processed_materials UNION SELECT sourcesJson FROM visual_evidence UNION SELECT sourcesJson FROM chat_entries") suspend fun retainedImageSources(): List<String>
    @Query("SELECT * FROM local_materials WHERE conversationId=:id") fun materials(id: String): Flow<List<LocalMaterial>>
    @Query("SELECT * FROM local_materials WHERE id=:id") suspend fun material(id: String): LocalMaterial?
    @Query("SELECT * FROM local_materials") suspend fun allMaterials(): List<LocalMaterial>
    @Upsert suspend fun putMaterial(value: LocalMaterial)
    @Query("UPDATE local_materials SET selected=0 WHERE conversationId=:id") suspend fun deselectMaterials(id: String)
    @Query("DELETE FROM chat_entries WHERE conversationId=:id") suspend fun deleteEntries(id: String)
    @Query("DELETE FROM conversations WHERE id=:id") suspend fun deleteConversation(id: String)

    @Query("SELECT * FROM accounts ORDER BY label") fun accounts(): Flow<List<MailAccount>>
    @Query("SELECT * FROM accounts") suspend fun allAccounts(): List<MailAccount>
    @Query("SELECT * FROM accounts WHERE id=:id") suspend fun account(id: String): MailAccount?
    @Upsert suspend fun putAccount(value: MailAccount)
    @Query("DELETE FROM accounts WHERE id=:id") suspend fun deleteAccount(id: String)
    @Query("SELECT * FROM models ORDER BY label") fun models(): Flow<List<ModelProfile>>
    @Query("SELECT * FROM models WHERE id=:id") suspend fun model(id: String): ModelProfile?
    @Upsert suspend fun putModel(value: ModelProfile)
    @Query("DELETE FROM models WHERE id=:id") suspend fun deleteModel(id: String)
    @Query("SELECT * FROM messages WHERE accountId=:accountId AND folder=:folder ORDER BY sentAt DESC, uid DESC")
    fun messages(accountId: String, folder: String): Flow<List<MailMessage>>
    @Query("SELECT * FROM messages WHERE id=:id") suspend fun message(id: String): MailMessage?
    @Query("SELECT name FROM mail_folders WHERE accountId=:accountId ORDER BY name") suspend fun cachedFolders(accountId: String): List<String>
    @Query("DELETE FROM mail_folders WHERE accountId=:accountId") suspend fun clearFolders(accountId: String)
    @Insert suspend fun putFolders(values: List<MailFolder>)
    @Query("SELECT * FROM mail_index WHERE accountId=:accountId AND folder=:folder AND validity=:validity") suspend fun mailIndex(accountId: String,folder: String,validity: Long): List<MailIndex>
    @Upsert suspend fun putIndex(values: List<MailIndex>)
    @Query("DELETE FROM mail_index WHERE accountId=:accountId AND folder=:folder AND validity!=:validity") suspend fun purgeOldIndex(accountId: String,folder: String,validity: Long)
    @Query("DELETE FROM mail_index WHERE accountId=:accountId AND folder=:folder AND validity=:validity AND uid IN (:uids)") suspend fun deleteIndex(accountId: String,folder: String,validity: Long,uids: List<Long>)
    @Query("DELETE FROM messages WHERE accountId=:accountId AND folder=:folder AND uidValidity=:validity AND uid IN (:uids)") suspend fun deleteMissingMessages(accountId: String,folder: String,validity: Long,uids: List<Long>)
    @Upsert suspend fun putMessages(values: List<MailMessage>)
    @Query("SELECT * FROM messages WHERE accountId=:accountId AND folder=:folder ORDER BY sentAt DESC, uid DESC") suspend fun cachedMessages(accountId: String,folder: String): List<MailMessage>
    @Query("SELECT * FROM sync_cursors WHERE accountId=:accountId AND folder=:folder") suspend fun syncCursor(accountId: String,folder: String): SyncCursor?
    @Upsert suspend fun putSyncCursor(cursor: SyncCursor)
    @Query("SELECT * FROM conversation_turns WHERE conversationId=:id ORDER BY number ASC") suspend fun turns(id: String): List<TurnSnapshot>
    @Upsert suspend fun putTurn(turn: TurnSnapshot)
    @Query("UPDATE conversation_turns SET requestJson=:request WHERE id=:id") suspend fun updateTurnRequest(id: String,request: String)
    @Query("SELECT * FROM conversation_turns") suspend fun allTurns(): List<TurnSnapshot>
    @Query("DELETE FROM conversation_turns WHERE conversationId NOT IN (SELECT id FROM conversations)") suspend fun purgeOrphanTurns()
    @Query("SELECT * FROM conversation_turns WHERE id=:id") suspend fun turn(id: String): TurnSnapshot?
    @Query("SELECT requestJson FROM conversation_turns WHERE conversationId=:conversation AND accountId=:account AND requestJson LIKE '%\"materialNotes\"%' ORDER BY number DESC LIMIT 1 OFFSET :offset")
    suspend fun materialNoteRequest(conversation: String,account: String,offset: Int): String?
    @Query("UPDATE conversations SET selectionJson=:selection, folder=:folder, accountId=CASE WHEN accountId='' THEN :accountId ELSE accountId END WHERE id=:id") suspend fun updateSelection(id: String,accountId: String,folder: String,selection: String)
    @Query("UPDATE messages SET unread=:unread WHERE id=:id") suspend fun setUnread(id: String, unread: Boolean)
    @Query("DELETE FROM messages WHERE accountId=:accountId") suspend fun deleteMessages(accountId: String)
    @Query("DELETE FROM messages WHERE accountId=:accountId AND folder=:folder AND uidValidity!=:validity") suspend fun purgeOldValidity(accountId: String, folder: String, validity: Long)
    @Query("SELECT * FROM attachments WHERE messageId=:messageId ORDER BY partPath") suspend fun attachments(messageId: String): List<Attachment>
    @Query("SELECT * FROM attachments WHERE id=:id") suspend fun attachment(id: String): Attachment?
    @Upsert suspend fun putAttachments(values: List<Attachment>)
    @Query("DELETE FROM attachments WHERE messageId NOT IN (SELECT id FROM messages)") suspend fun purgeOrphanAttachments()
    @Query("UPDATE attachments SET localPath='' ") suspend fun clearAttachmentPaths()
    @Query("SELECT * FROM drafts ORDER BY updatedAt DESC") fun drafts(): Flow<List<Draft>>
    @Query("SELECT * FROM drafts") suspend fun allDrafts(): List<Draft>
    @Query("SELECT * FROM drafts WHERE id=:id") suspend fun draft(id: String): Draft?
    @Upsert suspend fun putDraft(value: Draft)
    @Query("DELETE FROM drafts WHERE id=:id AND status IN ('DRAFT','FAILED','SENT')") suspend fun deleteDraft(id: String)
    @Query("DELETE FROM drafts WHERE accountId=:accountId") suspend fun deleteAccountDrafts(accountId: String)
    @Insert suspend fun insertAttempt(value: SendAttempt)
    @Upsert suspend fun putAttempt(value: SendAttempt)
    @Query("SELECT * FROM send_attempts WHERE draftId=:draftId AND revision=:revision") suspend fun attempt(draftId: String, revision: Long): SendAttempt?
    @Query("UPDATE drafts SET status='UNKNOWN', error='发送过程中应用退出，请核对已发送邮件后再操作' WHERE status='SENDING'") suspend fun recoverDrafts()
    @Query("UPDATE send_attempts SET status='UNKNOWN', detail='发送过程中应用退出' WHERE status IN ('PREPARING','SENDING')") suspend fun recoverAttempts()
    @Query("DELETE FROM send_attempts WHERE draftId NOT IN (SELECT id FROM drafts)") suspend fun purgeOrphanAttempts()
    @Query("SELECT * FROM conversations WHERE id=:id") fun observeConversation(id: String): Flow<Conversation?>
    @Query("SELECT * FROM conversations WHERE id=:id") suspend fun conversation(id: String): Conversation?
    @Upsert suspend fun putConversation(value: Conversation)
    @Query("UPDATE conversations SET contextSummary=:summary, summaryThroughId=:throughId, summarizedEntries=:count WHERE id=:id AND accountId=:accountId")
    suspend fun updateContext(id: String,accountId: String,summary: String,throughId: String,count: Int): Int
    @Query("UPDATE conversations SET contextSummary=:summary,summaryThroughId=:throughId,summarizedEntries=:count WHERE id=:id AND accountId=:accountId AND contextSummary=:oldSummary AND summaryThroughId=:oldThrough")
    suspend fun commitContext(id: String,accountId: String,oldSummary: String,oldThrough: String,summary: String,throughId: String,count: Int): Int
    @Query("SELECT * FROM chat_entries WHERE conversationId=:id ORDER BY createdAt ASC, rowid ASC") fun entries(id: String): Flow<List<ChatEntry>>
    @Query("SELECT * FROM chat_entries WHERE conversationId=:id ORDER BY createdAt ASC, rowid ASC") suspend fun history(id: String): List<ChatEntry>
    @Upsert suspend fun putEntry(value: ChatEntry)
    @Query("DELETE FROM chat_entries") suspend fun clearEntries()
    @Query("DELETE FROM conversations") suspend fun clearConversations()
    @Query("DELETE FROM chat_entries WHERE conversationId IN (SELECT id FROM conversations WHERE accountId=:accountId)") suspend fun deleteAccountEntries(accountId: String)
    @Query("DELETE FROM conversations WHERE accountId=:accountId") suspend fun deleteAccountConversations(accountId: String)
}

class HistoryV9Migration: androidx.room.migration.AutoMigrationSpec {
    override fun onPostMigrate(db: androidx.sqlite.db.SupportSQLiteDatabase) {
        db.execSQL("UPDATE conversations SET lastActivityAt=COALESCE((SELECT MAX(createdAt) FROM chat_entries WHERE conversationId=conversations.id AND role='user'),createdAt)")
    }
}

@Database(entities = [MailAccount::class, ModelProfile::class, MailMessage::class, MailFolder::class, MailIndex::class, SyncCursor::class, TurnSnapshot::class, Attachment::class, Draft::class, SendAttempt::class, Conversation::class, ChatEntry::class, LocalMaterial::class, VisualEvidence::class, ProcessedMaterial::class], version = 9, exportSchema = true, autoMigrations = [AutoMigration(from=1,to=2),AutoMigration(from=2,to=3),AutoMigration(from=3,to=4),AutoMigration(from=4,to=5),AutoMigration(from=5,to=6),AutoMigration(from=6,to=7),AutoMigration(from=7,to=8),AutoMigration(from=8,to=9,spec=HistoryV9Migration::class)])
abstract class MailDatabase : RoomDatabase() { abstract fun dao(): MailDao }
