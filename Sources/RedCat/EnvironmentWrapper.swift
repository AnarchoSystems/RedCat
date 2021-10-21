//
//  EnvironmentWrapper.swift
//  
//
//  Created by Markus Pfeifer on 17.06.21.
//

fileprivate protocol Reader {
    func readValue(from environment: Any)
}

@propertyWrapper
public struct _Lens<Whole, Value> : Reader {
    
    @inlinable
    public var wrappedValue : Value {
        _wrappedValue.value!
    }
    @usableFromInline
    var _wrappedValue : Box
    private let _read : (Whole) -> Value
    
    public init(_ read: @escaping (Whole) -> Value) {
        self._read = read
        self._wrappedValue = Box()
    }
    
    func readValue(from environment: Any) {
        _wrappedValue.value = _read(environment as! Whole)
    }
 
    @usableFromInline
    internal final class Box {
        @usableFromInline
        var value : Value?
    }
    
}

public typealias Injected<Value> = _Lens<Dependencies, Value>

public func inject<Whole>(environment: Whole, to object: Any) {
    
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
