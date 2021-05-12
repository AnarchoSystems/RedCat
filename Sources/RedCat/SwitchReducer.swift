//
//  SwitchReducer.swift
//  
//
//  Created by Markus Pfeifer on 12.05.21.
//

import Foundation



public enum IfReducer<R1 : ErasedReducer, R2 : ErasedReducer> : ErasedReducer where R1.State == R2.State {
    
    case ifReducer(R1)
    case elseReducer(R2)
    
    public func apply<Action : ActionProtocol>(_ action: Action, to state: inout R1.State, environment: Dependencies) {
        switch self {
        case .ifReducer(let reducer):
            reducer.apply(action, to: &state, environment: environment)
        case .elseReducer(let reducer):
            reducer.apply(action, to: &state, environment: environment)
        }
    }
    
    public func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
        switch self {
        case .ifReducer(let reducer):
            return reducer.acceptsAction(action)
        case .elseReducer(let reducer):
            return reducer.acceptsAction(action)
        }
    }
    
    public static func elseReducer<State>() -> Self where R2 == NopReducer<State> {
        .elseReducer(NopReducer())
    }
    
}


extension IfReducer : ErasedClassReducer where R1 : ErasedClassReducer, R2 : ErasedClassReducer {
    
    public func apply<Action : ActionProtocol>(_ action: Action, to state: R1.State, environment: Dependencies) {
        switch self {
        case .ifReducer(let reducer):
            reducer.apply(action, to: state, environment: environment)
        case .elseReducer(let reducer):
            reducer.apply(action, to: state, environment: environment)
        }
    }
    
}


public enum ElseIfReducer<R1 : ErasedReducer, R2 : ErasedReducer, R3 : ErasedReducer> : ErasedReducer where
    R1.State == R2.State, R2.State == R3.State {
    
    
    case ifReducer(R1)
    case elseIfReducer(R2)
    case elseReducer(R3)
    
    public func apply<Action : ActionProtocol>(_ action: Action, to state: inout R1.State, environment: Dependencies) {
        switch self {
        case .ifReducer(let reducer):
            reducer.apply(action, to: &state, environment: environment)
        case .elseIfReducer(let reducer):
            reducer.apply(action, to: &state, environment: environment)
        case .elseReducer(let reducer):
            reducer.apply(action, to: &state, environment: environment)
        }
    }
    
    public func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
        switch self {
        case .ifReducer(let reducer):
            return reducer.acceptsAction(action)
        case .elseIfReducer(let reducer):
            return reducer.acceptsAction(action)
        case .elseReducer(let reducer):
            return reducer.acceptsAction(action)
        }
    }
    
    public static func elseReducer<State>() -> Self where R3 == NopReducer<State> {
        .elseReducer(NopReducer())
    }
    
}


extension ElseIfReducer : ErasedClassReducer where
    R1 : ErasedClassReducer, R2 : ErasedClassReducer, R3 : ErasedClassReducer {
    
    public func apply<Action : ActionProtocol>(_ action: Action, to state: R1.State, environment: Dependencies) {
        switch self {
        case .ifReducer(let reducer):
            reducer.apply(action, to: state, environment: environment)
        case .elseIfReducer(let reducer):
            reducer.apply(action, to: state, environment: environment)
        case .elseReducer(let reducer):
            reducer.apply(action, to: state, environment: environment)
        }
    }
    
}


public enum Switch4Reducer<R1 : ErasedReducer, R2 : ErasedReducer, R3 : ErasedReducer, R4 : ErasedReducer>
: ErasedReducer where R1.State == R2.State, R2.State == R3.State, R3.State == R4.State {
    
    case case1Reducer(R1)
    case case2Reducer(R2)
    case case3Reducer(R3)
    case defaultReducer(R4)
    
    public func apply<Action : ActionProtocol>(_ action: Action, to state: inout R1.State, environment: Dependencies) {
        switch self {
        case .case1Reducer(let reducer):
            reducer.apply(action, to: &state, environment: environment)
        case .case2Reducer(let reducer):
            reducer.apply(action, to: &state, environment: environment)
        case .case3Reducer(let reducer):
            reducer.apply(action, to: &state, environment: environment)
        case .defaultReducer(let reducer):
            reducer.apply(action, to: &state, environment: environment)
        }
    }
    
    public func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
        switch self {
        case .case1Reducer(let reducer):
            return reducer.acceptsAction(action)
        case .case2Reducer(let reducer):
            return reducer.acceptsAction(action)
        case .case3Reducer(let reducer):
            return reducer.acceptsAction(action)
        case .defaultReducer(let reducer):
            return reducer.acceptsAction(action)
        }
    }
    
    public static func defaultReducer<State>() -> Self where R4 == NopReducer<State> {
        .defaultReducer(NopReducer())
    }
    
}


extension Switch4Reducer : ErasedClassReducer where
    R1 : ErasedClassReducer, R2 : ErasedClassReducer, R3 : ErasedClassReducer, R4 : ErasedClassReducer {
    
    public func apply<Action : ActionProtocol>(_ action: Action, to state: R1.State, environment: Dependencies) {
        switch self {
        case .case1Reducer(let reducer):
            reducer.apply(action, to: state, environment: environment)
        case .case2Reducer(let reducer):
            reducer.apply(action, to: state, environment: environment)
        case .case3Reducer(let reducer):
            reducer.apply(action, to: state, environment: environment)
        case .defaultReducer(let reducer):
            reducer.apply(action, to: state, environment: environment)
        }
    }
    
}
