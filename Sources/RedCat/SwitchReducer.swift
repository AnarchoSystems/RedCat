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
    
    @inlinable
    public func applyErased<Action : ActionProtocol>(_ action: Action, to state: inout R1.State) {
        switch self {
        case .ifReducer(let reducer):
            reducer.applyErased(action, to: &state)
        case .elseReducer(let reducer):
            reducer.applyErased(action, to: &state)
        }
    }
    
    @inlinable
    public func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
        switch self {
        case .ifReducer(let reducer):
            return reducer.acceptsAction(action)
        case .elseReducer(let reducer):
            return reducer.acceptsAction(action)
        }
    }
    
    @inlinable
    public static func elseReducer<State>() -> Self where R2 == NopReducer<State> {
        .elseReducer(NopReducer())
    }
    
}


public enum ElseIfReducer<R1 : ErasedReducer, R2 : ErasedReducer, R3 : ErasedReducer> : ErasedReducer where
    R1.State == R2.State, R2.State == R3.State {
    
    
    case ifReducer(R1)
    case elseIfReducer(R2)
    case elseReducer(R3)
    
    @inlinable
    public func applyErased<Action : ActionProtocol>(_ action: Action, to state: inout R1.State) {
        switch self {
        case .ifReducer(let reducer):
            reducer.applyErased(action, to: &state)
        case .elseIfReducer(let reducer):
            reducer.applyErased(action, to: &state)
        case .elseReducer(let reducer):
            reducer.applyErased(action, to: &state)
        }
    }
    
    @inlinable
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
    
    @inlinable
    public static func elseReducer<State>() -> Self where R3 == NopReducer<State> {
        .elseReducer(NopReducer())
    }
    
}


public enum Switch4Reducer<R1 : ErasedReducer, R2 : ErasedReducer, R3 : ErasedReducer, R4 : ErasedReducer>
: ErasedReducer where R1.State == R2.State, R2.State == R3.State, R3.State == R4.State {
    
    case case1Reducer(R1)
    case case2Reducer(R2)
    case case3Reducer(R3)
    case defaultReducer(R4)
    
    @inlinable
    public func applyErased<Action : ActionProtocol>(_ action: Action, to state: inout R1.State) {
        switch self {
        case .case1Reducer(let reducer):
            reducer.applyErased(action, to: &state)
        case .case2Reducer(let reducer):
            reducer.applyErased(action, to: &state)
        case .case3Reducer(let reducer):
            reducer.applyErased(action, to: &state)
        case .defaultReducer(let reducer):
            reducer.applyErased(action, to: &state)
        }
    }
    
    @inlinable
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
    
    @inlinable
    public static func defaultReducer<State>() -> Self where R4 == NopReducer<State> {
        .defaultReducer(NopReducer())
    }
    
}



public extension Reducers.Native {
    
    func ifReducer<R1 : ErasedReducer, R2 : ErasedReducer>(_ r1: R1, otherType: R2.Type = R2.self) -> IfReducer<R1, R2> {
        IfReducer.ifReducer(r1)
    }
    
    func elseReducer<R1 : ErasedReducer, R2 : ErasedReducer>(_ r2: R2, otherType: R1.Type = R1.self) -> IfReducer<R1, R2> {
        IfReducer.elseReducer(r2)
    }
    
}
