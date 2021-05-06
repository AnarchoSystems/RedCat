//
//  DetailReducer.swift
//  
//
//  Created by Markus Pfeifer on 05.05.21.
//

import Foundation


public protocol DependentDetailReducer : DependentReducer {
    
    associatedtype Detail
    associatedtype Action : ActionProtocol
    
    var keyPath : WritableKeyPath<State, Detail>{get}
    func apply(_ action: Action,
               to detail: inout Detail,
               environment: Environment)
    
}


public extension DependentDetailReducer {
    
    func apply<Action : ActionProtocol>(_ action: Action,
                       to state: inout State,
                       environment: Environment) {
        guard let action = action as? Self.Action else{return}
        apply(action, to: &state[keyPath: keyPath], environment: environment)
    }
    
}


public protocol DetailReducer : DependentReducer {
    
    associatedtype Detail
    associatedtype Action : ActionProtocol
    
    var keyPath : WritableKeyPath<State, Detail>{get}
    func apply(_ action: Action,
               to detail: inout Detail)
    
}


public extension DetailReducer {
    
    func apply<Action : ActionProtocol>(_ action: Action,
                       to state: inout State,
                       environment: Environment) {
        guard let action = action as? Self.Action else{return}
        apply(action, to: &state[keyPath: keyPath])
    }
    
}


public protocol DetailReducerWrapper : DependentReducer {
    
    associatedtype Body : DependentReducer
    
    var keyPath : WritableKeyPath<State, Body.State>{get}
    var body : Body{get}
    
}


public extension DetailReducerWrapper {
    
    func apply<Action : ActionProtocol>(_ action: Action,
                       to state: inout State,
                       environment: Environment) {
        body.apply(action, to: &state[keyPath: keyPath], environment: environment)
    }
    
}
