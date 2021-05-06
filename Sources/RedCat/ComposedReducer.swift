//
//  ComposedReducer.swift
//  
//
//  Created by Markus Pfeifer on 06.05.21.
//

import Foundation


public extension DependentReducer {
    
    @inlinable 
    func compose<Next: DependentReducer>(with next: Next) -> ComposedReducer<Self, Next> {
        ComposedReducer(self, next)
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
    public func apply<Action : ActionProtocol>(_ action: Action, to state: inout R1.State, environment: Environment) {
        r1.apply(action, to: &state, environment: environment)
        r2.apply(action, to: &state, environment: environment)
    }
    
    
}
