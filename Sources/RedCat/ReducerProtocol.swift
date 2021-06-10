//
//  Reducer.swift
//  
//
//  Created by Markus Pfeifer on 05.05.21.
//

import CasePaths

/// ```ErasedReducer```s act as a currency type for RedCat apps. An ```ErasedReducer``` is aware of the ```State``` it can mutate whenever it receives an ```Action```.
public protocol ErasedReducer {
    
    associatedtype State
    
    /// Applies an action to the state.
    /// - Parameters:
    ///     - action: The action to apply.
    ///     - state: The state to modify.
    ///
    /// The main idea of unidirectional dataflow architectures is that everything that happens in an application can be viewed as a long list of actions applied over time to one global app state, as the new actions become available. For this, you need some function with a signature similar to that of ```Sequence```'s ```reduce```method -- hence the name "reducer".
    /// Typically, you don't write one large app reducer for your global state, but compose it up from smaller reducers using partial actions and partial state. In order to make the "partial actions" part easy, RedCat made ```applyErased``` a generic function that doesn't care what actions the reducer receives. The possibility of applying invalid actions can be mitigated by using proper namespacing and debugging tools such as ```UnrecognizedActionsDebugger```. The advantage of using a generic function rather than sending ```Any``` or ```ActionProtocol``` is that at least in theory this method can be specialized by the compiler for each concrete ```Action``` type with that it is actually called.
    func applyErased<Action : ActionProtocol>(_ action: Action,
                                              to state: inout State)
    
    /// Indicates if the reducer actually accepts the given action.
    /// - Parameters:
    ///     - action: The action in question.
    ///
    /// This method is part of the public interface of ```ErasedReducer``` so you can customize it. Reducer protocols with an associated action type will just evaluate if the type of action matches the expected type by default. Reducer wrappers will test, if the wrapped reducer accepts the action.
    ///
    /// There shouldn't be a need to call this function directly (except if you write new reducer wrappers that can't adopt one of the existing reducer wrapper protocols). You can attach an ```UnrecognizedActionsDebugger``` to your store if there are any doubts.
    func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool
    
}


public extension ErasedReducer {
    
    @inlinable
    func applyDynamic(_ action: ActionProtocol,
                      to state: inout State) {
        action.apply(to: &state, using: self)
    }
    
    @inlinable
    func acceptsActionDynamic(_ action: ActionProtocol) -> Bool {
        action.accepts(using: self)
    }
}


extension ActionProtocol {
    
    @usableFromInline
    func apply<Reducer : ErasedReducer>(to state: inout Reducer.State,
                                        using reducer: Reducer) {
        reducer.applyErased(self, to: &state)
    }
    
    @inlinable
    func accepts<Reducer : ErasedReducer>(using reducer: Reducer) -> Bool {
        reducer.acceptsAction(self)
    }
    
}


/// ```ReducerProtocol``` is the fundamental building block of RedCat apps. An instance of ```ReducerProtocol``` holds the actual implementation of what should happen to the ```State``` when a specific action is received.
public protocol ReducerProtocol : ErasedReducer {
    
    associatedtype State 
    associatedtype Action : ActionProtocol
    
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
    
    @inlinable
    func applyErased<Action : ActionProtocol>(_ action: Action,
                                              to state: inout State) {
        guard Action.self == Self.Action.self else {
            return
        }
        apply(action as! Self.Action, to: &state)
    }
    
    @inlinable
    func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
        action is Self.Action
    }
    
}


public extension ErasedReducer {
    
    /// Composes this reducer with another one.
    /// - Parameters:
    ///     - next: The other reducer.
    /// - Returns: A reducer capable to handle all the actions the two individual reducers can handle. If there are actions handled by both reducers, they are handled in sequence.
    @inlinable
    func compose<Next: ErasedReducer>(with next: Next) -> ComposedReducer<Self, Next> where Next.State == State {
        ComposedReducer(self, next)
    }
    
    /// Composes this reducer with another one.
    /// - Parameters:
    ///     - next: The other reducer.
    ///     - property: The property to which the other reducer is bound.
    /// - Returns: A reducer capable to handle all the actions the two individual reducers can handle. If there are actions handled by both reducers, they are handled in sequence.
    @inlinable
    func compose<Next : ErasedReducer>(with next: Next,
                                       property: WritableKeyPath<State, Next.State>)
    -> ComposedReducer<Self, DetailReducer<State, Next>> {
        compose(with: next.bind(to: property))
    }
    
    /// Composes this reducer with another one.
    /// - Parameters:
    ///     - next: The other reducer.
    ///     - aspect: The aspect to which the other reducer is bound.
    /// - Returns: A reducer capable to handle all the actions the two individual reducers can handle. If there are actions handled by both reducers, they are handled in sequence.
    @inlinable
    func compose<Next : ErasedReducer>(with next: Next,
                                       aspect: CasePath<State, Next.State>)
    -> ComposedReducer<Self, AspectReducer<State, Next>> where State : Releasable {
        compose(with: next.bind(to: aspect))
    }
    
}


public struct ComposedReducer<R1 : ErasedReducer, R2 : ErasedReducer> : ErasedReducer where R1.State == R2.State {
    
    @usableFromInline
    let re1 : R1
    @usableFromInline
    let re2 : R2
    
    @usableFromInline
    init(_ re1: R1, _ re2: R2) {(self.re1, self.re2) = (re1, re2)}
    
    @inlinable
    public func applyErased<Action : ActionProtocol>(_ action: Action, to state: inout R1.State) {
        re1.applyErased(action, to: &state)
        re2.applyErased(action, to: &state)
    }
    
    @inlinable
    public func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
        re1.acceptsAction(action)
            || re2.acceptsAction(action)
    }
    
}
