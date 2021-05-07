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


public struct RefReducer<State : AnyObject, Action : ActionProtocol> : DependentClassReducer {
    
    @usableFromInline
    let closure : (Action, State, Environment) -> Void
    
    @inlinable
    public init(_ closure: @escaping (Action, State, Environment) -> Void){
        self.closure = closure
    }
    
    @inlinable
    public init(_ closure: @escaping (Action, State) -> Void){
        self.closure = {action, state, _ in closure(action, state)}
    }
    
    @inlinable
    public func apply(_ action: Action, to state: State, environment: Environment) {
        closure(action, state, environment)
    }
    
}
