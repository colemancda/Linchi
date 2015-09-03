//
//  URLRouter.swift
//  Linchi
//

// TODO: documentation

public struct URLRouter {
    
    private var tries: [HTTPMethod: URLTrieNode] = [:]

    internal func find(method: HTTPMethod, url: String) -> (ResponseWriter, [String: String])? {
        
        guard let (params, rw) = tries[method]?.find(url) else { return nil }
        
        return (params, rw)
    }

    public mutating func add(method: HTTPMethod, _ url: String, handler: ResponseWriter) {
        
        guard let pattern = URLPattern(str: url) else {
            fatalError("The url pattern ‘ \(url) ’ is not valid.")
        }
        
        if tries[method] == nil {
            tries[method] = URLTrieNode()
        }
        
        tries[method]!.add(pattern, responseWriter: handler)
    }
}

