//
//  ClosureReducer.swift
//  
//
//  Created by Markus Pfeifer on 07.05.21.
//

import Foundation



public struct ClosureReducer<State, Action : ActionProtocol> : DependentReducer {
    
    @usableFromInline
    let closure : (Action, inout State, Dependencies) -> Void
    
    @inlinable
    public init(_ closure: @escaping (Action, inout State, Dependencies) -> Void) {
        self.closure = closure
    }
    
    @inlinable
    public init(_ closure: @escaping (Action, inout State) -> Void) {
        self = Self {action, state, _ in closure(action, &state)}
    }
    
    @inline(__always)
    public func apply(_ action: Action,
                      to state: inout State,
                      environment: Dependencies) {
        closure(action, &state, environment)
    }
    
}
