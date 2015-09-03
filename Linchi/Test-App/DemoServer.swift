//
//  DemoServer.swift
//  Linchi
//

import Darwin

let DEMO_SERVER = DemoServer()

class DemoServer : HTTPServer {
    
    let basePath : String
    var fileCache : FileCache

    override init() {
        
        self.basePath = "\(PROJECT_DIR)/"
        self.fileCache = FileCache()
        
        super.init()

        try! fileCache.addFilesInDirectory(basePath + "static/", url: "static/")
        self.addCachedFiles(fileCache)
        
        guard let page404 = fileCache["static/404.html"] else { fatalError() }
        self.defaultResponseWriters.notFound = BasicResponseWriters.sendData(page404)

        router.add(.GET, "/", handler: HomePage.getMainPage)
        router.add(.GET, "/hello/∆: greeter=\(RegEx.CharClass.Printable)+", handler: HomePage.greetFriend)
        router.add(.POST, "/hello/∆: greeter=\(RegEx.CharClass.Printable)+", handler: HomePage.greetFriend)
    }
    
}

