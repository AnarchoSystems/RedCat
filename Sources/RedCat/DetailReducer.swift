//
//  DetailReducer.swift
//  
//
//  Created by Markus Pfeifer on 05.05.21.
//

import Foundation


public protocol DependentDetailReducer : ErasedReducer {
    
    associatedtype Detail
    associatedtype Action : ActionProtocol
    
    var keyPath : WritableKeyPath<State, Detail> {get}
    func apply(_ action: Action,
               to detail: inout Detail,
               environment: Dependencies)
    
}


public extension DependentDetailReducer {
    
    func apply<Action : ActionProtocol>(_ action: Action,
                                        to state: inout State,
                                        environment: Dependencies) {
        guard let action = action as? Self.Action else {return}
        apply(action, to: &state[keyPath: keyPath], environment: environment)
    }
    
    func acceptsAction<Action : ActionProtocol>(ofType type: Action.Type) -> Bool {
        type is Self.Action
    }
    
}


public protocol DetailReducer : ErasedReducer {
    
    associatedtype Detail
    associatedtype Action : ActionProtocol
    
    var keyPath : WritableKeyPath<State, Detail> {get}
    func apply(_ action: Action,
               to detail: inout Detail)
    
}


public extension DetailReducer {
    
    func apply<Action : ActionProtocol>(_ action: Action,
                                        to state: inout State,
                                        environment: Dependencies) {
        guard let action = action as? Self.Action else {return}
        apply(action, to: &state[keyPath: keyPath])
    }
    
    func acceptsAction<Action : ActionProtocol>(ofType type: Action.Type) -> Bool {
        type is Self.Action
    }
    
}


public protocol DetailReducerWrapper : ErasedReducer {
    
    associatedtype Body : ErasedReducer
    
    var keyPath : WritableKeyPath<State, Body.State> {get}
    var body : Body {get}
    
}


public extension DetailReducerWrapper {
    
    func apply<Action : ActionProtocol>(_ action: Action,
                                        to state: inout State,
                                        environment: Dependencies) {
        body.apply(action, to: &state[keyPath: keyPath], environment: environment)
    }
    
    func acceptsAction<Action : ActionProtocol>(ofType type: Action.Type) -> Bool {
        body.acceptsAction(ofType: type)
    }
    
}


public struct LensReducer<State, Reducer : ErasedReducer> : DetailReducerWrapper {
    
    public let keyPath: WritableKeyPath<State, Reducer.State>
    public let body : Reducer
    
    public init(_ detail: WritableKeyPath<State, Reducer.State>, reducer: Reducer) {
        self.keyPath = detail
        self.body = reducer
    }
    
}
