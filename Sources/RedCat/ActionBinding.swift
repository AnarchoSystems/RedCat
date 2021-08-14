//
//  ActionBinding.swift
//  
//
//  Created by Markus Pfeifer on 14.06.21.
//



public struct ActionBinding<R : ReducerProtocol, NewAction> : ReducerProtocol {
    
    @usableFromInline
    let reducer : R
    @usableFromInline
    let embed : (NewAction) -> R.Action
    
    @inlinable
    public func apply(_ action: NewAction,
                      to state: inout R.State) -> R.Response {
        reducer.apply(embed(action), to: &state)
    }
    
}


public extension ReducerProtocol {
    
    func bindAction<NewAction>(to newAction: @escaping (NewAction) -> Action) -> ActionBinding<Self, NewAction> {
        ActionBinding(reducer: self, embed: newAction)
    }
    
}
