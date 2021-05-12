//
//  Environment.swift
//  
//
//  Created by Markus Pfeifer on 05.05.21.
//

import Foundation


public protocol Dependency {
    
    associatedtype Value
    static var defaultValue : Value {get}
    
}


public struct Dependencies {
    
    @usableFromInline
    var dict : [String : Any]
    
    @inlinable
    public subscript<Key : Dependency>(key: Key.Type) -> Key.Value {
        get {
            dict[String(describing: key)] as? Key.Value ?? Key.defaultValue
        }
        set {
            dict[String(describing: key)] = newValue
        }
    }
    
}


public struct Bind {
    
    let update : (inout Dependencies) -> Void
    
    init<Value>(_ keyPath: WritableKeyPath<Dependencies, Value>, to value: Value) {
        update = {env in env[keyPath: keyPath] = value}
    }
    
}


extension Dependencies : ExpressibleByArrayLiteral {
    
    public init(arrayLiteral elements: Bind...) {
        dict = [:]
        for elm in elements {
            elm.update(&self)
        }
    }
    
}
