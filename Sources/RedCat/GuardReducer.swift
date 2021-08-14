//
//  GuardReducer.swift
//  
//
//  Created by Markus Pfeifer on 16.05.21.
//

import Foundation
import CasePaths


/// Applies actions only when the state matches some condition.
public struct GuardReducer<Wrapped : ReducerProtocol> : ReducerProtocol {
    
    @usableFromInline
    let condition : (Wrapped.State) -> Bool
    @usableFromInline
    let wrapped : Wrapped
    
    @inlinable
    public init(_ reducer: Wrapped, where condition: @escaping (Wrapped.State) -> Bool) {
        self.condition = condition
        self.wrapped = reducer
    }
    
    @inlinable
    public init(where condition: @escaping (Wrapped.State) -> Bool, build: () -> Wrapped) {
        self = GuardReducer(build(), where: condition)
    }
    
    @inlinable
    public func apply(_ action: Wrapped.Action,
                      to state: inout Wrapped.State) -> Wrapped.Response? {
        guard condition(state) else {
            return nil
        }
        return wrapped.apply(action, to: &state)
    }
    
}


public extension Reducers.Native {
    
    static func guarded<Wrapped : ReducerProtocol>(_ reducer: Wrapped,
                                                   where condition: @escaping (Wrapped.State) -> Bool) -> GuardReducer<Wrapped> {
        GuardReducer(where: condition) {reducer}
    }
    
}


public extension Reducer {
    
    init<State, Wrapped : ReducerProtocol>(_ detail: WritableKeyPath<State, Wrapped.State>,
                                           where condition: @escaping (State) -> Bool,
                                           build: @escaping () -> Wrapped) where Body == GuardReducer<DetailReducer<State, Wrapped>> {
        self = Reducer {
            Reducers.Native.guarded(DetailReducer(detail, build: build), where: condition)
        }
    }
    
    
    init<State, Wrapped : ReducerProtocol>(preservingResponse aspect: CasePath<State, Wrapped.State>,
                                           where condition: @escaping (State) -> Bool,
                                           build: @escaping () -> Wrapped) where Body == GuardReducer<AspectReducer<State, Wrapped>> {
        self = Reducer {
            AspectReducer(aspect, build: build).filter(condition)
        }
    }
    
    
    init<State, Wrapped : ReducerProtocol>(_ aspect: CasePath<State, Wrapped.State>,
                                           where condition: @escaping (State) -> Bool,
                                           build: @escaping () -> Wrapped) where Body == GuardReducer<ResponseMapReducer<AspectReducer<State, Wrapped>, Void>> {
        self = Reducer {
            AspectReducer(aspect, build: build).mapResponse{_ in }.filter(condition)
        }
    }
    
}


public extension ReducerProtocol {
    
    /// Handles actions only when the state satisfies some condition.
    func filter(_ condition: @escaping (State) -> Bool) -> GuardReducer<Self> {
        GuardReducer(self, where: condition)
    }
    
}
