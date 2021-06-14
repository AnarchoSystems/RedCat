//
//  AspectReducer.swift
//  
//
//  Created by Markus Pfeifer on 05.05.21.
//

import CasePaths


/// ```AspectReducerProtocol``` is a type used for direct composition. It requires an implementation of what should happen to the state given a specific action, but it will only be executed if the state matches a certain enum case - the associated data is then handed to the implementation.
public protocol AspectReducerProtocol : ReducerProtocol {
    
    associatedtype State
    associatedtype Action
    associatedtype Aspect
    
    /// The enum case of the enum-typed ```State``` for which this reducer is used.
    var casePath : CasePath<State, Aspect> {get}
    
    /// Applies an action to the state.
    /// - Parameters:
    ///     - action: The action to apply.
    ///     - aspect: The case to modify when present.
    ///
    /// The main idea of unidirectional dataflow architectures is that everything that happens in an application can be viewed as a long list of actions applied over time to one global app state, as the new actions become available. For this, you need some function with a signature similar to that of ```Sequence```'s ```reduce```method -- hence the name "reducer".
    ///
    /// Typically, you don't write one large app reducer for your global state, but compose it up from smaller reducers using partial actions and partial state. ```AspectReducerProtocol``` is a way to mutate an enum-typed state whenever it is in a specific case.
    func apply(_ action: Action,
               to aspect: inout Aspect)
    
}


public extension AspectReducerProtocol where State : Releasable {
    
    @inlinable
    func apply(_ action: Action,
               to state: inout State) {
        casePath.mutate(&state) {aspect in
            apply(action, to: &aspect)
        }
    }
    
}

/// An ```AspectReducerWrapper``` is a type used for indirect composition. The implementation of what should happen to the state given an ```Action``` is given via the ```body``` property, and the wrapper's single responsibility is delegating the action to the body whenever the state matches a certain enum case.
public protocol AspectReducerWrapper : ReducerProtocol where Action == Body.Action {
    
    associatedtype State
    associatedtype Action = Body.Action
    associatedtype Body : ReducerProtocol
    
    /// The enum case of the enum-typed ```State``` for which this reducer is used.
    var casePath : CasePath<State, Body.State> {get}
    
    /// The reducer to apply to the ```State``` whenever ```casePath``` is matched.
    var body : Body {get}
    
}

public extension AspectReducerWrapper where State : Releasable {
    
    @inlinable
    func apply(_ action: Body.Action,
               to state: inout State) {
        casePath.mutate(&state) {aspect in
            body.apply(action, to: &aspect)
        }
    }
    
}


/// An "anonymous" ```AspectReducerWrapper```.
public struct AspectReducer<State : Releasable, Reducer : ReducerProtocol> : AspectReducerWrapper {
    
    public let casePath : CasePath<State, Reducer.State>
    public let body : Reducer
    
    @inlinable
    public init(_ casePath: CasePath<State, Reducer.State>,
                reducer: Reducer) {
        self.casePath = casePath
        self.body = reducer
    }
    
    @inlinable
    public init(_ casePath: CasePath<State, Reducer.State>,
                build: () -> Reducer) {
        self = AspectReducer(casePath, reducer: build())
    }
    
    @inlinable
    public init<Aspect, Action>(_ aspect: CasePath<State, Aspect>,
                        closure: @escaping (Action, inout Aspect) -> Void)
    where Reducer == ClosureReducer<Aspect, Action> {
        self = AspectReducer(aspect) {
            ClosureReducer(closure)
        }
    }
    
}


public extension ReducerProtocol {
    
    func bind<Root>(to aspect: CasePath<Root, State>) -> AspectReducer<Root, Self> {
        AspectReducer(aspect, reducer: self)
    }
    
}


public extension Reducers.Native {
    
    static func aspectReducer<State : Releasable, Aspect, Action>(_ aspect: CasePath<State, Aspect>,
                                                               _ closure: @escaping (Action, inout Aspect) -> Void)
    -> AspectReducer<State, ClosureReducer<Aspect, Action>> {
        AspectReducer(aspect, closure: closure)
    }
    
}
