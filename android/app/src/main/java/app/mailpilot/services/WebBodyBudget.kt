package app.mailpilot.services

import java.util.concurrent.locks.ReentrantLock
import kotlin.concurrent.withLock

/** Reservations include concurrent readers; no body read may exceed its reservation. */
internal class WebBodyBudget(private val limit: Int) {
    private val lock=ReentrantLock()
    private val changed=lock.newCondition()
    private var reserved=0
    private var consumed=0
    private var closed=false
    val used get()=lock.withLock { consumed }
    val exhausted get()=lock.withLock { consumed>=limit }
    fun reserve(maximum: Int): Int=lock.withLock {
        while(!closed && limit-consumed-reserved==0 && reserved>0) changed.await()
        if(closed) return 0
        minOf(maximum,limit-consumed-reserved).also { reserved+=it }
    }
    fun finish(allowance: Int,actual: Int) = lock.withLock {
        require(actual in 0..allowance)
        reserved-=allowance; consumed+=actual; changed.signalAll()
    }
    fun close()=lock.withLock { closed=true; changed.signalAll() }
}
