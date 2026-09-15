package app.mailpilot.data

/** Append-only versions. An edited question replaces its old branch in context,
 * while the full original history and SMTP audit remain in Room. */
object ChatBranch {
    fun root(entry: ChatEntry, rows: List<ChatEntry>): String {
        var current=entry; val seen=mutableSetOf<String>()
        while(current.action=="edit_user" && seen.add(current.id)) {
            current=rows.firstOrNull { it.id==current.targetAnswerId && it.role=="user" } ?: break
        }
        return current.id
    }
    fun active(rows: List<ChatEntry>): List<ChatEntry> {
        val active=mutableListOf<ChatEntry>()
        rows.forEach { entry ->
            if(entry.role=="user" && entry.action=="edit_user") {
                val root=root(entry,rows)
                val index=active.indexOfFirst { it.role=="user" && root(it,rows)==root }
                if(index>=0) active.subList(index,active.size).clear()
            }
            active+=entry
        }
        return active
    }
    fun replies(entry: ChatEntry,rows: List<ChatEntry>): List<ChatEntry> {
        val index=rows.indexOfFirst { it.id==entry.id && it.role=="user" }
        return if(index<0) emptyList() else rows.drop(index+1).takeWhile { it.role!="user" }
    }
    fun versions(entry: ChatEntry,rows: List<ChatEntry>)=rows.filter { it.role=="user" && root(it,rows)==root(entry,rows) }
}
