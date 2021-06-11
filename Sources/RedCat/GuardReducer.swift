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
                      to state: inout Wrapped.State) {
        guard condition(state) else {
            return
        }
        wrapped.apply(action, to: &state)
    }
    
}


public extension Reducers.Native {
    
    static func guarded<Wrapped : ReducerProtocol>(_ reducer: Wrapped,
                                                 where condition: @escaping (Wrapped.State) -> Bool) -> GuardReducer<Wrapped> {
        GuardReducer(reducer, where: condition)
    }
    
}


public extension DetailReducer {
    
    init<Reducer : ReducerProtocol>(_ detail: WritableKeyPath<State, Reducer.State>,
                                  where condition: @escaping (Reducer.State) -> Bool,
                                  build: @escaping () -> Reducer) where Self.Body == GuardReducer<Reducer> {
        self = DetailReducer(detail, reducer: GuardReducer(where: condition, build: build))
    }
    
}

public extension AspectReducer {
    
    init<Reducer : ReducerProtocol>(_ aspect: CasePath<State, Reducer.State>,
                                  where condition: @escaping (Reducer.State) -> Bool,
                                  build: @escaping () -> Reducer) where Self.Body == GuardReducer<Reducer> {
        self = AspectReducer(aspect, reducer: GuardReducer(where: condition, build: build))
    }
}

public extension Reducer {
    
    init<State, Wrapped : ReducerProtocol>(_ detail: WritableKeyPath<State, Wrapped.State>,
                                         where condition: @escaping (Wrapped.State) -> Bool,
                                         build: @escaping () -> Wrapped) where Body == DetailReducer<State, GuardReducer<Wrapped>> {
        self = Reducer {
            DetailReducer(detail, where: condition, build: build)
        }
    }
    
    
    init<State, Wrapped : ReducerProtocol>(_ aspect: CasePath<State, Wrapped.State>,
                                         where condition: @escaping (Wrapped.State) -> Bool,
                                         build: @escaping () -> Wrapped) where Body == AspectReducer<State, GuardReducer<Wrapped>> {
        self = Reducer {
            AspectReducer(aspect, where: condition, build: build)
        }
    }
    
}


public extension ReducerProtocol {
    
    /// Handles actions only when the state satisfies some condition.
    func filter(_ condition: @escaping (State) -> Bool) -> GuardReducer<Self> {
        GuardReducer(self, where: condition)
    }
    
    func compose<Next : ReducerProtocol>(with next: Next,
                                       where condition: @escaping (State) -> Bool)
    -> ComposedReducer<Self, GuardReducer<Next>> where State == Next.State {
        compose(with: next.filter(condition))
    }
    
    func compose<Next : ReducerProtocol>(with next: Next,
                                       property: WritableKeyPath<State, Next.State>,
                                       where condition: @escaping (State) -> Bool)
    -> ComposedReducer<Self, GuardReducer<DetailReducer<State, Next>>> {
        compose(with: next.bind(to: property).filter(condition))
    }
    
    func compose<Next : ReducerProtocol>(with next: Next,
                                       property: WritableKeyPath<State, Next.State>,
                                       where condition: @escaping (Next.State) -> Bool)
    -> ComposedReducer<Self, DetailReducer<State, GuardReducer<Next>>> {
        compose(with: next.filter(condition).bind(to: property))
    }
    
    func compose<Next : ReducerProtocol>(with next: Next,
                                       aspect: CasePath<State, Next.State>,
                                       where condition: @escaping (Next.State) -> Bool)
    -> ComposedReducer<Self, AspectReducer<State, GuardReducer<Next>>> where State : Emptyable {
        compose(with: next.filter(condition).bind(to: aspect))
    }
    
}
