//
//  ClosureReducer.swift
//  
//
//  Created by Markus Pfeifer on 07.05.21.
//

import Foundation


/// An anonymous instance of ```ReducerProtocol```, created using a closure.
public struct ClosureReducer<State, Action> : ReducerProtocol {
    
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
    
    static func withClosure<State, Action>(_ closure: @escaping (Action, inout State) -> Void) -> ClosureReducer<State, Action> {
        ClosureReducer(closure)
    }
    
}
