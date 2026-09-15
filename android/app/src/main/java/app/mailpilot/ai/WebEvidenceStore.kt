package app.mailpilot.ai

import app.mailpilot.data.SourceChunk
import app.mailpilot.data.stableId
import java.io.File

/** Full extracted pages stay outside Room rows; references never contain paths. */
class WebEvidenceStore(root: File,account: String,conversation: String) {
    private val directory=File(File(root,stableId(account)),stableId(conversation))
    fun save(source: SourceChunk): SourceChunk {
        require(source.kind=="web" && source.retrieval=="webpage")
        val bytes=source.text.toByteArray(Charsets.UTF_8)
        require(bytes.size<=MAX_BYTES) { "Extracted web text exceeds storage limit" }
        check(directory.isDirectory || directory.mkdirs()) { "Cannot create web evidence directory" }
        val key=stableId(source.text); val target=File(directory,"$key.txt")
        val pending=File.createTempFile("page-",".tmp",directory)
        try {
            pending.outputStream().use { it.write(bytes); it.flush() }
            // Same-directory rename publishes a complete file before its checkpoint.
            if(!pending.renameTo(target)) {
                check(target.isFile && target.readText()==source.text) { "Cannot commit web evidence" }
            }
        } finally { pending.delete() }
        return source.copy(contentKey=key,webReadVersion=WebReadWorkflow.READ_POLICY_VERSION,webReadStatus="complete")
    }
    fun restore(source: SourceChunk): SourceChunk {
        if(source.kind!="web" || source.contentKey.isBlank()) return normalize(source)
        val key=source.contentKey
        val text=runCatching {
            require(KEY.matches(key))
            val file=File(directory,"$key.txt")
            require(file.canonicalFile.parentFile==directory.canonicalFile && file.length()<=MAX_BYTES)
            file.readText().also { require(stableId(it)==key) }
        }.getOrNull()
        return if(text!=null) normalize(source.copy(text=text))
        else source.copy(contentKey="",retrieval="excerpt",location="此前网页摘录（完整原文已失效，可重新读取）")
    }
    fun clear() { directory.deleteRecursively() }
    companion object {
        fun normalize(source: SourceChunk): SourceChunk = if(source.kind=="web" && source.retrieval=="webpage" && source.webReadVersion!=WebReadWorkflow.READ_POLICY_VERSION)
            source.copy(retrieval="webpage_unverified",location="此前网页片段（读取策略已更新，正文完整性待核对）",webReadStatus="legacy") else source
        private val KEY=Regex("[a-f0-9]{64}")
        private const val MAX_BYTES=8*1024*1024L
        fun clearAccount(root: File,account: String) { File(root,stableId(account)).deleteRecursively() }
    }
}
