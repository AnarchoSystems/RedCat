//
//  DispatchReducer.swift
//  
//
//  Created by Markus Pfeifer on 12.05.21.
//

import Foundation



public protocol DispatchReducer : ErasedReducer {
    
    associatedtype Dispatched : ErasedReducer
    
    func dispatch<Action : ActionProtocol>(_ action: Action) -> Dispatched
    
}


public extension DispatchReducer {
    
    @inlinable
    func applyErased<Action : ActionProtocol>(_ action: Action, to state: inout Dispatched.State, environment: Dependencies) {
        dispatch(action).applyErased(action, to: &state, environment: environment)
    }
    
    @inlinable
    func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
        dispatch(action).acceptsAction(action)
    }
    
}

extension Optional : ErasedReducer, DispatchReducer where Wrapped : ErasedReducer {
    
    public typealias State = Dispatched.State
    
    @inlinable
    public func dispatch<Action : ActionProtocol>(_ action: Action) -> IfReducer<Wrapped, NopReducer<Wrapped.State>> {
        map(IfReducer.ifReducer) ?? .elseReducer()
    }
    
}
