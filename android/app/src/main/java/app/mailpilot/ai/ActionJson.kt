package app.mailpilot.ai

import android.util.JsonReader
import android.util.JsonToken
import app.mailpilot.data.stableId
import org.json.JSONArray
import org.json.JSONObject
import java.io.StringReader

/** Framing and validation are separate: prose never becomes tool arguments. */
object ActionJson {
    data class Envelope(val calls: JSONArray,val bare: Boolean)
    private fun fail(reason: String): Nothing=throw ModelFailure(FailureInfo("action_format",
        "模型操作格式无效（$reason），未执行该操作；请重试本轮。",diagnostics=JSONObject().put("stage","action_validation").put("protocol","action_json").put("reason",reason)))

    /** Strict JSON also rejects duplicate keys, trailing values and excessive nesting. */
    fun objectValue(raw: String): JSONObject=value(raw) as? JSONObject ?: fail("操作必须是对象")

    /** Shared typed values for native JSON and inline protocol parameters. */
    fun value(raw: String): Any {
        if(raw.length>1_048_576) fail("操作内容过长")
        try {
            // Android's strict reader only accepts an object/array at the document root.
            // A single-value array permits scalars without enabling lenient JSON syntax.
            JsonReader(StringReader("[$raw]")).use { reader ->
                fun value(depth: Int): Any {
                    if(depth>16) fail("操作嵌套过深")
                    return when(reader.peek()) {
                        JsonToken.BEGIN_OBJECT -> JSONObject().also { result ->
                            reader.beginObject()
                            while(reader.hasNext()) {
                                val key=reader.nextName(); if(result.has(key)) fail("操作字段重复")
                                result.put(key,value(depth+1))
                            }
                            reader.endObject()
                        }
                        JsonToken.BEGIN_ARRAY -> JSONArray().also { result ->
                            reader.beginArray(); while(reader.hasNext()) result.put(value(depth+1)); reader.endArray()
                        }
                        JsonToken.STRING -> reader.nextString()
                        JsonToken.NUMBER -> reader.nextString().let { it.toLongOrNull() ?: it.toDouble().also { n -> if(!n.isFinite()) fail("数值无效") } }
                        JsonToken.BOOLEAN -> reader.nextBoolean()
                        JsonToken.NULL -> { reader.nextNull(); JSONObject.NULL }
                        else -> fail("操作 JSON 不完整")
                    }
                }
                reader.beginArray()
                val result=value(0)
                if(reader.peek()!=JsonToken.END_ARRAY) fail("操作后存在多余内容")
                reader.endArray()
                if(reader.peek()!=JsonToken.END_DOCUMENT) fail("操作后存在多余内容")
                return result
            }
        } catch(e: ModelFailure) { throw e } catch(e: Exception) { fail("操作 JSON 不完整或语法无效") }
    }

    private data class Span(val start: Int,val end: Int)
    /** Locate top-level objects outside quoted prose, block quotes and inline code. */
    private fun objects(text: String): List<Span> {
        val result=mutableListOf<Span>(); var at=0; var start=-1; var depth=0; var quote=false; var escaped=false
        var ticks=0
        while(at<text.length) {
            val c=text[at]
            if(start<0) {
                if(at==0 || text[at-1]=='\n') {
                    var line=at; while(line<text.length && text[line]==' ') line++
                    if(line<text.length && text[line]=='>') {
                        at=text.indexOf('\n',line).let { if(it<0) text.length else it+1 }; continue
                    }
                }
                if(c=='`') {
                    var n=1; while(at+n<text.length && text[at+n]=='`') n++
                    // Fenced JSON is a protocol wrapper; inline code remains an example.
                    if(n<3) ticks=if(ticks==n) 0 else n
                    at+=n; continue
                }
                if(ticks>0) { at++; continue }
                if(escaped) { escaped=false; at++; continue }
                if(quote && c=='\\') { escaped=true; at++; continue }
                if(c=='"') { quote=!quote; at++; continue }
                if(!quote && c=='{') { start=at; depth=1 }
            } else {
                if(escaped) escaped=false
                else if(quote && c=='\\') escaped=true
                else if(c=='"') quote=!quote
                else if(!quote) {
                    if(c=='{') depth++
                    if(c=='}') {
                        depth--
                        if(depth==0) { result+=Span(start,at+1); start=-1 }
                    }
                }
            }
            at++
        }
        if(start>=0) result+=Span(start,text.length)
        return result
    }

    fun parse(raw: String): Envelope? {
        val all=objects(raw)
        val spans=all.filter { span ->
            // Nested JSON examples are not decisions; a control key must be at the root.
            rootActionKey(raw.substring(span.start,span.end))
        }
        if(spans.isEmpty()) return null
        if(spans.size!=all.size) fail("操作混有其他 JSON 对象")
        if(spans.size>4) fail("一次最多四个动作")
        val first=spans.first(); val last=spans.last()
        val prefix=raw.take(first.start).trim(); val suffix=raw.substring(last.end).trim()
        val bare=spans.size==1 && prefix in setOf("","```json","```") && suffix in setOf("","```")
        // Compatibility envelopes must be terminal: don't execute quoted explanations.
        if(suffix !in setOf("","```")) fail("操作后存在多余内容")
        val calls=JSONArray()
        for((index,span) in spans.withIndex()) {
            val obj=objectValue(raw.substring(span.start,span.end))
            if(obj.keys().asSequence().toSet()!=setOf("mailpilot_action","arguments")) fail("动作字段不匹配")
            val name=obj.opt("mailpilot_action") as? String ?: fail("动作名缺失")
            val args=obj.optJSONObject("arguments") ?: fail("参数必须是对象")
            calls.put(JSONObject().put("id","action_"+stableId(raw).take(20)+"_$index").put("type","function")
                .put("function",JSONObject().put("name",name).put("arguments",args.toString())))
        }
        return Envelope(calls,bare)
    }

    private fun rootActionKey(text: String): Boolean {
        var depth=0; var at=0
        while(at<text.length) {
            when(text[at]) {
                '{','[' -> depth++
                '}',']' -> depth--
                '"' -> {
                    val begin=at++; var escape=false
                    while(at<text.length) {
                        val c=text[at]
                        if(escape) escape=false else if(c=='\\') escape=true else if(c=='"') break
                        at++
                    }
                    var previous=begin-1; while(previous>=0 && text[previous].isWhitespace()) previous--
                    if(depth==1 && previous>=0 && text[previous] in "{," && text.substring(begin,(at+1).coerceAtMost(text.length))=="\"mailpilot_action\"") return true
                }
            }
            at++
        }
        return false
    }
}
