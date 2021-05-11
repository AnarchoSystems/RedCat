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


public extension DependentAspectReducer where State : Emptyable {
    
    func apply<Action : ActionProtocol>(_ action: Action,
                                        to state: inout State,
                                        environment: Dependencies) {
        guard let action = action as? Self.Action else {return}
        casePath.mutate(&state) {aspect in
            apply(action, to: &aspect, environment: environment)
        }
    }
    
    func acceptsAction<Action : ActionProtocol>(ofType type: Action.Type) -> Bool {
        type == Self.Action.self
    }
    
}

public protocol AspectReducer : ErasedReducer {
    
    associatedtype Aspect
    associatedtype Action : ActionProtocol
    
    var casePath : CasePath<State, Aspect> {get}
    func apply(_ action: Action,
               to aspect: inout Aspect)
    
}


public extension AspectReducer where State : Emptyable {
    
    func apply<Action : ActionProtocol>(_ action: Action,
                                        to state: inout State,
                                        environment: Dependencies) {
        guard let action = action as? Self.Action else {return}
        casePath.mutate(&state) {aspect in
            apply(action, to: &aspect)
        }
    }
    
    func acceptsAction<Action : ActionProtocol>(ofType type: Action.Type) -> Bool {
        type == Self.Action.self
    }
    
}


public protocol AspectReducerWrapper : ErasedReducer {
    
    associatedtype Body : ErasedReducer
    
    var casePath : CasePath<State, Body.State> {get}
    var body : Body {get}
    
}


public extension AspectReducerWrapper where State : Emptyable {
    
    @inlinable
    func apply<Action : ActionProtocol>(_ action: Action,
                                        to state: inout State,
                                        environment: Dependencies) {
        casePath.mutate(&state) {aspect in
            body.apply(action, to: &aspect, environment: environment)
        }
    }
    
    func acceptsAction<Action : ActionProtocol>(ofType type: Action.Type) -> Bool {
        body.acceptsAction(ofType: type)
    }
    
}


public struct PrismReducer<State : Emptyable, Reducer : ErasedReducer> : AspectReducerWrapper {
    
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

public protocol DependentClassCaseReducer : ErasedReducer {
    
    associatedtype Aspect : AnyObject
    associatedtype Action : ActionProtocol
    
    var casePath : CasePath<State, Aspect> {get}
    func apply(_ action: Action,
               to aspect: Aspect,
               environment: Dependencies)
    
}


public extension DependentClassCaseReducer {
    
    func apply<Action : ActionProtocol>(_ action: Action,
                                        to state: inout State,
                                        environment: Dependencies) {
        guard let action = action as? Self.Action else {return}
        casePath.mutate(state) {aspect in
            apply(action, to: aspect, environment: environment)
        }
    }
    
    func acceptsAction<Action : ActionProtocol>(ofType type: Action.Type) -> Bool {
        type == Self.Action.self
    }
    
}

public protocol ClassCaseReducer : ErasedReducer {
    
    associatedtype Aspect : AnyObject
    associatedtype Action : ActionProtocol
    
    var casePath : CasePath<State, Aspect> {get}
    func apply(_ action: Action,
               to aspect: Aspect)
    
}


public extension ClassCaseReducer {
    
    func apply<Action : ActionProtocol>(_ action: Action,
                                        to state: inout State,
                                        environment: Dependencies) {
        guard let action = action as? Self.Action else {return}
        casePath.mutate(state) {aspect in
            apply(action, to: aspect)
        }
    }
    
    func acceptsAction<Action : ActionProtocol>(ofType type: Action.Type) -> Bool {
        type == Self.Action.self
    }
    
}


public protocol ClassCaseReducerWrapper : ErasedReducer {
    
    associatedtype Body : ErasedClassReducer
    
    var casePath : CasePath<State, Body.State> {get}
    var body : Body {get}
    
}


public extension ClassCaseReducerWrapper {
    
    func apply<Action : ActionProtocol>(_ action: Action,
                                        to state: inout State,
                                        environment: Dependencies) {
        casePath.mutate(state) {aspect in
            body.apply(action, to: aspect, environment: environment)
        }
    }
    
    func acceptsAction<Action : ActionProtocol>(ofType type: Action.Type) -> Bool {
        body.acceptsAction(ofType: type)
    }
    
}


public struct ClassPrismReducer<State, Reducer : DependentClassReducer> : ClassCaseReducerWrapper {
    
    public let casePath: CasePath<State, Reducer.State>
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
