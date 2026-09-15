package app.mailpilot.attachments

import android.content.Context
import android.graphics.*
import android.graphics.pdf.PdfRenderer
import android.os.ParcelFileDescriptor
import androidx.exifinterface.media.ExifInterface
import app.mailpilot.data.*
import app.mailpilot.ai.contentFingerprint
import app.mailpilot.mail.MAX_ATTACHMENT_BYTES
import app.mailpilot.mail.readLimited
import kotlinx.coroutines.*
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import java.io.File
import java.nio.ByteBuffer
import java.nio.charset.CodingErrorAction
import java.nio.charset.Charset

interface AttachmentProcessor {
    suspend fun pdfCount(file: File): Int
    suspend fun process(attachment: Attachment,pages: List<Int> = emptyList(),onProgress: (String)->Unit = {}): List<SourceChunk>
    suspend fun previewPdf(file: File,page: Int): File
    suspend fun previewImage(file: File): File = error("图片预览不可用")
    suspend fun thumbnailPdf(file: File,page: Int): File = previewPdf(file,page)
    suspend fun processBudgeted(attachment: Attachment,pages: List<Int>,budget: ProcessingBudget,onProgress: (String)->Unit): List<SourceChunk> =
        process(attachment,pages,onProgress).also(budget::sources)
}

fun Attachment.isImageAttachment(): Boolean = mimeType.substringBefore(';').trim().startsWith("image/",true) ||
    name.substringAfterLast('.', "").lowercase() in setOf("jpg","jpeg","png","webp","gif","bmp","heic","heif","avif")

fun Attachment.openMimeType(): String = if(mimeType.startsWith("image/",true)) mimeType.substringBefore(';').lowercase() else
    when(name.substringAfterLast('.', "").lowercase()) {
        "jpg","jpeg" -> "image/jpeg"
        "png","webp","gif","bmp","heic","heif","avif" -> "image/${name.substringAfterLast('.').lowercase()}"
        else -> mimeType
    }

