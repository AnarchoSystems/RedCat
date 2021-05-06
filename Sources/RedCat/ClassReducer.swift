//
//  ClassReducer.swift
//  
//
//  Created by Markus Pfeifer on 06.05.21.
//

import Foundation



public protocol DependentClassReducer : DependentReducer where State : AnyObject {
    
    associatedtype Action : ActionProtocol
    func apply(_ action: Action,
               to state: State,
               environment: Environment)
    
}


public extension DependentClassReducer {
    
    func apply<Action : ActionProtocol>(_ action: Action,
                       to state: inout State,
                       environment: Environment) {
        guard let action = action as? Self.Action else{return}
        apply(action, to: state, environment: environment)
    }
    
}


public protocol ClassReducer : DependentClassReducer {
    
    func apply(_ action: Action,
               to state: State)
    
}


public extension ClassReducer {
    
    func apply<Action : ActionProtocol>(_ action: Action,
                       to state: State,
                       environment: Environment) {
        guard let action = action as? Self.Action else{return}
        apply(action, to: state)
    }
    
}


public protocol ClassReducerWrapper : DependentClassReducer where Body.Action == Action {
    
    associatedtype Body : DependentClassReducer
    var body : Body{get}
    
}


public extension ClassReducerWrapper {
    
    func apply(_ action: Action,
               to state: Body.State,
               environment: Environment) {
        body.apply(action,
                   to: state,
                   environment: environment)
    }
    
}
