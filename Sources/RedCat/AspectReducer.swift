//
//  AspectReducer.swift
//  
//
//  Created by Markus Pfeifer on 05.05.21.
//

import CasePaths



public protocol DependentAspectReducer : DependentReducer {
    
    associatedtype Aspect
    associatedtype Action : ActionProtocol
    
    var casePath : CasePath<State, Aspect>{get}
    func apply(_ action: Action,
               to aspect: inout Aspect,
               environment: Dependencies)
    
}


public extension DependentAspectReducer where State : Emptyable {
    
    func apply<Action : ActionProtocol>(_ action: Action,
                       to state: inout State,
                       environment: Dependencies) {
        guard let action = action as? Self.Action else{return}
        casePath.mutate(&state){aspect in
            apply(action, to: &aspect, environment: environment)
        }
    }
    
}

public protocol AspectReducer : DependentReducer {
    
    associatedtype Aspect
    associatedtype Action : ActionProtocol
    
    var casePath : CasePath<State, Aspect>{get}
    func apply(_ action: Action,
               to aspect: inout Aspect)
    
}


public extension AspectReducer where State : Emptyable {
    
    func apply<Action : ActionProtocol>(_ action: Action,
                       to state: inout State,
                       environment: Dependencies) {
        guard let action = action as? Self.Action else{return}
        casePath.mutate(&state){aspect in
            apply(action, to: &aspect)
        }
    }
    
}


public protocol AspectReducerWrapper : DependentReducer {
    
    associatedtype Body : DependentReducer
    
    var casePath : CasePath<State, Body.State>{get}
    var body : Body{get}
    
}


public extension AspectReducerWrapper where State : Emptyable {
    
    @inlinable
    func apply<Action : ActionProtocol>(_ action: Action,
                       to state: inout State,
                       environment: Dependencies) {
        casePath.mutate(&state){aspect in
            body.apply(action, to: &aspect, environment: environment)
        }
    }
    
}


public struct PrismReducer<State : Emptyable, Reducer : DependentReducer> : AspectReducerWrapper {
    
    public let casePath : CasePath<State, Reducer.State>
    public let body : Reducer
    
    @inlinable
    public init(_ casePath: CasePath<State, Reducer.State>,
                reducer: Reducer){
        self.casePath = casePath
        self.body = reducer
    }
    
    @inlinable
    public init(_ casePath: CasePath<State, Reducer.State>,
                build: @escaping () -> Reducer){
        self.casePath = casePath
        self.body = build()
    }
    
}

public protocol DependentClassCaseReducer : DependentReducer {
    
    associatedtype Aspect : AnyObject
    associatedtype Action : ActionProtocol
    
    var casePath : CasePath<State, Aspect>{get}
    func apply(_ action: Action,
               to aspect: Aspect,
               environment: Dependencies)
    
}


public extension DependentClassCaseReducer {
    
    func apply<Action : ActionProtocol>(_ action: Action,
                       to state: inout State,
                       environment: Dependencies) {
        guard let action = action as? Self.Action else{return}
        casePath.mutate(state){aspect in
            apply(action, to: aspect, environment: environment)
        }
    }
    
}

public protocol ClassCaseReducer : DependentReducer {
    
    associatedtype Aspect : AnyObject
    associatedtype Action : ActionProtocol
    
    var casePath : CasePath<State, Aspect>{get}
    func apply(_ action: Action,
               to aspect: Aspect)
    
}


public extension ClassCaseReducer {
    
    func apply<Action : ActionProtocol>(_ action: Action,
                       to state: inout State,
                       environment: Dependencies) {
        guard let action = action as? Self.Action else{return}
        casePath.mutate(state){aspect in
            apply(action, to: aspect)
        }
    }
    
}


public protocol ClassCaseReducerWrapper : DependentReducer {
    
    associatedtype Body : DependentClassReducer
    
    var casePath : CasePath<State, Body.State>{get}
    var body : Body{get}
    
}


public extension ClassCaseReducerWrapper {
    
    func apply<Action : ActionProtocol>(_ action: Action,
                       to state: inout State,
                       environment: Dependencies) {
        guard let action = action as? Body.Action else{return}
        casePath.mutate(state){aspect in
            body.apply(action, to: aspect, environment: environment)
        }
    }
    
}


public struct ClassPrismReducer<State, Reducer : DependentClassReducer> : ClassCaseReducerWrapper {
    
    public let casePath: CasePath<State, Reducer.State>
    public let body : Reducer
    
    @inlinable
    public init(_ casePath: CasePath<State, Reducer.State>,
                reducer: Reducer){
        self.casePath = casePath
        self.body = reducer
    }
    
    @inlinable
    public init(_ casePath: CasePath<State, Reducer.State>,
                build: @escaping () -> Reducer){
        self.casePath = casePath
        self.body = build()
    }
    
}
