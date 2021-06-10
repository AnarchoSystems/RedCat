//
//  DetailReducer.swift
//  
//
//  Created by Markus Pfeifer on 05.05.21.
//

import Foundation


/// ```DetailReducerProtocol``` is a type used for direct composition. It requires an implementation of what should happen to the state given a specific action, but it applies the action to a given keypath of a more global state.
public protocol DetailReducerProtocol : ReducerProtocol {
    
    associatedtype State
    associatedtype Detail
    associatedtype Action
    
    /// The property of ```State``` for which this reducer is used.
    var keyPath : WritableKeyPath<State, Detail> {get}
    
    /// Applies an action to the state.
    /// - Parameters:
    ///     - action: The action to apply.
    ///     - detail: The property to change.
    ///
    /// The main idea of unidirectional dataflow architectures is that everything that happens in an application can be viewed as a long list of actions applied over time to one global app state, as the new actions become available. For this, you need some function with a signature similar to that of ```Sequence```'s ```reduce```method -- hence the name "reducer".
    ///
    /// Typically, you don't write one large app reducer for your global state, but compose it up from smaller reducers using partial actions and partial state. ```DetailReducerProtocol``` is a way to mutate just one property of a more global state type.
    func apply(_ action: Action,
               to detail: inout Detail)
    
}


public extension DetailReducerProtocol {
    
    @inlinable
    func apply(_ action: Action,
               to state: inout State) {
        apply(action, to: &state[keyPath: keyPath])
    }
    
}

/// A ```DetailReducerWrapper``` is a type used for indirect composition. The implementation of what should happen to the state given an ```Action``` is given via the ```body``` property, and the wrapper's single responsibility is delegating the given keypath.
public protocol DetailReducerWrapper : ErasedReducer {
    
    associatedtype Body : ErasedReducer
    
    /// The property of ```State``` for which this reducer is used.
    var keyPath : WritableKeyPath<State, Body.State> {get}
    
    /// The reducer to apply to ```keyPath``` of ```State```.
    var body : Body {get}
    
}


public extension DetailReducerWrapper {
    
    @inlinable
    func applyErased<Action : ActionProtocol>(_ action: Action,
                                              to state: inout State) {
        body.applyErased(action, to: &state[keyPath: keyPath])
    }
    
    func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
        body.acceptsAction(action)
    }
    
}


/// An "anonymous" ```DetailReducerWrapper```.
public struct DetailReducer<State, Reducer : ErasedReducer> : DetailReducerWrapper {
    
    public let keyPath: WritableKeyPath<State, Reducer.State>
    public let body : Reducer
    
    @inlinable
    public init(_ detail: WritableKeyPath<State, Reducer.State>, reducer: Reducer) {
        self.keyPath = detail
        self.body = reducer
    }
    
    @inlinable
    public init(_ detail: WritableKeyPath<State, Reducer.State>, build: @escaping () -> Reducer) {
        self.keyPath = detail
        self.body = build()
    }
    
    @inlinable
    public init<Detail, Action : ActionProtocol>(_ detail: WritableKeyPath<State, Detail>,
                                                 closure: @escaping (Action, inout Detail) -> Void)
    where Reducer == ClosureReducer<Detail, Action> {
        self.keyPath = detail
        self.body = ClosureReducer(closure)
    }
    
}


public extension ErasedReducer {
    
    @inlinable
    func bind<Root>(to property: WritableKeyPath<Root, State>) -> DetailReducer<Root, Self> {
        DetailReducer(property, reducer: self)
    }
    
}


public extension Reducers.Native {
    
    static func detailReducer<State, Detail, Action : ActionProtocol>(_ detail: WritableKeyPath<State, Detail>,
                                                               _ closure: @escaping (Action, inout Detail) -> Void)
    -> DetailReducer<State, ClosureReducer<Detail, Action>> {
        DetailReducer(detail, closure: closure)
    }
    
}
