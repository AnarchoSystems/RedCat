//
//  ComposedClassReducer.swift
//  
//
//  Created by Markus Pfeifer on 11.05.21.
//

import CasePaths


public extension ErasedClassReducer {
    
    @inlinable
    func compose<Next: ErasedClassReducer>(with next: Next) -> ComposedClassReducer<Self, Next>
    where Next.State == State {
        ComposedClassReducer(self, next)
    }
    
}


public struct ComposedClassReducer<R1 : ErasedClassReducer, R2 : ErasedClassReducer> : ErasedClassReducer
where R1.State == R2.State {
    
    public typealias State = R1.State
    
    @usableFromInline
    let re1 : R1
    @usableFromInline
    let re2 : R2
    
    @usableFromInline
    init(_ re1: R1, _ re2: R2) {(self.re1, self.re2) = (re1, re2)}
    
    
    public func apply<Action : ActionProtocol>(_ action: Action,
                                               to state: R1.State,
                                               environment: Dependencies) {
        re1.apply(action, to: state, environment: environment)
        re2.apply(action, to: state, environment: environment)
    }
    
    public func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
        re1.acceptsAction(action)
            || re2.acceptsAction(action)
    }
    
}
