//
//  TrieNodeTests.swift
//  Linchi
//

import XCTest
@testable import Linchi

class TrieNodeTests : XCTestCase {

    var dumbRequest = HTTPRequest.init(method: .GET, url: "/", headers: [:], body: "", methodParameters: [:], urlParameters: [:])

    func createRW(pattern: String) -> ResponseWriter {
        return { request in
            return HTTPResponse.init(status: .OK, headers: [:], body: pattern.toUTF8Bytes())
        }
    }
    
    func readRW(rw: ResponseWriter?) -> String {
        guard let body = rw?(dumbRequest).body else { return "{{{no response writer}}}"}
        return String.fromUTF8Bytes(body)
    }
    
    override func setUp() {
        super.setUp()
    }
    
    func test() {

        let tests : [String: (match: [String], dontmatch: [String]) ] = [
            
            "hello": (["/hello", "hello", "/hello/"], ["hellol", "", "Hello"]),
            
            "hello/world": (["/hello/world/", "hello/world"], ["hello/", "hello/worl", "hello/world/won"]),
            
            "/": (["", "/"], ["anythingelsereally", "/a"]),
            
            "world": (["world"], ["hello", "/hello", "/", "", "world/world"]),
            
            "hello/world/no/more/ideas": (["hello/world/no/more/ideas/"], ["hello/world/no/more/ideas/long", "hello/world/no/more/", "hello/world/more/ideas", "hello/world/yes/more/ideas"]),
            
            "∆: digits=[0-9]+": (["6", "893", "/012"], ["23hk", "23/ab", "/", "hk23"]),
            
            "/hello/∆: name=[a-z]+": (["hello/loic", "hello/hello"], ["hello/world", "world/loic", "hello/43"]),
            
            "/new/∆: page=[0-9]+/profile": (["new/2/profile"], ["new/2l/profile", "/2/profile", "new/profile", "/"]),
            
            "∆: digits=[0-9]+/∆: name=[a-zA-Z]+/∆: AorB=[ab]" : (["6/loic/a", "34/Elodie/b"], [""])
        ]
        
        var trie = URLTrieNode()
        
        var i : UInt8 = 0
        for (key, _) in tests {
            trie.add(URLPattern(str: key)!, responseWriter: createRW(key))
            i++
        }
        
        for (key, value) in tests {
            
            let (match, dontmatch) = value

            for x in match {
                XCTAssertEqual(readRW(trie.find(x)?.rw), key)
            }
            
            for x in dontmatch {
                XCTAssertNotEqual(readRW(trie.find(x)?.rw), key)
            }
        }
        
        
    
    }
}




