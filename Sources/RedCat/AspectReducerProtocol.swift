//
//  AspectReducer.swift
//  
//
//  Created by Markus Pfeifer on 05.05.21.
//

import CasePaths


public protocol AspectReducerProtocol : ReducerProtocol {
    
    associatedtype State
    associatedtype Action
    associatedtype Aspect
    
    var casePath : CasePath<State, Aspect> {get}
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


public protocol AspectReducerWrapper : ErasedReducer {
    
    associatedtype Body : ErasedReducer
    
    var casePath : CasePath<State, Body.State> {get}
    var body : Body {get}
    
}


public extension AspectReducerWrapper where State : Releasable {
    
    @inlinable
    func applyErased<Action : ActionProtocol>(_ action: Action,
                                              to state: inout State) {
        casePath.mutate(&state) {aspect in
            body.applyErased(action, to: &aspect)
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
    
    @inlinable
    public init<Aspect, Action : ActionProtocol>(_ aspect: CasePath<State, Aspect>,
                                                 closure: @escaping (Action, inout Aspect) -> Void)
    where Reducer == ClosureReducer<Aspect, Action> {
        self.casePath = aspect
        self.body = ClosureReducer(closure)
    }
    
}


public extension ErasedReducer {
    
    func bind<Root>(to aspect: CasePath<Root, State>) -> AspectReducer<Root, Self> {
        AspectReducer(aspect, reducer: self)
    }
    
}


public extension Reducers.Native {
    
    func detailReducer<State : Releasable, Aspect, Action : ActionProtocol>(_ aspect: CasePath<State, Aspect>,
                                                               _ closure: @escaping (Action, inout Aspect) -> Void)
    -> AspectReducer<State, ClosureReducer<Aspect, Action>> {
        AspectReducer(aspect, closure: closure)
    }
    
}
