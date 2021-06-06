//
//  ComposedReducer.swift
//  
//
//  Created by Markus Pfeifer on 06.05.21.
//

import CasePaths


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
    public func apply<Action : ActionProtocol>(_ action: Action, to state: inout R1.State, environment: Dependencies) {
        re1.apply(action, to: &state, environment: environment)
        re2.apply(action, to: &state, environment: environment)
    }
    
    @inlinable
    public func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
        re1.acceptsAction(action)
            || re2.acceptsAction(action)
    }
    
}
