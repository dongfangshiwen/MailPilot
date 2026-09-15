package app.mailpilot.mail

import jakarta.mail.Message
import jakarta.mail.MessagingException
import jakarta.mail.FolderClosedException
import jakarta.mail.StoreClosedException
import jakarta.mail.search.AndTerm
import jakarta.mail.search.OrTerm
import jakarta.mail.search.SearchTerm
import org.eclipse.angus.mail.iap.BadCommandException

/** Some IMAP servers accept individual criteria but reject standard boolean SEARCH.
 * Split only an explicit BAD response; connection/authentication failures still fail.
 * Message numbers are scoped to the open folder and are never stored as UID cursors. */
internal class CompatibleImapSearch(private val search: (SearchTerm) -> Array<Message>) {
    private var splitBoolean = false

    fun find(term: SearchTerm): Array<Message> {
        val compound = term is OrTerm || term is AndTerm
        if (!splitBoolean || !compound) {
            try { return search(term) }
            catch (e: MessagingException) {
                if (!compound || e is FolderClosedException || e is StoreClosedException || !isBadCommand(e)) throw e
                splitBoolean = true
            }
        }
        return when (term) {
            is OrTerm -> term.terms.flatMap { find(it).asList() }.distinctBy { it.messageNumber }.toTypedArray()
            is AndTerm -> {
                val groups = term.terms.map { find(it).asList() }
                val common = groups.map { group -> group.map { it.messageNumber }.toSet() }.reduce { a, b -> a intersect b }
                groups.first().filter { it.messageNumber in common }.toTypedArray()
            }
            else -> error("Only boolean search expressions can be split")
        }
    }

    private fun isBadCommand(error: Throwable): Boolean =
        generateSequence(error) { it.cause }.take(12).any {
            it is BadCommandException || Regex("(?:^|\\s)BAD(?:\\s|$)").containsMatchIn(it.message.orEmpty())
        }
}
