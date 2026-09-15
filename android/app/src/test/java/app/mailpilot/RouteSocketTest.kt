package app.mailpilot

import app.mailpilot.mail.RouteSocketFactory
import org.junit.Assert.*
import org.junit.Test
import java.net.*
import java.util.Collections

class RouteSocketTest {
    @Test fun unreachableFirstFamilyDoesNotBlockWorkingAddressAndLosersClose() {
        val sockets=Collections.synchronizedList(mutableListOf<Socket>())
        ServerSocket(0,1,InetAddress.getByName("127.0.0.1")).use { server ->
            server.soTimeout=3000
            val acceptor=Thread { runCatching { repeat(2) { server.accept().close() } } }.apply { isDaemon=true; start() }
            val factory=RouteSocketFactory(
                resolve={ arrayOf(InetAddress.getByName("::1"),InetAddress.getByName("127.0.0.1")) },
                probe={ socket,address,timeout ->
                    sockets.add(socket)
                    if(address.address is Inet6Address) Thread.sleep(5000)
                    socket.connect(address,timeout)
                })
            val start=System.nanoTime()
            factory.createSocket().use { socket ->
                socket.soTimeout=4321
                socket.connect(InetSocketAddress("localhost",server.localPort),2000)
                assertTrue(socket.isConnected); assertEquals(4321,socket.soTimeout)
                assertTrue((System.nanoTime()-start)/1000000<1500)
            }
            assertTrue(sockets.all { it.isClosed })
            acceptor.join(1000)
        }
    }
    @Test fun ipv6OnlyAndClosedSocketHaveExplicitOutcomes() {
        val closed=RouteSocketFactory().createSocket(); closed.close()
        assertThrows(SocketException::class.java) { closed.connect(InetSocketAddress("localhost",1)) }
        val ipv6=RouteSocketFactory(resolve={ arrayOf(InetAddress.getByName("::1")) })
        ipv6.createSocket().use { socket -> assertThrows(java.io.IOException::class.java) { socket.connect(InetSocketAddress("localhost",1),100) } }
    }
}
