//
//  ClosureReducer.swift
//  
//
//  Created by Markus Pfeifer on 07.05.21.
//

import Foundation


/// An anonymous instance of ```ReducerProtocol```, created using a closure.
public struct ClosureReducer<State, Action, Response> : ReducerProtocol {
    
    @usableFromInline
    let closure : (Action, inout State) -> Response
    
    @inlinable
    public init(_ closure: @escaping (Action, inout State) -> Response) {
        self.closure = closure
    }
    
    @inlinable
    public func apply(_ action: Action,
                      to state: inout State) -> Response {
        closure(action, &state)
    }
    
}


public extension Reducers.Native {
    
    static func withClosure<State, Action, Response>(_ closure: @escaping (Action, inout State) -> Response) -> ClosureReducer<State, Action, Response> {
        ClosureReducer(closure)
    }
    
}
