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
    
    func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool
    
}


public extension ErasedReducer {
    
    func applyDynamic(_ action: ActionProtocol,
                      to state: inout State,
                      environment: Dependencies = []) {
        action.apply(to: &state, using: self, environment: environment)
    }
    
    func acceptsActionDynamic(_ action: ActionProtocol) -> Bool {
        action.accepts(using: self)
    }
}


extension ActionProtocol {
    
    @inlinable
    func apply<Reducer : ErasedReducer>(to state: inout Reducer.State,
                                        using reducer: Reducer,
                                        environment: Dependencies) {
        reducer.apply(self, to: &state, environment: environment)
    }
    
    @inlinable
    func accepts<Reducer : ErasedReducer>(using reducer: Reducer) -> Bool {
        reducer.acceptsAction(self)
    }
    
}


public protocol DependentReducer : ErasedReducer {
    
    associatedtype Action : ActionProtocol
    
    func apply(_ action: Action,
               to state: inout State,
               environment: Dependencies)
    
}


public extension DependentReducer {
    
    @inlinable
    func apply<Action : ActionProtocol>(_ action: Action,
                                        to state: inout State,
                                        environment: Dependencies) {
        guard let action = action as? Self.Action else {
            return
        }
        apply(action, to: &state, environment: environment)
    }
    
    @inlinable
    func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
        action is Self.Action
    }
    
}


public protocol ReducerProtocol : DependentReducer {
    
    func apply(_ action: Action,
               to state: inout State)
    
}

public extension ReducerProtocol {
    
    @inlinable
    func apply(_ action: Action,
               to state: inout State,
               environment: Dependencies) {
        apply(action, to: &state)
    }
    
}
