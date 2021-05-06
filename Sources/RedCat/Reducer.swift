//
//  Reducer.swift
//  
//
//  Created by Markus Pfeifer on 05.05.21.
//

import Foundation



public protocol DependentReducer {
    
    associatedtype State
    
    func apply<Action : ActionProtocol>(_ action: Action,
                       to state: inout State,
                       environment: Environment)
    
}


public extension DependentReducer {
    
    func applyDynamic(_ action: ActionProtocol,
                      to state: inout State,
                      environment: Environment = Environment()) {
        action.apply(to: &state, using: self, environment: environment)
    }
    
}


public protocol Reducer : DependentReducer {
    
    associatedtype Action : ActionProtocol
    func apply(_ action: Action,
               to state: inout State)
    
}

public extension Reducer {
    
    func apply<Action : ActionProtocol>(_ action: Action,
                       to state: inout State,
                       environment: Environment) {
        guard let action = action as? Self.Action else{return}
        apply(action, to: &state)
    }
    
}
