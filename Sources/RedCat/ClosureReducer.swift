//
//  ClosureReducer.swift
//  
//
//  Created by Markus Pfeifer on 07.05.21.
//

import Foundation



public struct ClosureReducer<State, Act : ActionProtocol> : DependentReducer {
    
    public typealias Action = Act
    
    @usableFromInline
    let closure : (Act, inout State, Dependencies) -> Void
    
    @inlinable
    public init(_ closure: @escaping (Act, inout State, Dependencies) -> Void) {
        self.closure = closure
    }
    
    @inlinable
    public init(_ closure: @escaping (Act, inout State) -> Void) {
        self = Self {action, state, _ in closure(action, &state)}
    }
    
    @inlinable
    public func apply<Action : ActionProtocol>(_ action: Action,
                                               to state: inout State,
                                               environment: Dependencies) {
        guard let action = action as? Act else {return}
        closure(action, &state, environment)
    }
    
}
