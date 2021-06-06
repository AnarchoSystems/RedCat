//
//  DetailReducer.swift
//  
//
//  Created by Markus Pfeifer on 05.05.21.
//

import Foundation


public protocol DependentDetailReducer : ErasedReducer {
    
    associatedtype Detail
    associatedtype Action : ActionProtocol
    
    var keyPath : WritableKeyPath<State, Detail> {get}
    func apply(_ action: Action,
               to detail: inout Detail,
               environment: Dependencies)
    
}


public extension DependentDetailReducer {
    
    @inline(__always)
    func apply<Action : ActionProtocol>(_ action: Action,
                                        to state: inout State,
                                        environment: Dependencies) {
        guard let action = action as? Self.Action else {
            return
        }
        apply(action, to: &state[keyPath: keyPath], environment: environment)
    }
    
    @inline(__always)
    func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
        action is Self.Action
    }
    
}


public protocol DetailReducerProtocol : ErasedReducer {
    
    associatedtype Detail
    associatedtype Action : ActionProtocol
    
    var keyPath : WritableKeyPath<State, Detail> {get}
    func apply(_ action: Action,
               to detail: inout Detail)
    
}


public extension DetailReducerProtocol {
    
    @inline(__always)
    func apply<Action : ActionProtocol>(_ action: Action,
                                        to state: inout State,
                                        environment: Dependencies) {
        guard let action = action as? Self.Action else {
            return
        }
        apply(action, to: &state[keyPath: keyPath])
    }
    
    @inline(__always)
    func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
        action is Self.Action
    }
    
}


public protocol DetailReducerWrapper : ErasedReducer {
    
    associatedtype Body : ErasedReducer
    
    var keyPath : WritableKeyPath<State, Body.State> {get}
    var body : Body {get}
    
}


public extension DetailReducerWrapper {
    
    @inline(__always)
    func apply<Action : ActionProtocol>(_ action: Action,
                                        to state: inout State,
                                        environment: Dependencies) {
        body.apply(action, to: &state[keyPath: keyPath], environment: environment)
    }
    
    func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
        body.acceptsAction(action)
    }
    
}


public struct DetailReducer<State, Reducer : ErasedReducer> : DetailReducerWrapper {
    
    public let keyPath: WritableKeyPath<State, Reducer.State>
    public let body : Reducer
    
    @inlinable
    public init(_ detail: WritableKeyPath<State, Reducer.State>, reducer: Reducer) {
        self.keyPath = detail
        self.body = reducer
    }
    
    @inlinable
    public init(_ detail: WritableKeyPath<State, Reducer.State>, build: @escaping () -> Reducer) {
        self.keyPath = detail
        self.body = build()
    }
    
}


public extension ErasedReducer {
    
    @inlinable
    func bind<Root>(to property: WritableKeyPath<Root, State>) -> DetailReducer<Root, Self> {
        DetailReducer(property, reducer: self)
    }
    
}
