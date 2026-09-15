package app.mailpilot.attachments

import app.mailpilot.data.SourceChunk
import app.mailpilot.mail.readLimited
import org.xmlpull.v1.XmlPullParser
import org.xmlpull.v1.XmlPullParserFactory
import java.io.File
import java.nio.file.Paths
import java.time.LocalDate
import java.util.zip.ZipFile

data class XmlNode(val name: String,val attributes: Map<String,String>,val children: MutableList<XmlNode> = mutableListOf(),var text: String = "") {
    fun attr(name: String)=(attributes["rel:$name"] ?: attributes[name]).orEmpty()
    fun all(name: String): List<XmlNode> = children.flatMap { (if(it.name==name) listOf(it) else emptyList()) + it.all(name) }
    fun first(name: String): XmlNode?=all(name).firstOrNull()
    fun words(): String = if(name=="t") text else children.joinToString("") { when(it.name) { "tab" -> "\t"; "br" -> "\n"; else -> it.words() } }
}

class SafeOfficeArchive(file: File): AutoCloseable {
    private val zip=ZipFile(file)
    private var readBytes=0L
    private var nodeCount=0
    init { if(zip.size()>10000) { zip.close(); error("Office 文件结构过于复杂") } }
    fun exists(path: String)=zip.getEntry(path)!=null
    fun bytes(path: String): ByteArray {
        require(!path.startsWith("/") && !path.split('/').contains("..") && !path.contains('\\')) { "Office 附件路径无效" }
        val entry=zip.getEntry(path) ?: error("Office 文件缺少内容：$path")
        val remaining=100L*1024*1024-readBytes
        require(remaining>0 && entry.size<=remaining) { "Office 解压内容超过 100 MB" }
        val result=zip.getInputStream(entry).use { it.readLimited(remaining) }; readBytes+=result.size
        return result
    }
    fun xml(path: String): XmlNode {
        val parser=XmlPullParserFactory.newInstance().apply { isNamespaceAware=true }.newPullParser()
        parser.setFeature(XmlPullParser.FEATURE_PROCESS_DOCDECL,false)
        parser.setInput(bytes(path).inputStream(),null)
        val root=XmlNode("root",emptyMap()); val stack=mutableListOf(root)
        var event=parser.eventType
        while(event!=XmlPullParser.END_DOCUMENT) {
            if(Thread.currentThread().isInterrupted) throw InterruptedException()
            when(event) {
                XmlPullParser.DOCDECL -> error("不支持包含 DTD 的 Office 文档")
                XmlPullParser.START_TAG -> {
                    require(++nodeCount<=300000 && stack.size<100) { "Office 文档过于复杂" }
                    val n=XmlNode(parser.name,(0 until parser.attributeCount).associate { (if(parser.getAttributeNamespace(it).endsWith("/relationships")) "rel:" else "")+parser.getAttributeName(it) to parser.getAttributeValue(it) })
                    stack.last().children+=n; stack+=n
                }
                XmlPullParser.TEXT, XmlPullParser.CDSECT, XmlPullParser.ENTITY_REF -> { val text=parser.text.orEmpty(); stack.last().text+=text; require(stack.last().text.length<=2*1024*1024) { "单段文字过长" } }
                XmlPullParser.END_TAG -> stack.removeAt(stack.lastIndex)
            }
            event=parser.nextToken()
        }
        return root
    }
    data class Relation(val target: String,val type: String)
    fun relations(part: String): Map<String,Relation> {
        val parent=part.substringBeforeLast('/',"")
        val rel=if(part.isEmpty()) "_rels/.rels" else (if(parent.isEmpty()) "" else "$parent/")+"_rels/"+part.substringAfterLast('/')+".rels"
        if(!exists(rel)) return emptyMap()
        return xml(rel).all("Relationship").filter { it.attr("TargetMode")!="External" }.associate { r ->
            val target=r.attr("Target")
            require(!target.contains(':') && !target.contains('\\')) { "外部关系不受支持" }
            val normalized=if(target.startsWith('/')) target.removePrefix("/") else Paths.get(parent).resolve(target).normalize().toString().replace('\\','/')
            require(!normalized.startsWith("..")) { "Office 附件路径越界" }
            r.attr("Id") to Relation(normalized,r.attr("Type"))
        }
    }
    override fun close()=zip.close()
}

