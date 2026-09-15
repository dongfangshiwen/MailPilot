package app.mailpilot

import app.mailpilot.mail.CompatibleImapSearch
import jakarta.mail.Message
import jakarta.mail.MessagingException
import jakarta.mail.Session
import jakarta.mail.internet.MimeMessage
import jakarta.mail.search.*
import org.eclipse.angus.mail.iap.BadCommandException
import org.junit.Assert.*
import org.junit.Test
import java.util.Properties

class CompatibleImapSearchTest {
    private fun mail(number: Int): Message = object : MimeMessage(Session.getInstance(Properties())) {
        override fun getMessageNumber() = number
    }
    @Test fun rejectedOrFallsBackToUnionAndRemembersCompatibility() {
        val a=SubjectTerm("a"); val b=SubjectTerm("b")
        var rejects=0
        val query=CompatibleImapSearch { term ->
            when(term) {
                is OrTerm -> { rejects++; throw MessagingException("SEARCH failed",BadCommandException("A7 BAD invalid command or parameters")) }
                a -> arrayOf(mail(1),mail(2))
                b -> arrayOf(mail(2),mail(3))
                else -> error("Unexpected query")
            }
        }
        repeat(2) { assertEquals(listOf(1,2,3),query.find(OrTerm(a,b)).map { it.messageNumber }) }
        assertEquals(1,rejects)
    }
    @Test fun nestedAndPreservesIntersectionAndEmptyResults() {
        val a=SubjectTerm("a"); val b=SubjectTerm("b"); val c=SubjectTerm("c")
        val query=CompatibleImapSearch { term -> when(term) {
            is AndTerm,is OrTerm -> throw MessagingException("A1 BAD invalid command or parameters")
            a -> arrayOf(mail(1),mail(2))
            b -> arrayOf(mail(2),mail(3))
            else -> emptyArray()
        } }
        assertEquals(listOf(2),query.find(AndTerm(a,b)).map { it.messageNumber })
        assertTrue(query.find(AndTerm(OrTerm(a,b),c)).isEmpty())
    }
    @Test fun doesNotHideNetworkOrLeafSyntaxFailures() {
        val a=SubjectTerm("a"); val b=SubjectTerm("b")
        for(error in listOf(MessagingException("connection timed out"),MessagingException("NO permission denied"))) {
            var calls=0
            val query=CompatibleImapSearch { calls++; throw error }
            assertSame(error,runCatching { query.find(OrTerm(a,b)) }.exceptionOrNull())
            assertEquals(1,calls)
        }
        val error=MessagingException("A2 BAD invalid date")
        assertSame(error,runCatching { CompatibleImapSearch { throw error }.find(a) }.exceptionOrNull())
    }
}
