//
//  Environment.swift
//  
//
//  Created by Markus Pfeifer on 05.05.21.
//

import Foundation


/// Types conforming to ```Config``` define values that can be stored in the ```Dependencies```. If no value is stored, an appropriate default value will be computed from other dependencies.
public protocol Config {
    
    associatedtype Value
    
    /// Computes an appropriate default value given the rest of the environment.
    /// - Parameters:
    ///     - environment: The dependency graph that needs a default value.
    @MainActor
    static func value(given environment: Dependencies) -> Value
    
}


/// Types conforming to ```Config``` define values that can be stored in the ```Dependencies```. If no value is stored, the static default value from this protocol will be assumed.
public protocol Dependency : Config where StaticValue == Value {
    associatedtype StaticValue
    
    /// The default value, if nothing else is stored.
    static var defaultValue : StaticValue {get}
}


public extension Dependency {
    @MainActor
    static func value(given: Dependencies) -> Value {
        defaultValue
    }
}


#if compiler(>=5.5) && canImport(_Concurrency)


/// ```Dependencies``` Wrap the app's constants configured from outside. Values can be accessed via a subscript taking a type that conforms to ```Config```:
/// ```
/// public extension Dependencies {
///
///   var myValue : MyType {
///         get {self[MyKey.self]}
///         set {self[MyKey.self] = newValue}
///   }
///
/// }
/// ```
/// - Note: If you read a value that isn't stored in the underlying dictionary, the default value is assumed. The value will then be memoized and shared across all copies. As a result, if the dependency itself has reference semantics, it will be retained after the first read.
/// - Important: The way memoization is implemented requires properties to be read on the main thread. Failing to read not-yet memoized dependencies on the main thread is undefined behavior and may lead to crashes due to overlapping memory access.
@MainActor
public struct Dependencies {
    
    @usableFromInline
    var dict = SwiftMutableDict()
    
    @inlinable
    @MainActor
    public subscript<Key : Config>(key: Key.Type) -> Key.Value {
        get {
            if let result = dict.dict[String(describing: key)] as? Key.Value {
                return result
            }
            else {
                let result = Key.value(given: self)
                //memoization -- reference semantics is appropriate
                dict.dict[String(describing: key)] = result
                return result
            }
        }
        set {
            if
                !isKnownUniquelyReferenced(&dict) {
                self.dict = dict.copy()
            }
            dict.dict[String(describing: key)] = newValue
        }
    }
    
    @MainActor
    func hasStoredValue<Key : Config>(for key: Key.Type) -> Bool {
        dict.dict[String(describing: key)] != nil
    }
    
}

@usableFromInline
class SwiftMutableDict {
    @usableFromInline
    @MainActor
    var dict : [String : Any] = [:]
    @inlinable
    init(){}
    @inlinable
    @MainActor
    func copy() -> SwiftMutableDict {
        let result = SwiftMutableDict()
        result.dict = dict
        return result
    }
}


#else

/// ```Dependencies``` Wrap the app's constants configured from outside. Values can be accessed via a subscript taking a type that conforms to ```Config```:
/// ```
/// public extension Dependencies {
///
///   var myValue : MyType {
///         get {self[MyKey.self]}
///         set {self[MyKey.self] = newValue}
///   }
///
/// }
/// ```
/// - Note: If you read a value that isn't stored in the underlying dictionary, the default value is assumed. The value will then be memoized and shared across all copies. As a result, if the dependency itself has reference semantics, it will be retained after the first read.
/// - Important: The way memoization is implemented requires properties to be read on the main thread. Failing to read not-yet memoized dependencies on the main thread is undefined behavior and may lead to crashes due to overlapping memory access.
public struct Dependencies {
    
    @usableFromInline
    var dict = SwiftMutableDict()
    
    @inlinable
    public subscript<Key : Config>(key: Key.Type) -> Key.Value {
        get {
            if let result = dict.dict[String(describing: key)] as? Key.Value {
                return result
            }
            else {
                let result = Key.value(given: self)
                //memoization -- reference semantics is appropriate
                dict.dict[String(describing: key)] = result
                return result
            }
        }
        set {
            if
                !isKnownUniquelyReferenced(&dict) {
                self.dict = dict.copy()
            }
            dict.dict[String(describing: key)] = newValue
        }
    }
    
    func hasStoredValue<Key : Config>(for key: Key.Type) -> Bool {
        dict.dict[String(describing: key)] != nil
    }
    
}

@usableFromInline
class SwiftMutableDict {
    @usableFromInline
    var dict : [String : Any] = [:]
    @inlinable
    init(){}
    @inlinable
    func copy() -> SwiftMutableDict {
        let result = SwiftMutableDict()
        result.dict = dict
        return result
    }
}

#endif

public struct Bind {
    
    @usableFromInline
    let update : (inout Dependencies) -> Void
    @inlinable
    init(update: @escaping (inout Dependencies) -> Void) {
        self.update = update
    }
    
}


public extension Bind {
    
    init<Value>(_ keyPath: WritableKeyPath<Dependencies, Value>, to value: Value) {
        self.update = {env in env[keyPath: keyPath] = value}
    }
    
    init(@EnvironmentBuilder _ transform: @escaping (Dependencies) -> Bind) {
        self.update = {env in transform(env).update(&env)}
    }
    
    init<GivenValue>(given: KeyPath<Dependencies, GivenValue>,
                     @EnvironmentBuilder _ update: @escaping (GivenValue) -> Bind) {
        self = Bind{env in update(env[keyPath: given])}
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
        component ?? Bind(update: {_ in })
    }
    
    public static func buildArray(_ components: [Bind]) -> Bind {
        components.reduce(Bind(update: {_ in }), {b1, b2 in b1.then{_ in b2}})
    }
    
    public static func buildLimitedAvailability(_ component: Bind) -> Bind {
        component
    }
    
}


extension Dependencies : ExpressibleByArrayLiteral {
    
    nonisolated public init(arrayLiteral elements: Bind...) {
        EnvironmentBuilder.buildArray(elements).update(&self)
    }
    
}


public extension Dependencies {
    
    init(@EnvironmentBuilder content: (Dependencies) -> Bind) {
        content(self).update(&self)
    }
    
    init(@EnvironmentBuilder content: () -> Bind) {
        self = Dependencies{_ in content()}
    }
    
}
