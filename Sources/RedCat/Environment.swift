//
//  Environment.swift
//  
//
//  Created by Markus Pfeifer on 05.05.21.
//

import Foundation

public protocol OpaqueEnvironmentKey {
    static func tryWriteToEnv(_ any: Any, env: inout Environment)
}

public protocol EnvironmentKey : OpaqueEnvironmentKey {
    
    associatedtype Value
    static var defaultValue : Value{get}
    
}

public extension EnvironmentKey {
    static func tryWriteToEnv(_ any: Any, env: inout Environment) {
        guard let value = any as? Value else {
            fatalError("\(any) is not a \(String(describing: Value.self))!")
        }
        env[self] = value
    }
}

public struct Environment {
    
    @usableFromInline
    var dict : [String : Any]
    
    @inlinable
    public subscript<Key : EnvironmentKey>(key: Key.Type) -> Key.Value {
        get{
            dict[String(describing: key)] as? Key.Value ?? Key.defaultValue
        }
        set{
            dict[String(describing: key)] = newValue
        }
    }
    
}

extension Environment : ExpressibleByDictionaryLiteral {
    
    public init(dictionaryLiteral elements: (OpaqueEnvironmentKey.Type, Any)...) {
        dict = [:]
        for (key, value) in elements {
            key.tryWriteToEnv(value, env: &self)
        }
    }
    
}
