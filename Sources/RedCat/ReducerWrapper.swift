//
//  ReducerWrapper.swift
//  
//
//  Created by Markus Pfeifer on 06.05.21.
//

import CasePaths



public protocol ReducerWrapper : ErasedReducer {

    associatedtype Body : ErasedReducer
    var body : Body {get}

}


public extension ReducerWrapper {
    
    func apply<Action : ActionProtocol>(_ action: Action,
                                        to state: inout Body.State,
                                        environment: Dependencies) {
        body.apply(action,
                   to: &state,
                   environment: environment)
    }
    
    func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
        body.acceptsAction(action)
    }
    
}


public struct Reducer<Reducer : ErasedReducer> : ReducerWrapper {
    
    public let body : Reducer
    
    public init(_ body: () -> Reducer) {
        self.body = body()
    }
    
    public init<State, Action : ActionProtocol>(_ closure: @escaping (Action, inout State, Dependencies) -> Void)
    where Reducer == ClosureReducer<State, Action> {
        self.body = ClosureReducer(closure)
    }
    
    public init<State, Action : ActionProtocol>(_ closure: @escaping (Action, inout State) -> Void)
    where Reducer == ClosureReducer<State, Action> {
        self.body = ClosureReducer(closure)
    }
    
    public init<State : Emptyable, R : ErasedReducer>(_ aspect: CasePath<State, R.State>, _ body: () -> R)
    where Reducer == PrismReducer<State, R> {
        self.body = PrismReducer(aspect, reducer: body())
    }
    
    public init<State, R : ErasedReducer>(_ detail: WritableKeyPath<State, R.State>, _ body: () -> R)
    where Reducer == LensReducer<State, R> {
        self.body = LensReducer(detail, reducer: body())
    }

}
