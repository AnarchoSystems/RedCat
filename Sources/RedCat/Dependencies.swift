//
//  Environment.swift
//  
//
//  Created by Markus Pfeifer on 05.05.21.
//

import Foundation


public protocol Config {
    
    associatedtype Value
    static func value(given: Dependencies) -> Value
    
}


public protocol Dependency : Config where StaticValue == Value {
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
    var dict : [String : Any] = [:]
    @usableFromInline
    var memoize : ((Bind) -> Void)?
    
    @inlinable
    public subscript<Key : Config>(key: Key.Type) -> Key.Value {
        get {
            if let result = dict[String(describing: key)] as? Key.Value {
                return result
            }
            else {
                let result = Key.value(given: self)
                memoize?(Bind(update: {$0[key] = result}))
                return result
            }
        }
        set {
            dict[String(describing: key)] = newValue
        }
    }
    
}


public struct Bind {
    
    @usableFromInline
    let update : (inout Dependencies) -> Void
    @usableFromInline
    init(update: @escaping (inout Dependencies) -> Void) {
        self.update = update
    }
    
}


public extension Bind {
    
    init<Value>(_ keyPath: WritableKeyPath<Dependencies, Value>, to value: Value) {
        self.update = {env in env[keyPath: keyPath] = value}
    }
    
    init<GivenValue>(given: KeyPath<Dependencies, GivenValue>,
                     _ update: @escaping (GivenValue) -> Bind) {
        self.update = {env in update(env[keyPath: given]).update(&env)}
    }
    
    init(_ transform: @escaping (Dependencies) -> Bind) {
        self.update = {env in transform(env).update(&env)}
    }
    
    func then(_ transform: @escaping (Dependencies) -> Bind) -> Bind {
        Bind {(env: inout Dependencies) in
            update(&env)
            transform(env).update(&env)
        }
    }
    
}


@resultBuilder
public enum EnvironmentBuilder {
    
    public static func buildBlock(_ components: Bind...) -> Bind {
        buildArray(components)
    }
    
    public static func buildEither(first component: Bind) -> Bind {
        component
    }
    
    public static func buildEither(second component: Bind) -> Bind {
        component
    }
    
    public static func buildOptional(_ component: Bind?) -> Bind {
        Bind.init {_ in }
    }
    
    public static func buildArray(_ components: [Bind]) -> Bind {
        Bind {(env: inout Dependencies) in
            for bind in components {
                bind.update(&env)
            }
        }
    }
    
    public static func buildLimitedAvailability(_ component: Bind) -> Bind {
        component
    }
    
}


extension Dependencies : ExpressibleByArrayLiteral {
    
    public init(arrayLiteral elements: Bind...) {
        for elm in elements {
            elm.update(&self)
        }
    }
    
}


public extension Dependencies {
    
    init(@EnvironmentBuilder content: () -> Bind) {
        content().update(&self)
    }
    
    init(@EnvironmentBuilder content: (Dependencies) -> Bind) {
        content(self).update(&self)
    }
    
}
