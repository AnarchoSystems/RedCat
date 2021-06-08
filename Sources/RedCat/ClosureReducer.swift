//
//  ClosureReducer.swift
//  
//
//  Created by Markus Pfeifer on 07.05.21.
//

import Foundation



public struct ClosureReducer<State, Action : ActionProtocol> : ReducerProtocol {
    
    @usableFromInline
    let closure : (Action, inout State) -> Void
    
    @inlinable
    public init(_ closure: @escaping (Action, inout State) -> Void) {
        self.closure = closure
    }
    
    @inlinable
    public func apply(_ action: Action,
                      to state: inout State) {
        closure(action, &state)
    }
    
}


public extension Reducers.Native {
    
    func withClosure<State, Action : ActionProtocol>(_ closure: @escaping (Action, inout State) -> Void) -> ClosureReducer<State, Action> {
        ClosureReducer(closure)
    }
    
}
