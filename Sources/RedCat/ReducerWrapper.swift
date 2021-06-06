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
    
    @inlinable
    func applyErased<Action : ActionProtocol>(_ action: Action,
                                              to state: inout Body.State,
                                              environment: Dependencies) {
        body.applyErased(action,
                         to: &state,
                         environment: environment)
    }
    
    @inlinable
    func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
        body.acceptsAction(action)
    }
    
}


public struct Reducer<Body : ErasedReducer> : ReducerWrapper {
    
    public let body : Body
    
    @inlinable
    public init(_ body: () -> Body) {
        self.body = body()
    }
    
    @inlinable
    public init<State, Action : ActionProtocol>(_ closure: @escaping (Action, inout State, Dependencies) -> Void)
    where Body == ClosureReducer<State, Action> {
        self.body = ClosureReducer(closure)
    }
    
    @inlinable
    public init<State, Action : ActionProtocol>(_ closure: @escaping (Action, inout State) -> Void)
    where Body == ClosureReducer<State, Action> {
        self.body = ClosureReducer(closure)
    }
    
    @inlinable
    public init<State : Releasable, R : ErasedReducer>(_ aspect: CasePath<State, R.State>, _ body: () -> R)
    where Body == AspectReducer<State, R> {
        self.body = AspectReducer(aspect, reducer: body())
    }
    
    @inlinable
    public init<State, R : ErasedReducer>(_ detail: WritableKeyPath<State, R.State>, _ body: () -> R)
    where Body == DetailReducer<State, R> {
        self.body = DetailReducer(detail, reducer: body())
    }
    
}
