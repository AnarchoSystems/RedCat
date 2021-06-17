//
//  EnvironmentWrapper.swift
//  
//
//  Created by Markus Pfeifer on 17.06.21.
//

fileprivate protocol Reader {
    func readValue(from environment: Dependencies)
}

@propertyWrapper
public struct Injected<Value> : Reader {
    
    @inlinable
    public var wrappedValue : Value {
        _wrappedValue.value
    }
    @usableFromInline
    var _wrappedValue : Box
    private let _read : (Dependencies) -> Value
    
    public init(_ read: @escaping (Dependencies) -> Value) {
        self._read = read
        self._wrappedValue = Box(value: read(Dependencies()))
    }
    
    func readValue(from environment: Dependencies) {
        _wrappedValue.value = _read(environment)
    }
 
    @usableFromInline
    internal final class Box {
        @usableFromInline
        var value : Value
        init(value: Value) {self.value = value}
    }
    
}


public func inject(environment: Dependencies, to object: Any) {
    
    let mirror = Mirror(reflecting: object)
    
    var children = Array(mirror.children)
    
    while !children.isEmpty {
        let (_, child) = children.removeLast()
        if let reader = child as? Reader {
            reader.readValue(from: environment)
        }
        else {
            children.append(contentsOf: Mirror(reflecting: child).children)
        }
    }
    
}
