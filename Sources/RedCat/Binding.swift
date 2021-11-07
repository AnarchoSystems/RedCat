//
//  Binding.swift
//  RedCat
//
//  Created by Markus Pfeifer on 15.05.21.
//



// see also:
// https://stackoverflow.com/questions/66716119/cannot-find-swiftui-or-combine-types-when-building-swift-package-for-any-ios-de/67853022#67853022


#if compiler(>=5.5) && canImport(_Concurrency)

// no good solution :( even on compiler >= 5.5 and canImport(_Concurrency), SwiftUI does not force the closures of bindings to run on main thread


#if os(macOS) || os(watchOS) || os(tvOS) || (os(iOS) && arch(arm64))
#if canImport(SwiftUI)

import SwiftUI

@dynamicMemberLookup
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public protocol StoreView : View {
    
    associatedtype Store : StoreProtocol
    
    var store : Store {get}
    
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension StoreView {
    
    @MainActor
    subscript<T>(dynamicMember member: KeyPath<Store.State, T>) -> T {
        store.state[keyPath: member]
    }
    
}

#endif
#endif

#else


#if os(macOS) || os(watchOS) || os(tvOS) || (os(iOS) && arch(arm64))
#if canImport(SwiftUI)

import SwiftUI

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension StoreProtocol {
    
    /// Exposes a value as a binding, if provided with an action that serves as a setter.
    func binding<Value>(for value: @escaping (State) -> Value,
                        action: @escaping (Value) -> Action) -> Binding<Value> {
        Binding(get: {value(self.state)},
                set: {self.send(action($0))})
    }
    
    func binding(_ action: @escaping (State) -> Action) -> Binding<State> {
        binding(for: {$0},
                   action: action)
    }
    
    /// Exposes a value as a binding, if provided with an action that serves as a setter.
    func binding<Value, A : Undoable>(for value: @escaping (State) -> Value,
                                      withUndoManager: UndoManager?,
                                      undoTitle: String? = nil,
                                      redoTitle: String? = nil,
                                      embed: @escaping (A) -> Action,
                                      action: @escaping (Value) -> A) -> Binding<Value> {
        Binding(get: {value(self.state)},
                set: {self.sendWithUndo(action($0),
                                        undoTitle: undoTitle,
                                        redoTitle: redoTitle,
                                        undoManager: withUndoManager,
                                        embed: embed)})
    }
    
    func binding<Value>(for value: @escaping (State) -> Value,
                        withUndoManager: UndoManager?,
                        undoTitle: String? = nil,
                        redoTitle: String? = nil,
                        action: @escaping (Value) -> Action) -> Binding<Value> where Action : Undoable {
        Binding(get: {value(self.state)},
                set: {self.sendWithUndo(action($0),
                                        undoTitle: undoTitle,
                                        redoTitle: redoTitle,
                                        undoManager: withUndoManager)})
    }
    
    /// Exposes a value as a binding, if provided with an action that serves as a setter.
    func binding<A : Undoable>(withUndoManager: UndoManager?,
                               undoTitle: String? = nil,
                               redoTitle: String? = nil,
                               embed: @escaping (A) -> Action,
                               action: @escaping (State) -> A) -> Binding<State> {
        Binding(get: {self.state},
                set: {self.sendWithUndo(action($0),
                                        undoTitle: undoTitle,
                                        redoTitle: redoTitle,
                                        undoManager: withUndoManager,
                                        embed: embed)})
    }
    
    func binding(withUndoManager: UndoManager?,
                 undoTitle: String? = nil,
                 redoTitle: String? = nil,
                 action: @escaping (State) -> Action) -> Binding<State> where Action : Undoable {
        Binding(get: {self.state},
                set: {self.sendWithUndo(action($0),
                                        undoTitle: undoTitle,
                                        redoTitle: redoTitle,
                                        undoManager: withUndoManager)})
    }
    
}


@dynamicMemberLookup
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public protocol StoreView : View {
    
    associatedtype Store : StoreProtocol
    
    var store : Store {get}
    
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension StoreView {
    
    subscript<T>(dynamicMember member: KeyPath<Store.State, T>) -> T {
        store.state[keyPath: member]
    }
    
}

#endif
#endif

#endif
