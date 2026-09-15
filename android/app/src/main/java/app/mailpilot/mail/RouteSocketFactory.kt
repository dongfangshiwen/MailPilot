package app.mailpilot.mail

import java.io.IOException
import java.net.*
import java.util.concurrent.*
import javax.net.SocketFactory

/** Resolve a working address without handing a delegated socket to Android's
 * descriptor-based TLS provider. Angus still verifies the original TLS hostname. */
internal class RouteSocketFactory(
    private val resolve: (String) -> Array<InetAddress> = InetAddress::getAllByName,
    private val probe: (Socket,InetSocketAddress,Int)->Unit = { socket,address,timeout -> socket.connect(address,timeout) }
) : SocketFactory() {
    override fun createSocket(): Socket = RouteSocket(resolve,probe)
    override fun createSocket(host: String,port: Int): Socket = createSocket().apply { connect(InetSocketAddress(host,port),15000) }
    override fun createSocket(host: InetAddress,port: Int): Socket = createSocket(host.hostAddress!!,port)
    override fun createSocket(host: String,port: Int,local: InetAddress,localPort: Int): Socket = createSocket().apply { bind(InetSocketAddress(local,localPort)); connect(InetSocketAddress(host,port),15000) }
    override fun createSocket(host: InetAddress,port: Int,local: InetAddress,localPort: Int): Socket = createSocket(host.hostAddress!!,port,local,localPort)
}

private class RouteSocket(
    private val resolve: (String)->Array<InetAddress>,
    private val probe: (Socket,InetSocketAddress,Int)->Unit
) : Socket() {
    private val probes=ConcurrentHashMap.newKeySet<Socket>()
    override fun connect(endpoint: SocketAddress)=connect(endpoint,15000)
    override fun connect(endpoint: SocketAddress,timeout: Int) {
        if(isClosed) throw SocketException("Socket closed")
        val address=endpoint as? InetSocketAddress ?: throw SocketException("Unsupported address")
        val found=resolve(address.hostString).distinct()
        if(found.isEmpty()) throw UnknownHostException(address.hostString)
        val limit=if(timeout>0) timeout else 15000
        if(found.size==1) { super.connect(InetSocketAddress(found.single(),address.port),limit); return }
        val deadline=System.nanoTime()+TimeUnit.MILLISECONDS.toNanos(limit.toLong())
        val first=found.filter { (it is Inet6Address)==(found.first() is Inet6Address) }
        val second=found.filter { (it is Inet6Address)!=(found.first() is Inet6Address) }
        val routes=(0 until maxOf(first.size,second.size)).flatMap { listOfNotNull(first.getOrNull(it),second.getOrNull(it)) }
        val pool=Executors.newFixedThreadPool(minOf(routes.size,4)) { r -> Thread(r,"mail-route").apply { isDaemon=true } }
        val completion=ExecutorCompletionService<InetAddress>(pool)
        val tasks=routes.mapIndexed { i,ip -> completion.submit(Callable {
            val socket=Socket(); probes.add(socket)
            try {
                if(i>0) Thread.sleep(minOf(i*250L,1000))
                if(isClosed || Thread.currentThread().isInterrupted) throw SocketException("Socket closed")
                val remaining=TimeUnit.NANOSECONDS.toMillis(deadline-System.nanoTime()).toInt()
                if(remaining<=0) throw SocketTimeoutException("Connection timed out")
                probe(socket,InetSocketAddress(ip,address.port),remaining)
                ip
            } finally { runCatching { socket.close() }; probes.remove(socket) }
        }) }
        var chosen: InetAddress?=null; var last: Throwable?=null
        try {
            for(i in routes.indices) {
                val remaining=deadline-System.nanoTime()
                if(remaining<=0) break
                val done=completion.poll(remaining,TimeUnit.NANOSECONDS) ?: break
                try { chosen=done.get(); break } catch(e: ExecutionException) { last=e.cause }
            }
        } catch(e: InterruptedException) {
            Thread.currentThread().interrupt(); throw java.io.InterruptedIOException("邮箱连接已取消")
        } finally {
            tasks.forEach { it.cancel(true) }; pool.shutdownNow()
            probes.forEach { runCatching { it.close() } }; probes.clear()
        }
        val route=chosen ?: throw (last as? IOException ?: SocketTimeoutException("邮箱服务器连接超时"))
        val remaining=TimeUnit.NANOSECONDS.toMillis(deadline-System.nanoTime()).toInt()
        if(remaining<=0) throw SocketTimeoutException("邮箱服务器连接超时")
        // Connect this Socket's own descriptor. Delegating streams to a separate
        // Socket works on desktop JSSE but fails on Android 8 Conscrypt.
        super.connect(InetSocketAddress(route,address.port),remaining)
    }
    override fun close() {
        super.close()
        probes.forEach { runCatching { it.close() } }; probes.clear()
    }
}
