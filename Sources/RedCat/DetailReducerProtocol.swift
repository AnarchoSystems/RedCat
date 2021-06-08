//
//  DetailReducer.swift
//  
//
//  Created by Markus Pfeifer on 05.05.21.
//

import Foundation


public protocol DetailReducerProtocol : ReducerProtocol {
    
    associatedtype State
    associatedtype Detail
    associatedtype Action
    
    var keyPath : WritableKeyPath<State, Detail> {get}
    func apply(_ action: Action,
               to detail: inout Detail)
    
}


public extension DetailReducerProtocol {
    
    @inlinable
    func apply(_ action: Action,
               to state: inout State) {
        apply(action, to: &state[keyPath: keyPath])
    }
    
}


public protocol DetailReducerWrapper : ErasedReducer {
    
    associatedtype Body : ErasedReducer
    
    var keyPath : WritableKeyPath<State, Body.State> {get}
    var body : Body {get}
    
}


public extension DetailReducerWrapper {
    
    @inlinable
    func applyErased<Action : ActionProtocol>(_ action: Action,
                                              to state: inout State) {
        body.applyErased(action, to: &state[keyPath: keyPath])
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
    
    @inlinable
    public init<Detail, Action : ActionProtocol>(_ detail: WritableKeyPath<State, Detail>,
                                                 closure: @escaping (Action, inout Detail) -> Void)
    where Reducer == ClosureReducer<Detail, Action> {
        self.keyPath = detail
        self.body = ClosureReducer(closure)
    }
    
}


public extension ErasedReducer {
    
    @inlinable
    func bind<Root>(to property: WritableKeyPath<Root, State>) -> DetailReducer<Root, Self> {
        DetailReducer(property, reducer: self)
    }
    
}


public extension Reducers.Native {
    
    func detailReducer<State, Detail, Action : ActionProtocol>(_ detail: WritableKeyPath<State, Detail>,
                                                               _ closure: @escaping (Action, inout Detail) -> Void)
    -> DetailReducer<State, ClosureReducer<Detail, Action>> {
        DetailReducer(detail, closure: closure)
    }
    
}