class AndroidAttachmentProcessor(context: Context): AttachmentProcessor {
    private val root=File(context.cacheDir,"preview").apply { mkdirs() }
    private val imagePreviewLock=Mutex()
    private val pdfRenderLock=Mutex()
    override suspend fun previewImage(file: File): File = withContext(Dispatchers.IO) {
        require(file.isFile && file.length()<=MAX_ATTACHMENT_BYTES) { "图片不存在或超过 20 MB" }
        imagePreviewLock.withLock { prepareImage(file) }
    }
    override suspend fun pdfCount(file: File): Int = withContext(Dispatchers.IO) {
        ParcelFileDescriptor.open(file,ParcelFileDescriptor.MODE_READ_ONLY).use { fd -> PdfRenderer(fd).use { it.pageCount } }
    }
    override suspend fun previewPdf(file: File,page: Int)=renderPdf(file,page,2048)
    override suspend fun thumbnailPdf(file: File,page: Int)=renderPdf(file,page,480)
    private suspend fun renderPdf(file: File,page: Int,longEdge: Int): File = pdfRenderLock.withLock { withContext(Dispatchers.IO) {
        currentCoroutineContext().ensureActive()
        val target=File(root,"${stableId(contentFingerprint(file)+"pdf-v1")}-page-$page-$longEdge.jpg")
        if(target.isFile && target.length()>0) return@withContext target
        val temporary=File(root,"${newId()}.jpg")
        try {
        ParcelFileDescriptor.open(file,ParcelFileDescriptor.MODE_READ_ONLY).use { fd -> PdfRenderer(fd).use { renderer ->
            require(page in 0 until renderer.pageCount) { "PDF 页码无效" }
            renderer.openPage(page).use { p ->
                val scale=longEdge.toFloat()/maxOf(p.width,p.height)
                val bitmap=Bitmap.createBitmap(maxOf(1,(p.width*scale).toInt()),maxOf(1,(p.height*scale).toInt()),Bitmap.Config.ARGB_8888)
                try { bitmap.eraseColor(Color.WHITE); p.render(bitmap,null,null,PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY); temporary.outputStream().use { check(bitmap.compress(Bitmap.CompressFormat.JPEG,90,it)) } } finally { bitmap.recycle() }
            }
        } }
        currentCoroutineContext().ensureActive()
        check(temporary.renameTo(target)) { "无法保存 PDF 预览" }; target
        } finally { temporary.delete() }
    } }
    override suspend fun process(attachment: Attachment,pages: List<Int>,onProgress: (String)->Unit)=processInternal(attachment,pages,null,onProgress)
    override suspend fun processBudgeted(attachment: Attachment,pages: List<Int>,budget: ProcessingBudget,onProgress: (String)->Unit)=processInternal(attachment,pages,budget,onProgress)
    private suspend fun processInternal(attachment: Attachment,pages: List<Int>,budget: ProcessingBudget?,onProgress: (String)->Unit): List<SourceChunk> = withContext(Dispatchers.IO) {
        val file=File(attachment.localPath)
        require(file.exists()) { "请先下载附件" }; require(file.length()<=MAX_ATTACHMENT_BYTES) { "单附件分析上限为 20 MB" }
        val ext=attachment.name.substringAfterLast('.').lowercase()
        onProgress("正在读取 ${attachment.name}")
        val result=when(ext) {
            "pdf" -> {
                require(pages.isNotEmpty() && pages.distinct().size<=20) { "请先选择 PDF 页面，每次最多 20 页" }
                val count=pdfCount(file)
                require(pages.all { it in 0 until count }) { "PDF 页码无效" }
                pages.distinct().sorted().mapIndexed { index,p ->
                    budget?.image(attachment.name)
                    currentCoroutineContext().ensureActive(); onProgress("${attachment.name} · 渲染 ${index+1}/${pages.size} 页")
                    SourceChunk(messageId=attachment.messageId,attachmentId=attachment.id,title=attachment.name,location="第 ${p+1} 页",imagePath=previewPdf(file,p).absolutePath)
                }
            }
            "jpg","jpeg","png","webp" -> { budget?.image(attachment.name); listOf(SourceChunk(messageId=attachment.messageId,attachmentId=attachment.id,title=attachment.name,location="图片",imagePath=previewImage(file).absolutePath)) }
            "docx","xlsx","pptx" -> runInterruptible { OfficeReader { bytes,imageExt ->
                budget?.image(attachment.name)
                val raw=File(root,"${newId()}.$imageExt"); raw.writeBytes(bytes)
                try { prepareImage(raw).absolutePath } finally { raw.delete() }
            }.read(file,ext,attachment.messageId,attachment.id,attachment.name) }
            "txt" -> {
                val bytes=file.inputStream().use { it.readLimited(MAX_ATTACHMENT_BYTES) }
                val text=decodeText(bytes)
                text.chunked(6000).mapIndexed { i,t -> SourceChunk(messageId=attachment.messageId,attachmentId=attachment.id,title=attachment.name,location="文本段 ${i+1}",text=t) }
            }
            "doc","xls","ppt" -> error("请将旧版 .$ext 文件转换为 docx / xlsx / pptx 后分析")
            else -> error("暂不支持 .$ext 附件分析，可以下载后用其他应用打开")
        }
        require(result.isNotEmpty()) { "未提取到可分析内容，文件可能为空或仅包含不支持的对象" }
        result.forEach { budget?.text(it.text) }
        result
    }
    private fun prepareImage(file: File): File {
        val output=File(root,"prepared-${contentFingerprint(file)}-v1.jpg")
        if(output.isFile && output.length()>0) return output
        val bounds=BitmapFactory.Options().apply { inJustDecodeBounds=true }; BitmapFactory.decodeFile(file.absolutePath,bounds)
        require(bounds.outWidth>0 && bounds.outHeight>0) { "图片格式无效" }
        require(bounds.outWidth.toLong()*bounds.outHeight<=100_000_000L) { "图片尺寸过大" }
        var sample=1; while(maxOf(bounds.outWidth,bounds.outHeight)/sample>4096) sample*=2
        val bitmap=BitmapFactory.decodeFile(file.absolutePath,BitmapFactory.Options().apply { inSampleSize=sample }) ?: error("无法解码图片")
        val orientation=runCatching { ExifInterface(file).getAttributeInt(ExifInterface.TAG_ORIENTATION,ExifInterface.ORIENTATION_NORMAL) }.getOrDefault(ExifInterface.ORIENTATION_NORMAL)
        val m=Matrix()
        when(orientation) {
            ExifInterface.ORIENTATION_ROTATE_90 -> m.postRotate(90f)
            ExifInterface.ORIENTATION_ROTATE_180 -> m.postRotate(180f)
            ExifInterface.ORIENTATION_ROTATE_270 -> m.postRotate(270f)
            ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> m.postScale(-1f,1f)
            ExifInterface.ORIENTATION_FLIP_VERTICAL -> m.postScale(1f,-1f)
            ExifInterface.ORIENTATION_TRANSPOSE -> { m.postRotate(90f); m.postScale(-1f,1f) }
            ExifInterface.ORIENTATION_TRANSVERSE -> { m.postRotate(270f); m.postScale(-1f,1f) }
        }
        val scale=minOf(1f,2048f/maxOf(bitmap.width,bitmap.height)); m.postScale(scale,scale)
        val transformed=Bitmap.createBitmap(bitmap,0,0,bitmap.width,bitmap.height,m,true)
        val temporary=File(root,"${newId()}.jpg")
        try { temporary.outputStream().use { transformed.compress(Bitmap.CompressFormat.JPEG,90,it) }; check(temporary.renameTo(output)) } finally { temporary.delete(); if(transformed!==bitmap) transformed.recycle(); bitmap.recycle() }
        return output
    }
}

fun decodeText(bytes: ByteArray): String {
    if(bytes.size>=2 && bytes[0]==0xFF.toByte() && bytes[1]==0xFE.toByte()) return String(bytes,Charsets.UTF_16LE).removePrefix("\uFEFF")
    if(bytes.size>=2 && bytes[0]==0xFE.toByte() && bytes[1]==0xFF.toByte()) return String(bytes,Charsets.UTF_16BE).removePrefix("\uFEFF")
    return try { Charsets.UTF_8.newDecoder().onMalformedInput(CodingErrorAction.REPORT).decode(ByteBuffer.wrap(bytes)).toString().removePrefix("\uFEFF") }
    catch(_: Exception) { String(bytes,Charset.forName("GB18030")) }
}
