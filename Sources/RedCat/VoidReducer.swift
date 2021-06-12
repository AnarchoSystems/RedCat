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
    
    public func apply(_ action: (), to state: inout State) {
        apply(&state)
    }
    
}


public extension VoidReducer {
    
    init(_ closure: @escaping (inout State) -> Void) {
        apply = closure
    }
    
    init<R : ReducerProtocol>(_ reducer: R, action: R.Action) where State == R.State {
        apply = {reducer.apply(action, to: &$0)}
    }
    
}


public extension ReducerProtocol {
    
    func send(_ action: Action) -> VoidReducer<State> {
        VoidReducer(self, action: action)
    }
    
}
