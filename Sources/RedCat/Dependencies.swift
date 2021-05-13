//
//  Environment.swift
//  
//
//  Created by Markus Pfeifer on 05.05.21.
//

import Foundation


public protocol Configuration {
    
    associatedtype Value
    static func value(given: Dependencies) -> Value
    
}


public protocol Dependency : Configuration where StaticValue == Value {
    associatedtype StaticValue
    static var defaultValue : StaticValue {get}
}


public extension Dependency {
    static func value(given: Dependencies) -> Value {
        defaultValue
    }
}


public struct Dependencies {
    
    @usableFromInline
    var dict : [String : Any]
    
    @inlinable
    public subscript<Key : Configuration>(key: Key.Type) -> Key.Value {
        get {
            dict[String(describing: key)] as? Key.Value ?? Key.value(given: self)
        }
        set {
            dict[String(describing: key)] = newValue
        }
    }
    
}


public struct Bind {
    
    let update : (inout Dependencies) -> Void
    
    public init<Value>(_ keyPath: WritableKeyPath<Dependencies, Value>, to value: Value) {
        self.update = {env in env[keyPath: keyPath] = value}
    }
    
    public init<GivenValue>(given: KeyPath<Dependencies, GivenValue>,
                            _ update: @escaping (GivenValue) -> Bind) {
        self.update = {env in update(env[keyPath: given]).update(&env)}
    }
    
    public init(_ transform: @escaping (Dependencies) -> Bind) {
        self.update = {env in transform(env).update(&env)}
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
