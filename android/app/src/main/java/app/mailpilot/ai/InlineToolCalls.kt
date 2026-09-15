package app.mailpilot.ai

import app.mailpilot.data.stableId
import org.json.JSONArray
import org.json.JSONObject

/** Compatibility for leaked tool envelopes in assistant content, not an XML interpreter.
 * Only a terminal, complete envelope outside Markdown code is executable. The registry still
 * validates every capability and argument before any operation. No entity/DTD resolution.
 */
object InlineToolCalls {
    // Dialects describe framing only. Capabilities, schemas and execution stay in AgentActions.
    private data class Dialect(val prefix: String,val container: String,val function: String,
        val openers: List<String> = listOf("<$prefix$container>")) {
        val close="</$prefix$container>"
    }
    private const val optionalSpace='\u0001'
    private val seedOpeners=listOf("<seed:tool_call>","seed:tool_call>","seed:tool_call")
    private val dsmlMarkers=listOf("｜DSML｜","｜｜DSML｜｜","|DSML|","||DSML||")
    private val dialects=listOf(Dialect("","seed:tool_call","function",seedOpeners)) +
        dsmlMarkers.flatMap { marker -> listOf("tool_calls","function_calls","calls").map {
            Dialect(marker+optionalSpace,it,"invoke")
        } }
    // Recognize the namespace even when a container is incomplete or unsupported: don't leak it.
    private val controlOpeners=seedOpeners+dsmlMarkers.map { "<$it" }
    private const val maxSize=128_000
    // Android ICU does not support Java's (?U) flag. Match Unicode separators explicitly.
    private val attribute=Regex("""[\s\p{Z}]+([a-z_]+)[\s\p{Z}]*=[\s\p{Z}]*(?:"([^"]*)"|'([^']*)')""")
    private val identifier=Regex("[A-Za-z_][A-Za-z0-9_]*")
    private val entity=Regex("&(?:#|[A-Za-z]+;)")
    private fun fail(): Nothing=throw ModelFailure(FailureInfo("action_format","模型返回的工具调用不完整或不兼容，未执行该操作；请重试本轮。",
        diagnostics=JSONObject().put("stage","action_validation").put("protocol","inline_tool").put("reason","工具封套不完整或不兼容")))

    private fun Char.wireSpace()=isWhitespace() || Character.isSpaceChar(this)

    // Decode Markdown escapes only in control tokens, never in user/search argument values.
    private fun tokenEnd(text: String,at: Int,token: String,partial: Boolean=false): Int? {
        var cursor=at
        for(c in token) {
            if(c==optionalSpace) { while(cursor<text.length && text[cursor].wireSpace()) cursor++; continue }
            if(cursor==text.length) return if(partial && cursor>at) cursor else null
            if(text[cursor]=='\\' && c in "<_>") cursor++
            if(cursor==text.length) return if(partial) cursor else null
            if(text[cursor++]!=c) return null
        }
        return cursor
    }

    private fun findToken(text: String,from: Int,token: String): Pair<Int,Int>? {
        var cursor=from
        while(cursor<text.length) {
            val next=text.indexOf('<',cursor); if(next<0) return null
            val begin=if(next>from && text[next-1]=='\\') next-1 else next
            tokenEnd(text,begin,token)?.let { return begin to it }
            cursor=next+1
        }
        return null
    }

    private fun start(text: String,partial: Boolean=false): Int? {
        var i=0; var codeChar=' '; var codeLength=0; var quoted=false
        while(i<text.length) {
            val ch=text[i]
            if(codeLength==0) {
                // Do not interpret protocol examples inside JSON or quoted prose.
                if(quoted && ch=='\\') { i+=2; continue }
                if(ch=='"') { quoted=!quoted; i++; continue }
                if(quoted) { i++; continue }
            }
            if(codeLength==0 && (i==0 || text[i-1]=='\n')) {
                var line=i
                while(line<text.length && text[line]==' ') line++
                // Quoted examples are reference text, not executable decisions.
                if(line<text.length && text[line]=='>') {
                    i=text.indexOf('\n',line).let { if(it<0) text.length else it+1 }
                    continue
                }
            }
            if(ch=='`' || (ch=='~' && (i==0 || text[i-1]=='\n'))) {
                var n=1; while(i+n<text.length && text[i+n]==ch) n++
                if(codeLength==0 && (ch=='`' || n>=3)) { codeChar=ch; codeLength=n }
                else if(ch==codeChar && n==codeLength) codeLength=0
                i+=n; continue
            }
            if(codeLength==0 && ch in "<\\s") {
                val boundary=i==0 || !(text[i-1].isLetterOrDigit() || text[i-1]=='_' || text[i-1]=='\\')
                for(opener in controlOpeners) {
                    if(opener[0]!='<' && !boundary) continue
                    if(tokenEnd(text,i,opener,partial)!=null) return i
                }
            }
            i++
        }
        return null
    }

