//
//  Reducer.swift
//  
//
//  Created by Markus Pfeifer on 05.05.21.
//

import Foundation



public protocol ErasedReducer {
    
    associatedtype State
    
    func apply<Action : ActionProtocol>(_ action: Action,
                                        to state: inout State,
                                        environment: Dependencies)
    
    func acceptsAction<Action : ActionProtocol>(ofType type: Action.Type) -> Bool
    
}


public extension ErasedReducer {
    
    func applyDynamic(_ action: ActionProtocol,
                      to state: inout State,
                      environment: Dependencies = Dependencies()) {
        action.apply(to: &state, using: self, environment: environment)
    }
    
}


public protocol DependentReducer : ErasedReducer {
    
    associatedtype Action : ActionProtocol
    
    func apply(_ action: Action,
               to state: inout State,
               environment: Dependencies)
    
}


public extension DependentReducer {
    
    func apply<Action : ActionProtocol>(_ action: Action,
                                        to state: inout State,
                                        environment: Dependencies) {
        guard let action = action as? Self.Action else {return}
        apply(action, to: &state, environment: environment)
    }
    
    func acceptsAction<Action : ActionProtocol>(ofType type: Action.Type) -> Bool {
        type == Self.Action.self
    }
    
}


public protocol ReducerProtocol : DependentReducer {
    
    func apply(_ action: Action,
               to state: inout State)
    
}

public extension ReducerProtocol {
    
    func apply(_ action: Action,
               to state: inout State,
               environment: Dependencies) {
        apply(action, to: &state)
    }
    
}
