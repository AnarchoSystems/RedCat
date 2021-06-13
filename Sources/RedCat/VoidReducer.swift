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



public struct VoidReducer<State> : VoidReducerProtocol {
    
    let apply : (inout State) -> Void
    
    public init(_ closure: @escaping (inout State) -> Void) {
        apply = closure
    }
    
    public func apply(_ action: (), to state: inout State) {
        apply(&state)
    }
    
}


public extension VoidReducer {
    
    init<R : ReducerProtocol>(_ reducer: R, action: R.Action) where State == R.State {
        apply = {reducer.apply(action, to: &$0)}
    }
    
}


public extension ReducerProtocol {
    
    func send(_ action: Action) -> VoidReducer<State> {
        VoidReducer(self, action: action)
    }
    
}


public extension ReducerProtocol where Action == Void {
    
    func send() -> VoidReducer<State> {
        VoidReducer(self, action: ())
    }
    
    func asVoidReducer() -> VoidReducer<State> {
        send()
    }
    
}
