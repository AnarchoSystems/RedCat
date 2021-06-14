//
//  Reducer.swift
//  
//
//  Created by Markus Pfeifer on 05.05.21.
//

import CasePaths


/// ```ReducerProtocol``` is the fundamental building block of RedCat apps. An instance of ```ReducerProtocol``` holds the actual implementation of what should happen to the ```State``` when a specific action is received.
public protocol ReducerProtocol {
    
    associatedtype State 
    associatedtype Action
    
    /// Applies an action to the state.
    /// - Parameters:
    ///     - action: The action to apply.
    ///     - state: The state to modify.
    ///
    /// The main idea of unidirectional dataflow architectures is that everything that happens in an application can be viewed as a long list of actions applied over time to one global app state, as the new actions become available. For this, you need some function with a signature similar to that of ```Sequence```'s ```reduce```method -- hence the name "reducer".
    ///
    /// Typically, you don't write one large app reducer for your global state, but compose it up from smaller reducers using partial actions and partial state. ```ReducerProtocol``` and inheriting protocols are the main way to implement what it means concretely to apply a specific action. Everything else is really about composition.
    func apply(_ action: Action,
               to state: inout State)
    
}

public extension ReducerProtocol {
    
    func applyAll<S : Sequence>(_ actions: S,
                                to state: inout State) where S.Element == Action {
        for action in actions {
            apply(action, to: &state)
        }
    }
    
}

public extension ReducerProtocol {
    
    /// Composes this reducer with another one.
    /// - Parameters:
    ///     - next: The other reducer.
    /// - Returns: A reducer capable to handle all the actions the two individual reducers can handle. If there are actions handled by both reducers, they are handled in sequence.
    @inlinable
    func compose<Next: ReducerProtocol>(with next: Next) -> ComposedReducer<Self, Next> where
        Next.State == State, Next.Action == Action {
        ComposedReducer(self, next)
    }
    
    /// Composes this reducer with another one.
    /// - Parameters:
    ///     - next: The other reducer.
    ///     - property: The property to which the other reducer is bound.
    /// - Returns: A reducer capable to handle all the actions the two individual reducers can handle. If there are actions handled by both reducers, they are handled in sequence.
    @inlinable
    func compose<Next : ReducerProtocol>(with next: Next,
                                       property: WritableKeyPath<State, Next.State>)
    -> ComposedReducer<Self, DetailReducer<State, Next>> where Next.Action == Action {
        compose(with: next.bind(to: property))
    }
    
    /// Composes this reducer with another one.
    /// - Parameters:
    ///     - next: The other reducer.
    ///     - aspect: The aspect to which the other reducer is bound.
    /// - Returns: A reducer capable to handle all the actions the two individual reducers can handle. If there are actions handled by both reducers, they are handled in sequence.
    @inlinable
    func compose<Next : ReducerProtocol>(with next: Next,
                                         aspect: CasePath<State, Next.State>)
    -> ComposedReducer<Self, AspectReducer<State, Next>> where State : Releasable, Next.Action == Action {
        compose(with: next.bind(to: aspect))
    }
    
}


public struct ComposedReducer<R1 : ReducerProtocol, R2 : ReducerProtocol> : ReducerProtocol where R1.State == R2.State, R1.Action == R2.Action {
    
    @usableFromInline
    let re1 : R1
    @usableFromInline
    let re2 : R2
    
    @usableFromInline
    init(_ re1: R1, _ re2: R2) {(self.re1, self.re2) = (re1, re2)}
    
    @inlinable
    public func apply(_ action: R1.Action, to state: inout R1.State) {
        re1.apply(action, to: &state)
        re2.apply(action, to: &state)
    }
    
}
