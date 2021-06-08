//
//  Reducer.swift
//  
//
//  Created by Markus Pfeifer on 05.05.21.
//

import CasePaths


public protocol ErasedReducer {
    
    associatedtype State
    
    func applyErased<Action : ActionProtocol>(_ action: Action,
                                              to state: inout State)
    
    func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool
    
}


public extension ErasedReducer {
    
    @inlinable
    func applyDynamic(_ action: ActionProtocol,
                      to state: inout State) {
        action.apply(to: &state, using: self)
    }
    
    @inlinable
    func acceptsActionDynamic(_ action: ActionProtocol) -> Bool {
        action.accepts(using: self)
    }
}


extension ActionProtocol {
    
    @usableFromInline
    func apply<Reducer : ErasedReducer>(to state: inout Reducer.State,
                                        using reducer: Reducer) {
        reducer.applyErased(self, to: &state)
    }
    
    @inlinable
    func accepts<Reducer : ErasedReducer>(using reducer: Reducer) -> Bool {
        reducer.acceptsAction(self)
    }
    
}


public protocol ReducerProtocol : ErasedReducer {
    
    associatedtype State 
    associatedtype Action : ActionProtocol
    
    func apply(_ action: Action,
               to state: inout State)
    
}


public extension ReducerProtocol {
    
    @inlinable
    func applyErased<Action : ActionProtocol>(_ action: Action,
                                              to state: inout State) {
        guard Action.self == Self.Action.self else {
            return
        }
        apply(action as! Self.Action, to: &state)
    }
    
    @inlinable
    func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
        action is Self.Action
    }
    
}


public extension ErasedReducer {
    
    @inlinable
    func compose<Next: ErasedReducer>(with next: Next) -> ComposedReducer<Self, Next> where Next.State == State {
        ComposedReducer(self, next)
    }
    
    @inlinable
    func compose<Next : ErasedReducer>(with next: Next,
                                       property: WritableKeyPath<State, Next.State>)
    -> ComposedReducer<Self, DetailReducer<State, Next>> {
        compose(with: DetailReducer(property, reducer: next))
    }
    
    @inlinable
    func compose<Next : ErasedReducer>(with next: Next,
                                       aspect: CasePath<State, Next.State>)
    -> ComposedReducer<Self, AspectReducer<State, Next>> where State : Releasable {
        compose(with: AspectReducer(aspect, reducer: next))
    }
    
}


public struct ComposedReducer<R1 : ErasedReducer, R2 : ErasedReducer> : ErasedReducer where R1.State == R2.State {
    
    @usableFromInline
    let re1 : R1
    @usableFromInline
    let re2 : R2
    
    @usableFromInline
    init(_ re1: R1, _ re2: R2) {(self.re1, self.re2) = (re1, re2)}
    
    @inlinable
    public func applyErased<Action : ActionProtocol>(_ action: Action, to state: inout R1.State) {
        re1.applyErased(action, to: &state)
        re2.applyErased(action, to: &state)
    }
    
    @inlinable
    public func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
        re1.acceptsAction(action)
            || re2.acceptsAction(action)
    }
    
}
