//
//  URLTrieNode.swift
//  Linchi
//

struct URLTrieNode {

    typealias ParamsIndex = Int
    typealias TextsIndex = Dictionary<String, URLTrieNode>.Index
    
    private var responseWriter : ResponseWriter?
    private var texts : [String : URLTrieNode]
    private var params: [(name: String, regex: RegEx, child: URLTrieNode)]
    
    /// Creates an empty URLTrieNode
    init() {
        self.responseWriter = nil
        self.texts = [:]
        self.params = []
    }
    
    /// Index type for accessing a child of `self`
    private enum Index {
        case InTexts(idx: TextsIndex, key: String)
        case InParams(ParamsIndex)
    }

    private subscript(idx: URLTrieNode.Index) -> URLTrieNode {
        get {
            switch idx {
            case .InTexts(let textsIdx, _): return texts[textsIdx].1
            case .InParams(let paramsIdx) : return params[paramsIdx].child
            }
        }
        set {
            switch idx {
            case .InTexts(_, let key)    : texts[key] = newValue
            case .InParams(let paramsIdx): params[paramsIdx].child = newValue
            }
        }
    }

    /**
    Returns the index of the child that matches the given string,
    with a preference for an exact match over one that uses a regex.
    Returns nil if no match was found.
    */
    private func indexThatMatches(string: String) -> URLTrieNode.Index? {

        if let dicIdx = texts.indexForKey(string) {
            return URLTrieNode.Index.InTexts(idx: dicIdx, key: string)
        }
        
        if let arrIdx = params.indexOf({ $0.regex.matches(string) }) {
            return .InParams(arrIdx)
        }

        return nil
    }
    
    /**
    Returns the index of the child associated with the given URLPatternElement,
    or nil if there is no such child.
    */
    private func indexOfPatternElement(element: URLPatternElement) -> URLTrieNode.Index? {

        switch element {
        case .Text(let string):
            guard let textsIndex = texts.indexForKey(string) else { return nil }
            return .InTexts(idx: textsIndex, key: string)

        case .Parameter(_, let regex):
            guard let paramsIdx = params.indexOf({$0.regex.pattern == regex.pattern}) else { return nil }
            return .InParams(paramsIdx)
        }
    }

    /**
    Adds an empty child to `self`, associate it with the given URLPatternElement, and
    returns the index of the child.
    */
    private mutating func addPatternElement(element: URLPatternElement) -> URLTrieNode.Index {
        
        switch element {
        
        case .Text(let string):
            texts[string] = URLTrieNode()
            return .InTexts(idx: texts.indexForKey(string)!, key: string)
        
        case .Parameter(let name, let regex):
            params.append((name, regex, URLTrieNode()))
            return .InParams(params.endIndex.predecessor())
        }
    }

    /** 
    Returns the response writer and parameters associated with the URLPattern that matches the url,
    or nil if no pattern matches the url
    */
    func find(url: String) -> (rw: ResponseWriter, urlParameters: [String: String])? {

        let beforeInterrogationMark = url.splitOnce("?")?.0 ?? url
        let split = beforeInterrogationMark.split("/")

        var urlParameters = [String: String]()
        var gen = split.generate()

        func findRecursively(trie: URLTrieNode) -> ResponseWriter? {
            
            guard let urlComponent = gen.next() else { return trie.responseWriter }
            guard let index = trie.indexThatMatches(urlComponent) else { return nil }
            
            if case .InParams(let paramsIdx) = index {
                urlParameters[trie.params[paramsIdx].name] = urlComponent
            }
            
            return findRecursively(trie[index])
        }
        
        guard let rw = findRecursively(self) else { return nil }
        
        return (rw, urlParameters)
    }
    
    /// Associates a ResponseWriter to a URLPattern
    mutating func add(pattern: URLPattern, responseWriter: ResponseWriter) {

        var gen = pattern.generate()

        func traverseThenCreateBranch(inout node: URLTrieNode) {
            
            guard let patternElement = gen.next() else { return createBranch(&node) }

            guard let index = node.indexOfPatternElement(patternElement) else {
                let newIndex = node.addPatternElement(patternElement)
                return createBranch(&node[newIndex])
            }

            traverseThenCreateBranch(&node[index])
        }

        func createBranch(inout node: URLTrieNode) {
            guard let patternElement = gen.next() else { return node.responseWriter = responseWriter }

            let newIndex = node.addPatternElement(patternElement)
            createBranch(&node[newIndex])
        }

        return traverseThenCreateBranch(&self)
    }
    
}
