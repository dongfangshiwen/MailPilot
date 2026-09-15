package app.mailpilot.attachments

import app.mailpilot.data.*
import java.io.File

class MaterialFailure(message: String): IllegalStateException(message)

/** Shared by selection UI, native preflight and actual file processing. */
object SelectionPolicy {
    const val FILE_BYTES=20L*1024*1024
    const val TOTAL_BYTES=50L*1024*1024
    const val FILES=10
    const val IMAGES=20
    val formats=setOf("docx","xlsx","pptx","pdf","txt","jpg","jpeg","png","webp")
    fun extension(a: Attachment)=a.name.substringAfterLast('.',"").lowercase()
    fun reason(a: Attachment): String=when {
        extension(a) !in formats -> "此格式暂不支持分析"
        actualSize(a)>FILE_BYTES -> "超过单文件 20 MB"
        else -> ""
    }
    fun defaults(id: String,files: List<Attachment>): Selection {
        val allowed=files.filter { reason(it).isEmpty() }
        return Selection(id,allowed.map { it.id },defaultPdfIds=allowed.filter { extension(it)=="pdf" }.map { it.id })
    }
    fun toggle(old: Selection,a: Attachment): Selection {
        if(a.id in old.attachmentIds) return old.copy(attachmentIds=old.attachmentIds-a.id,pdfPages=old.pdfPages-a.id,defaultPdfIds=old.defaultPdfIds-a.id)
        reason(a).takeIf { it.isNotEmpty() }?.let { throw MaterialFailure("${a.name}：$it") }
        return old.copy(attachmentIds=old.attachmentIds+a.id,defaultPdfIds=if(extension(a)=="pdf") old.defaultPdfIds+a.id else old.defaultPdfIds)
    }
    fun summary(files: List<Attachment>,pages: Map<String,List<Int>>,defaults: Set<String>): Map<String,Any> {
        val unique=files.distinctBy { it.id }
        val size=unique.sumOf { actualSize(it).coerceAtLeast(0) }
        val unknown=unique.count { actualSize(it)<0 }
        val visuals=unique.sumOf { when(extension(it)) { "jpg","jpeg","png","webp" -> 1; "pdf" -> pages[it.id]?.size ?: 0; else -> 0 } }
        val issues=mutableListOf<String>()
        unique.forEach { a -> reason(a).takeIf { it.isNotEmpty() }?.let { issues+="${a.name}：$it" }; if(extension(a)=="pdf" && a.id !in defaults && pages[a.id].isNullOrEmpty()) issues+="${a.name}：请选择 PDF 页码" }
        if(unique.size>FILES) issues+="已选 ${unique.size} 个附件，每轮最多 $FILES 个"
        if(size>TOTAL_BYTES) issues+="附件合计超过 50 MB"
        if(visuals>IMAGES) issues+="已选 $visuals 张图片或 PDF 页面，每轮最多 $IMAGES 张"
        return mapOf("count" to unique.size,"bytes" to size,"unknown" to unknown,"visuals" to visuals,"pendingVisuals" to unique.any { extension(it) in setOf("docx","xlsx","pptx") || it.id in defaults },"blocked" to issues.isNotEmpty(),"issues" to issues)
    }
    fun actualSize(a: Attachment)=a.localPath.takeIf { it.isNotBlank() }?.let { File(it).takeIf(File::isFile)?.length() } ?: a.size
    fun requireAllowed(summary: Map<String,Any>) {
        if(summary["blocked"]==true) throw MaterialFailure((summary["issues"] as List<*>).joinToString("；"))
    }
}

class ProcessingBudget {
    private val files=mutableSetOf<String>()
    var bytes=0L; private set
    var images=0; private set
    var characters=0; private set
    fun file(a: Attachment) {
        if(!files.add(a.id)) return
        SelectionPolicy.reason(a).takeIf { it.isNotEmpty() }?.let { throw MaterialFailure("${a.name}：$it") }
        val size=SelectionPolicy.actualSize(a)
        if(size<0 || size>SelectionPolicy.FILE_BYTES) throw MaterialFailure("${a.name}：文件大小无效或超过 20 MB")
        bytes+=size
        if(files.size>SelectionPolicy.FILES || bytes>SelectionPolicy.TOTAL_BYTES) throw MaterialFailure("${a.name}：本轮附件超过 10 个或合计 50 MB，请调整资料")
    }
    fun image(name: String) { if(++images>SelectionPolicy.IMAGES) throw MaterialFailure("$name：本轮图片、PDF 页面及 Office 嵌入图片合计超过 20 张，请减少附件或页码") }
    fun text(text: String) { characters+=text.length; if(characters>240000) throw MaterialFailure("所选文字资料超过 24 万字，请减少选择或拆分文档") }
    fun sources(sources: List<SourceChunk>) { sources.forEach { text(it.text); if(it.imagePath.isNotEmpty()) image(it.title) } }
}
