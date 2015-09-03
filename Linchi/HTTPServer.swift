//
//  HTTPServer.swift
//  Linchi
//

import Darwin

// TODO: document it

public class HTTPServer {

    public var defaultResponseWriters = DefaultResponseWriters()

    public var router = URLRouter()
    private var passiveSocket = PassiveSocket.defaultInvalidSocket()

    /// Start the server at the given port (default: 8080)
    public func start(port: in_port_t = 8080) {

        passiveSocket = PassiveSocket(listeningToPort: port)!
        print("Server started.")

        while let activeSocket = try? ActiveSocket(fromPassiveSocket: passiveSocket) {
            // TODO: do this asynchronously
            self.handleSocket(activeSocket)
        }
        stop()
    }

    private func handleSocket(activeSocket: ActiveSocket) {
        
        while let message = activeSocket.nextMessage(), let request = parseRequest(message) {

            // TODO: do the entire body of the loop asynchronously
            
            // I don't like the keepAlive constant. Would be nice to find an other way to deal with it.
            // For now, it is always false because keeping alive a connection without
            // having implemented concurrency can block other connections.
            let keepAlive = false //request.headers["connection"] == "keep-alive"

            let cleanUrl = request.url.newByReplacingPlusesBySpaces().newByRemovingPercentEncoding()
            
            guard let (writeResponse, params) = router.find(request.method, url: cleanUrl) else {
                activeSocket.respond(defaultResponseWriters.notFound(request), keepAlive: keepAlive)
                if keepAlive { continue } else { break }
            }

            let updatedRequest = HTTPRequest(
                method           : request.method,
                url              : request.url,
                headers          : request.headers,
                body             : request.body,
                methodParameters : request.methodParameters,
                urlParameters    : params
            )

            activeSocket.respond(writeResponse(updatedRequest), keepAlive: keepAlive)

            if !keepAlive { break }
        }

        activeSocket.release()
    }

    /// Add the files in the cache to the url router of the server
    func addCachedFiles(cache: FileCache) {
        for (url, data) in cache {
            router.add(.GET, url, handler: BasicResponseWriters.sendData(data))
        }
    }

    public func stop() {
        passiveSocket.release()
        passiveSocket = PassiveSocket.defaultInvalidSocket()
    }
    
}



