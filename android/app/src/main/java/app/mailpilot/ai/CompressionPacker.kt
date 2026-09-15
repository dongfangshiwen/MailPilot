package app.mailpilot.ai

import org.json.JSONArray

data class SourceCursor(val block: Int=0,val offset: Int=0)
data class CompressionBatch(val text: String,val end: SourceCursor)

/** Lossless source positions; boundaries adapt to the complete request and rolling summary. */
object CompressionPacker {
    fun pack(blocks: List<String>,start: SourceCursor,budget: Int,messages: (String)->JSONArray): CompressionBatch {
        var block=start.block; var offset=start.offset; val text=StringBuilder()
        fun fits(value: String)=ContextBudgetPlanner.estimate(messages(value))<=budget
        while(block<blocks.size) {
            val source=blocks[block]
            require(offset in 0..source.length) { "整理进度已失效，请重新计算" }
            if(offset==source.length) { block++; offset=0; continue }
            val heading=source.substringBefore('\n').takeIf { offset>0 && it.length<=100 }.orEmpty()
            val prefix=(if(text.isEmpty()) "" else "\n\n")+(if(heading.isEmpty()) "" else "$heading（续）\n")
            val base=text.toString()+prefix
            var low=0; var high=source.length-offset
            while(low<high) {
                val middle=low+(high-low+1)/2
                if(fits(base+source.substring(offset,offset+middle))) low=middle else high=middle-1
            }
            var count=low
            if(offset+count<source.length && count>0 && source[offset+count-1].isHighSurrogate()) count--
            if(count==0) break
            if(offset+count<source.length) {
                val newline=source.lastIndexOf('\n',offset+count-1)
                if(newline>=offset+count/2) count=newline+1-offset
            }
            text.append(prefix).append(source,offset,offset+count); offset+=count
            if(offset<source.length) break
            block++; offset=0
        }
        return CompressionBatch(text.toString(),SourceCursor(block,offset))
    }
}
