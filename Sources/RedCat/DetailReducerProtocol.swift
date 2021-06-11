//
//  DetailReducer.swift
//  
//
//  Created by Markus Pfeifer on 05.05.21.
//

import Foundation
import CasePaths


/// ```DetailReducerProtocol``` is a type used for direct composition. It requires an implementation of what should happen to the state given a specific action, but it applies the action to a given keypath of a more global state.
public protocol DetailReducerProtocol : ReducerProtocol {
    
    associatedtype State
    associatedtype Detail
    associatedtype DetailAction
    associatedtype Action
    
    /// The property of ```State``` for which this reducer is used.
    var keyPath : WritableKeyPath<State, Detail> {get}
    var matchAction : CasePath<Action, DetailAction> {get}
    
    /// Applies an action to the state.
    /// - Parameters:
    ///     - action: The action to apply.
    ///     - detail: The property to change.
    ///
    /// The main idea of unidirectional dataflow architectures is that everything that happens in an application can be viewed as a long list of actions applied over time to one global app state, as the new actions become available. For this, you need some function with a signature similar to that of ```Sequence```'s ```reduce```method -- hence the name "reducer".
    ///
    /// Typically, you don't write one large app reducer for your global state, but compose it up from smaller reducers using partial actions and partial state. ```DetailReducerProtocol``` is a way to mutate just one property of a more global state type.
    func apply(_ action: DetailAction,
               to detail: inout Detail)
    
}


public extension DetailReducerProtocol where Action == DetailAction {
    
    @inlinable
    var matchAction : CasePath<Action, DetailAction> {
        /{$0}
    }
    
}


public extension DetailReducerProtocol {
    
    @inlinable
    func apply(_ action: Action,
               to state: inout State) {
        guard let action = matchAction.extract(from: action) else {return}
        apply(action, to: &state[keyPath: keyPath])
    }
    
}

/// A ```DetailReducerWrapper``` is a type used for indirect composition. The implementation of what should happen to the state given an ```Action``` is given via the ```body``` property, and the wrapper's single responsibility is delegating the given keypath.
public protocol DetailReducerWrapper : ReducerProtocol {
    
    associatedtype State
    associatedtype Action = Body.Action
    associatedtype Body : ReducerProtocol
    
    /// The property of ```State``` for which this reducer is used.
    var keyPath : WritableKeyPath<State, Body.State> {get}
    var matchAction : CasePath<Action, Body.Action> {get}
    
    /// The reducer to apply to ```keyPath``` of ```State```.
    var body : Body {get}
    
}


public extension DetailReducerWrapper where Action == Body.Action {
    
    @inlinable
    var matchAction : CasePath<Action, Body.Action> {
        /{$0}
    }
    
}


public extension DetailReducerWrapper {
    
    @inlinable
    func apply(_ action: Action,
                     to state: inout State) {
        guard let action = matchAction.extract(from: action) else {return}
            body.apply(action, to: &state[keyPath: keyPath])
    }
    
}


/// An "anonymous" ```DetailReducerWrapper```.
public struct DetailReducer<State, Reducer : ReducerProtocol, Action> : DetailReducerWrapper {
    
    public let keyPath: WritableKeyPath<State, Reducer.State>
    public let matchAction: CasePath<Action, Reducer.Action>
    public let body : Reducer
    
    @inlinable
    public init(_ detail: WritableKeyPath<State, Reducer.State>,
                matchAction: @escaping (Reducer.Action) -> Action,
                reducer: Reducer) {
        self.keyPath = detail
        self.matchAction = /matchAction
        self.body = reducer
    }
    
    @inlinable
    public init(_ detail: WritableKeyPath<State, Reducer.State>,
                matchAction: @escaping (Reducer.Action) -> Action,
                build: @escaping () -> Reducer) {
        self.keyPath = detail
        self.matchAction = /matchAction
        self.body = build()
    }
    
    @inlinable
    public init<Detail, Action>(_ detail: WritableKeyPath<State, Detail>,
                                matchAction: @escaping (Action) -> Self.Action,
                                closure: @escaping (Action, inout Detail) -> Void)
    where Reducer == ClosureReducer<Detail, Action> {
        self.keyPath = detail
        self.matchAction = /matchAction
        self.body = ClosureReducer(closure)
    }
    
}

public extension DetailReducer where Action == Reducer.Action {
    
    @inlinable
    init(_ detail: WritableKeyPath<State, Reducer.State>,
                reducer: Reducer) {
        self = DetailReducer(detail,
                             matchAction: {$0},
                             reducer: reducer)
    }
    
    @inlinable
    init(_ detail: WritableKeyPath<State, Reducer.State>,
                build: @escaping () -> Reducer) {
        self.keyPath = detail
        self.matchAction = /{$0}
        self.body = build()
    }
    
    @inlinable
    init<Aspect, Action>(_ detail: WritableKeyPath<State, Aspect>,
                        closure: @escaping (Action, inout Aspect) -> Void)
    where Reducer == ClosureReducer<Aspect, Action> {
        self.keyPath = detail
        self.matchAction = /{$0}
        self.body = ClosureReducer(closure)
    }
    
}

public extension ReducerProtocol {
    
    @inlinable
    func bind<Root, A>(to property: WritableKeyPath<Root, State>,
                       where match: @escaping (Action) -> A) -> DetailReducer<Root, Self, A> {
        DetailReducer(property, matchAction: match, reducer: self)
    }
    
    @inlinable
    func bind<Root>(to property: WritableKeyPath<Root, State>) -> DetailReducer<Root, Self, Action> {
        DetailReducer(property, reducer: self)
    }
    
}


public extension Reducers.Native {
    
    static func detailReducer<State, Detail, Action>(_ detail: WritableKeyPath<State, Detail>,
                                             _ closure: @escaping (Action, inout Detail) -> Void)
    -> DetailReducer<State, ClosureReducer<Detail, Action>, Action> {
        DetailReducer(detail, closure: closure)
    }
    
}
