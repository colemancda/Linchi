//
//  ActiveSocket.swift
//  Linchi
//

import Darwin

/// “An active socket is connected to a remote active socket via an open data connection”
internal struct ActiveSocket : Socket {
    
    /// File Descriptor
    let fd : CInt
    
    init(_ fd: CInt) {
        self.fd = fd
    }

    /** 
    Initialize the active socket by extracting the first connection request on the 
    queue of pending connections of the given passive socket.
    
    Please note that it is a blocking function if no pending connections are available.
    */
    init?(fromPassiveSocket sock: PassiveSocket) {
        
        var addr = sockaddr()
        var len: socklen_t = 0
        
        self.fd = accept(sock.fd, &addr, &len)
        guard self.fd != -1 else { return nil }

        do    { try applyOptions(SocketOption.NoSigPipe) }
        catch { return nil }
    }
    
}

