//
//  VoidReducer.swift
//  
//
//  Created by Markus Pfeifer on 12.06.21.
//

import Foundation



public protocol VoidReducerProtocol : ReducerProtocol where Action == Void {
    associatedtype State
}

public extension VoidReducerProtocol {
    
    func bindAction<NewAction>(to newAction: NewAction.Type = NewAction.self) -> ActionBinding<Self, NewAction> {
        bindAction{_ in }
    }
    
}

extension Optional : VoidReducerProtocol where Action == Void {}
extension AnyReducer : VoidReducerProtocol where Action == Void {}
extension DetailReducer : VoidReducerProtocol where Action == Void {}
extension AspectReducer : VoidReducerProtocol where Action == Void {}
extension Reducer : VoidReducerProtocol where Action == Void {}

public struct VoidReducer<State, Response> : VoidReducerProtocol {
    
    let apply : (inout State) -> Response
    
    public init(_ closure: @escaping (inout State) -> Response) {
        apply = closure
    }
    
    public func apply(_ action: (), to state: inout State) -> Response {
        apply(&state)
    }
    
}


public extension VoidReducer {
    
    init<R : ReducerProtocol>(_ reducer: R, action: R.Action) where State == R.State, R.Response == Response {
        apply = {reducer.apply(action, to: &$0)}
    }
    
}


public extension ReducerProtocol {
    
    func send(_ action: Action) -> VoidReducer<State, Response> {
        VoidReducer(self, action: action)
    }
    
}


public extension ReducerProtocol where Action == Void {
    
    func send() -> VoidReducer<State, Response> {
        VoidReducer(self, action: ())
    }
    
    func asVoidReducer() -> VoidReducer<State, Response> {
        send()
    }
    
}