    /** Keep a possible opener across SSE fragments; never release half a control token. */
    fun streaming(text: String): String=start(text,true)?.let { text.take(it) } ?: text

    private fun controlStart(text: String): Int? = start(text) ?: start(text,true)?.takeIf {
        val tail=text.substring(it).removePrefix("\\")
        tail.startsWith("<seed:") || tail.startsWith("seed:") || tail.startsWith("<｜") || tail.startsWith("<|")
    }

    /** Flush ordinary trailing punctuation, while keeping incomplete control namespaces hidden. */
    fun displayOnly(text: String): String=controlStart(text)?.let { text.take(it) } ?: text

    /** Old stored answers are display-only: never execute them or claim a search happened. */
    fun readable(text: String): String=controlStart(text)?.let {
        text.take(it).trimEnd().let { prefix ->
            listOf(prefix,"这条历史回答包含未处理的工具调用，不能据此确认已完成检索；请重试原问题。")
                .filter(String::isNotBlank).joinToString("\n\n")
        }
    } ?: text

    fun parse(text: String): JSONArray? {
        val first=controlStart(text) ?: return null
        val wire=text.substring(first)
        if(wire.length>maxSize) fail()
        val calls=JSONArray(); val idPrefix="inline_"+stableId(wire).take(16)+"_"; var offset=0
        while(offset<wire.length) {
            while(offset<wire.length && wire[offset].wireSpace()) offset++
            if(offset==wire.length) break
            val (dialect,bodyStart)=dialects.firstNotNullOfOrNull { dialect ->
                dialect.openers.firstNotNullOfOrNull { tokenEnd(wire,offset,it) }?.let { dialect to it }
            } ?: fail()
            val (end,after)=findToken(wire,bodyStart,dialect.close) ?: fail()
            val reader=Reader(wire.substring(bodyStart,end))
            while(!reader.finished()) {
                if(calls.length()>=4) fail()
                val function=reader.tag(dialect.prefix+dialect.function,setOf("name"))
                val name=function["name"]?.takeIf { identifier.matches(it) } ?: fail()
                val args=JSONObject()
                while(!reader.consume("</${dialect.prefix}${dialect.function}>")) {
                    if(args.length()>=32) fail()
                    val parameter=reader.tag(dialect.prefix+"parameter",setOf("name","string"))
                    val key=parameter["name"]?.takeIf { identifier.matches(it) } ?: fail()
                    if(args.has(key)) fail()
                    val value=reader.value("</${dialect.prefix}parameter>")
                    val string=parameter["string"] ?: "true"
                    args.put(key,when(string) {
                        "true" -> value
                        "false" -> ActionJson.value(value)
                        else -> fail()
                    })
                }
                calls.put(JSONObject().put("id",idPrefix+calls.length())
                    .put("type","function").put("function",JSONObject().put("name",name).put("arguments",args.toString())))
            }
            offset=after
        }
        if(calls.length()==0) fail()
        return calls
    }

    fun sameValue(a: Any?,b: Any?,depth: Int=0): Boolean {
        if(depth>16) return false
        if(a is JSONObject && b is JSONObject) {
            val keys=a.keys().asSequence().toSet()
            return keys==b.keys().asSequence().toSet() && keys.all { sameValue(a.opt(it),b.opt(it),depth+1) }
        }
        if(a is JSONArray && b is JSONArray) return a.length()==b.length() && (0 until a.length()).all { sameValue(a.opt(it),b.opt(it),depth+1) }
        return a==b
    }

    private class Reader(private val text: String) {
        private var at=0
        private fun space() { while(at<text.length && text[at].wireSpace()) at++ }
        fun finished(): Boolean { space(); return at==text.length }
        fun consume(token: String): Boolean {
            space(); at=tokenEnd(text,at,token) ?: return false
            return true
        }
        fun tag(name: String,allowed: Set<String>): Map<String,String> {
            space(); at=tokenEnd(text,at,"<$name") ?: fail()
            val attrs=mutableMapOf<String,String>()
            while(true) {
                val match=attribute.find(text,at)?.takeIf { it.range.first==at } ?: break
                val key=match.groupValues[1]
                if(key !in allowed || attrs.containsKey(key)) fail()
                val value=match.groups[2]?.value ?: match.groups[3]!!.value
                attrs[key]=if(key=="name") value.replace("\\_","_") else value
                at=match.range.last+1
            }
            space(); at=tokenEnd(text,at,">") ?: fail()
            return attrs
        }
        fun value(end: String): String {
            val (until,after)=findToken(text,at,end) ?: fail()
            val value=text.substring(at,until)
            // Reject markup, declarations and entities rather than expanding untrusted XML.
            if(value.contains('<') || entity.containsMatchIn(value)) fail()
            at=after; return value
        }
    }
}
