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
                                              to state: inout State,
                                              environment: Dependencies)
    
    func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool
    
}


public extension ErasedReducer {
    
    @inlinable
    func applyDynamic(_ action: ActionProtocol,
                      to state: inout State,
                      environment: Dependencies = []) {
        action.apply(to: &state, using: self, environment: environment)
    }
    
    @inlinable
    func acceptsActionDynamic(_ action: ActionProtocol) -> Bool {
        action.accepts(using: self)
    }
}


extension ActionProtocol {
    
    @inlinable
    func apply<Reducer : ErasedReducer>(to state: inout Reducer.State,
                                        using reducer: Reducer,
                                        environment: Dependencies) {
        reducer.applyErased(self, to: &state, environment: environment)
    }
    
    @inlinable
    func accepts<Reducer : ErasedReducer>(using reducer: Reducer) -> Bool {
        reducer.acceptsAction(self)
    }
    
}


public protocol DependentReducer : ErasedReducer {
    
    associatedtype State 
    associatedtype Action : ActionProtocol
    
    func apply(_ action: Action,
               to state: inout State,
               environment: Dependencies)
    
}


public extension DependentReducer {
    
    @inlinable
    func applyErased<Action : ActionProtocol>(_ action: Action,
                                              to state: inout State,
                                              environment: Dependencies) {
        guard Action.self == Self.Action.self else {
            return
        }
        apply(action as! Self.Action, to: &state, environment: environment)
    }
    
    @inlinable
    func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
        action is Self.Action
    }
    
}


public protocol ReducerProtocol : DependentReducer {
    
    associatedtype State
    associatedtype Action
    
    func apply(_ action: Action,
               to state: inout State)
    
}

public extension ReducerProtocol {
    
    @inlinable
    func apply(_ action: Action,
               to state: inout State,
               environment: Dependencies) {
        apply(action, to: &state)
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
    public func applyErased<Action : ActionProtocol>(_ action: Action, to state: inout R1.State, environment: Dependencies) {
        re1.applyErased(action, to: &state, environment: environment)
        re2.applyErased(action, to: &state, environment: environment)
    }
    
    @inlinable
    public func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
        re1.acceptsAction(action)
            || re2.acceptsAction(action)
    }
    
}
