//
//  ClosureReducer.swift
//  
//
//  Created by Markus Pfeifer on 07.05.21.
//

import Foundation



public struct Reducer<State, Act : ActionProtocol> : DependentReducer {
    
    @usableFromInline
    let closure : (Act, inout State, Environment) -> Void
    
    @inlinable
    public init(_ closure: @escaping (Act, inout State, Environment) -> Void){
        self.closure = closure
    }
    
    @inlinable
    public init(_ closure: @escaping (Act, inout State) -> Void){
        self = Reducer{action, state, _ in closure(action, &state)}
    }
    
    @inlinable
    public func apply<Action : ActionProtocol>(_ action: Action,
                              to state: inout State,
                              environment: Environment) {
        guard let action = action as? Act else{return}
        closure(action, &state, environment)
    }
    
}
