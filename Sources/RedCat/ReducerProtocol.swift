//
//  Reducer.swift
//  
//
//  Created by Markus Pfeifer on 05.05.21.
//

import Foundation



public protocol ErasedReducer {
    
    associatedtype State
    
    func applyErased<Action : ActionProtocol>(_ action: Action,
                                              to state: inout State,
                                              environment: Dependencies)
    
    func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool
    
}


public extension ErasedReducer {
    
    @inlinable
    func applyDynamic(_ action: ActionProtocol,
                      to state: inout State,
                      environment: Dependencies = []) {
        action.apply(to: &state, using: self, environment: environment)
    }
    
    @inlinable
    func acceptsActionDynamic(_ action: ActionProtocol) -> Bool {
        action.accepts(using: self)
    }
}


extension ActionProtocol {
    
    @inlinable
    func apply<Reducer : ErasedReducer>(to state: inout Reducer.State,
                                        using reducer: Reducer,
                                        environment: Dependencies) {
        reducer.applyErased(self, to: &state, environment: environment)
    }
    
    @inlinable
    func accepts<Reducer : ErasedReducer>(using reducer: Reducer) -> Bool {
        reducer.acceptsAction(self)
    }
    
}


public protocol DependentReducer : ErasedReducer {
    
    associatedtype State 
    associatedtype Action : ActionProtocol
    
    func apply(_ action: Action,
               to state: inout State,
               environment: Dependencies)
    
}


public extension DependentReducer {
    
    @inlinable
    func applyErased<Action : ActionProtocol>(_ action: Action,
                                              to state: inout State,
                                              environment: Dependencies) {
        guard Action.self == Self.Action.self else {
            return
        }
        apply(action as! Self.Action, to: &state, environment: environment)
    }
    
    @inlinable
    func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
        action is Self.Action
    }
    
}


public protocol ReducerProtocol : DependentReducer {
    
    associatedtype State
    associatedtype Action
    
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
