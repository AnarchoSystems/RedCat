//
//  ComposedReducer.swift
//  
//
//  Created by Markus Pfeifer on 06.05.21.
//

import CasePaths


public extension DependentReducer {
    
    @inlinable 
    func compose<Next: DependentReducer>(with next: Next) -> ComposedReducer<Self, Next> where Next.State == State {
        ComposedReducer(self, next)
    }
    
    @inlinable
    func compose<Next : DependentReducer>(with next: Next, property: WritableKeyPath<State, Next.State>) -> ComposedReducer<Self, LensReducer<State, Next>> {
        compose(with: LensReducer(property, reducer: next))
    }
    
    @inlinable
    func compose<Next : DependentReducer>(with next: Next, aspect: CasePath<State, Next.State>) -> ComposedReducer<Self, PrismReducer<State, Next>> where State : Emptyable {
        compose(with: PrismReducer(aspect, reducer: next))
    }
    
    @inlinable
    func compose<Next : DependentClassReducer>(with next: Next, aspect: CasePath<State, Next.State>) -> ComposedReducer<Self, ClassPrismReducer<State, Next>> {
        compose(with: ClassPrismReducer(aspect, reducer: next))
    }
    
}


public struct ComposedReducer<R1 : DependentReducer, R2 : DependentReducer> : DependentReducer where R1.State == R2.State {
    
    @usableFromInline
    let r1 : R1
    @usableFromInline
    let r2 : R2
    
    @usableFromInline
    init(_ r1: R1, _ r2: R2){(self.r1, self.r2) = (r1, r2)}
    
    @inlinable
    public func apply<Action : ActionProtocol>(_ action: Action, to state: inout R1.State, environment: Dependencies) {
        r1.apply(action, to: &state, environment: environment)
        r2.apply(action, to: &state, environment: environment)
    }
    
    
}
