//
//  AspectReducer.swift
//  
//
//  Created by Markus Pfeifer on 05.05.21.
//

import CasePaths



public protocol DependentAspectReducer : ErasedReducer {
    
    associatedtype Aspect
    associatedtype Action : ActionProtocol
    
    var casePath : CasePath<State, Aspect> {get}
    func apply(_ action: Action,
               to aspect: inout Aspect,
               environment: Dependencies)
    
}


public extension DependentAspectReducer where State : Releasable {
    
    @inlinable
    func applyErased<Action : ActionProtocol>(_ action: Action,
                                              to state: inout State,
                                              environment: Dependencies) {
        guard Action.self == Self.Action.self else {
            return
        }
        casePath.mutate(&state) {aspect in
            apply(action as! Self.Action, to: &aspect, environment: environment)
        }
    }
    
    @inlinable
    func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
        action is Self.Action
    }
    
}

public protocol AspectReducerProtocol : ErasedReducer {
    
    associatedtype Aspect
    associatedtype Action : ActionProtocol
    
    var casePath : CasePath<State, Aspect> {get}
    func apply(_ action: Action,
               to aspect: inout Aspect)
    
}


public extension AspectReducerProtocol where State : Releasable {
    
    @inlinable
    func applyErased<Action : ActionProtocol>(_ action: Action,
                                              to state: inout State,
                                              environment: Dependencies) {
        guard Action.self == Self.Action.self else {
            return
        }
        casePath.mutate(&state) {aspect in
            apply(action as! Self.Action, to: &aspect)
        }
    }
    
    @inlinable
    func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
        action is Self.Action
    }
    
}


public protocol AspectReducerWrapper : ErasedReducer {
    
    associatedtype Body : ErasedReducer
    
    var casePath : CasePath<State, Body.State> {get}
    var body : Body {get}
    
}


public extension AspectReducerWrapper where State : Releasable {
    
    @inlinable
    func applyErased<Action : ActionProtocol>(_ action: Action,
                                              to state: inout State,
                                              environment: Dependencies) {
        casePath.mutate(&state) {aspect in
            body.applyErased(action, to: &aspect, environment: environment)
        }
    }
    
    @inlinable
    func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
        body.acceptsAction(action)
    }
    
}


public struct AspectReducer<State : Releasable, Reducer : ErasedReducer> : AspectReducerWrapper {
    
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
                build: @escaping () -> Reducer) {
        self.casePath = casePath
        self.body = build()
    }
    
}


public extension ErasedReducer {
    
    func bind<Root>(to property: CasePath<Root, State>) -> AspectReducer<Root, Self> {
        AspectReducer(property, reducer: self)
    }
    
}