class OfficeReader(private val imageSink: (ByteArray,String)->String) {
    fun read(file: File,extension: String,messageId: String,attachmentId: String,title: String): List<SourceChunk> {
        val result=mutableListOf<SourceChunk>()
        fun text(location: String,value: String) { if(value.isNotBlank()) result+=SourceChunk(messageId=messageId,attachmentId=attachmentId,title=title,location=location,text=value.trim()) }
        SafeOfficeArchive(file).use { a ->
            val main=a.relations("").values.firstOrNull { it.type.endsWith("/officeDocument") }?.target ?: when(extension) { "docx"->"word/document.xml"; "xlsx"->"xl/workbook.xml"; else->"ppt/presentation.xml" }
            fun images(node: XmlNode,part: String,location: String) {
                val rels=a.relations(part)
                for((i,blip) in node.all("blip").withIndex()) {
                    val relation=rels[blip.attr("embed")] ?: continue
                    val ext=relation.target.substringAfterLast('.').lowercase()
                    if(ext !in listOf("jpg","jpeg","png","webp")) { text("$location · 图片 ${i+1}","[该嵌入图片格式 .$ext 暂不支持视觉分析]"); continue }
                    require(result.count { it.imagePath.isNotEmpty() }<80) { "嵌入图片超过 80 张，请拆分文档" }
                    result+=SourceChunk(messageId=messageId,attachmentId=attachmentId,title=title,location="$location · 图片 ${i+1}",imagePath=imageSink(a.bytes(relation.target),ext))
                }
            }
            when(extension) {
                "docx" -> {
                    val parts=listOf(main)+a.relations(main).values.filter { it.type.substringAfterLast('/') in listOf("header","footer","footnotes","endnotes") }.map { it.target }
                    for(part in parts) {
                        val doc=a.xml(part); val body=doc.first("body") ?: doc.children.first()
                        var paragraph=0; var table=0
                        for(n in body.children) {
                            if(n.name=="tbl") { table++; for((r,row) in n.children.filter { it.name=="tr" }.withIndex()) text("表格 $table · 第 ${r+1} 行",row.children.filter { it.name=="tc" }.joinToString(" | ") { cell -> cell.all("p").joinToString(" ") { it.words() } }) }
                            else { for(p in if(n.name=="p") listOf(n) else n.all("p")) { paragraph++; text("${if(part==main) "正文" else part.substringAfterLast('/')} · 段落 $paragraph",p.words()) } }
                            images(n,part,"${if(n.name=="tbl") "表格 $table" else "段落 $paragraph"}")
                        }
                    }
                }
                "xlsx" -> {
                    val book=a.xml(main); val rels=a.relations(main)
                    val shared=rels.values.firstOrNull { it.type.endsWith("/sharedStrings") }?.target?.let { a.xml(it).all("si").map { n -> n.words() } }.orEmpty()
                    val styles=rels.values.firstOrNull { it.type.endsWith("/styles") }?.target?.let { a.xml(it) }
                    val customFormats=styles?.all("numFmt")?.associate { it.attr("numFmtId") to it.attr("formatCode") }.orEmpty()
                    val formats=styles?.first("cellXfs")?.children?.map { it.attr("numFmtId") }.orEmpty()
                    val date1904=book.first("workbookPr")?.attr("date1904") in listOf("1","true")
                    for(sheet in book.all("sheet")) {
                        val path=rels[sheet.attr("id")]?.target ?: continue; val doc=a.xml(path); val name=sheet.attr("name")
                        for(row in doc.all("row")) {
                            val cells=row.children.filter { it.name=="c" }.map { c ->
                                var value=c.first("v")?.text.orEmpty()
                                value=when(c.attr("t")) { "s"->shared.getOrNull(value.toIntOrNull() ?: -1).orEmpty(); "inlineStr"->c.words(); "b"->if(value=="1") "TRUE" else "FALSE"; else->value }
                                val fmt=formats.getOrNull(c.attr("s").toIntOrNull() ?: 0).orEmpty()
                                val dateLike=fmt.toIntOrNull() in 14..22 || customFormats[fmt]?.let { it.contains('y',true) || (it.contains('d',true) && it.contains('m',true)) }==true
                                if(dateLike && value.toDoubleOrNull()!=null) {
                                    val serial=value.toDouble(); val days=serial.toLong()
                                    val date=if(!date1904 && days==60L) "1900-02-29（Excel 兼容日期）" else LocalDate.of(if(date1904) 1904 else 1899,if(date1904) 1 else 12,if(date1904) 1 else 31).plusDays(days-if(!date1904 && days>=60) 1 else 0).toString()
                                    val time=java.time.LocalTime.ofSecondOfDay((((serial-kotlin.math.floor(serial))*86400).toLong()).coerceIn(0,86399)).toString()
                                    value="$value（日期格式：$date $time，保留原始序列值）"
                                }
                                val formula=c.first("f")?.text.orEmpty()
                                if(formula.isNotEmpty()) value=if(value.isEmpty()) "公式 =$formula（无缓存值）" else "$value（公式缓存值）"
                                "${c.attr("r")}: $value"
                            }
                            text("$name · 第 ${row.attr("r")} 行",cells.joinToString(" | "))
                        }
                        val sheetRels=a.relations(path)
                        for(d in doc.all("drawing")) {
                            val drawing=sheetRels[d.attr("id")]?.target ?: continue
                            val content=a.xml(drawing)
                            val anchors=content.all("twoCellAnchor")+content.all("oneCellAnchor")+content.all("absoluteAnchor")
                            for(anchor in anchors) {
                                val from=anchor.first("from"); val row=from?.first("row")?.text?.toIntOrNull(); var col=(from?.first("col")?.text?.toIntOrNull() ?: -1)+1
                                var column=""; while(col>0) { col--; column=('A'.code+col%26).toChar()+column; col/=26 }
                                images(anchor,drawing,if(row!=null && column.isNotBlank()) "$name · $column${row+1} 附近" else "$name · 嵌入图片")
                            }
                        }
                    }
                }
                "pptx" -> {
                    val slides=a.xml(main).all("sldId"); val rels=a.relations(main)
                    for((i,s) in slides.withIndex()) {
                        val part=rels[s.attr("id")]?.target ?: continue; val doc=a.xml(part)
                        text("幻灯片 ${i+1}",doc.all("p").joinToString("\n") { it.words() })
                        for((t,table) in doc.all("tbl").withIndex()) for((r,row) in table.children.filter { it.name=="tr" }.withIndex())
                            text("幻灯片 ${i+1} · 表格 ${t+1} · 第 ${r+1} 行",row.children.filter { it.name=="tc" }.joinToString(" | ") { cell -> cell.all("p").joinToString(" ") { it.words() } })
                        images(doc,part,"幻灯片 ${i+1}")
                        for(note in a.relations(part).values.filter { it.type.endsWith("/notesSlide") }) text("幻灯片 ${i+1} · 备注",a.xml(note.target).all("p").joinToString("\n") { it.words() })
                    }
                }
            }
        }
        return result
    }
}
