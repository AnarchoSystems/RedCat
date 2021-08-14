//
//  SwitchReducer.swift
//  
//
//  Created by Markus Pfeifer on 12.05.21.
//

import Foundation



public enum IfReducer<R1 : ReducerProtocol, R2 : ReducerProtocol> : ReducerProtocol where R1.State == R2.State, R1.Action == R2.Action {
    
    case ifReducer(R1)
    case elseReducer(R2)
    
    @inlinable
    public func apply(_ action: R1.Action, to state: inout R1.State) {
        switch self {
        case .ifReducer(let reducer):
            reducer.apply(action, to: &state)
        case .elseReducer(let reducer):
            reducer.apply(action, to: &state)
        }
    }
    
    @inlinable
    public static func elseReducer<State, Action, Response>() -> Self where R2 == NopReducer<State, Action, Response> {
        .elseReducer(Reducers.Native.nop())
    }
    
}

// the below types really only make sense when there are opaque return types where you can specify associatedtypes

#if swift(>=999)
/*

public enum ElseIfReducer<R1 : ReducerProtocol, R2 : ReducerProtocol, R3 : ReducerProtocol> : ReducerProtocol where
    R1.State == R2.State, R2.State == R3.State, R1.Action == R2.Action, R2.Action == R3.Action {
    
    
    case ifReducer(R1)
    case elseIfReducer(R2)
    case elseReducer(R3)
    
    @inlinable
    public func apply(_ action: R1.Action, to state: inout R1.State) {
        switch self {
        case .ifReducer(let reducer):
            reducer.apply(action, to: &state)
        case .elseIfReducer(let reducer):
            reducer.apply(action, to: &state)
        case .elseReducer(let reducer):
            reducer.apply(action, to: &state)
        }
    }
    
    @inlinable
    public static func elseReducer<State, Action>() -> Self where R3 == NopReducer<State, Action> {
        .elseReducer(NopReducer())
    }
    
}


public enum Switch4Reducer<R1 : ReducerProtocol, R2 : ReducerProtocol, R3 : ReducerProtocol, R4 : ReducerProtocol>
: ReducerProtocol where R1.State == R2.State, R2.State == R3.State, R3.State == R4.State,
                        R1.Action == R2.Action, R2.Action == R3.Action, R3.Action == R4.Action {
    
    case case1Reducer(R1)
    case case2Reducer(R2)
    case case3Reducer(R3)
    case defaultReducer(R4)
    
    @inlinable
    public func apply(_ action: R1.Action, to state: inout R1.State) {
        switch self {
        case .case1Reducer(let reducer):
            reducer.apply(action, to: &state)
        case .case2Reducer(let reducer):
            reducer.apply(action, to: &state)
        case .case3Reducer(let reducer):
            reducer.apply(action, to: &state)
        case .defaultReducer(let reducer):
            reducer.apply(action, to: &state)
        }
    }
    
    @inlinable
    public static func defaultReducer<State, Action>() -> Self where R4 == NopReducer<State, Action> {
        .defaultReducer(NopReducer())
    }
    
}



public extension Reducers.Native {
    
    static func ifReducer<R1 : ReducerProtocol, R2 : ReducerProtocol>(_ r1: R1, otherType: R2.Type = R2.self) -> IfReducer<R1, R2> {
        IfReducer.ifReducer(r1)
    }
    
    static func elseReducer<R1 : ReducerProtocol, R2 : ReducerProtocol>(_ r2: R2, otherType: R1.Type = R1.self) -> IfReducer<R1, R2> {
        IfReducer.elseReducer(r2)
    }
    
}

*/
#endif
