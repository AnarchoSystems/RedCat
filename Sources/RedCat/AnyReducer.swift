//
//  AnyReducer.swift
//  
//
//  Created by Данил Войдилов on 29.05.2021.
//

import Foundation

public struct AnyReducer<State>: ErasedReducer {
	
    @usableFromInline
	internal let applyBlock: (ActionProtocol, inout State) -> Void
    @usableFromInline
	internal let acceptsActionBlock: (ActionProtocol) -> Bool
	
	public init<R: ErasedReducer>(_ reducer: R) where R.State == State {
		applyBlock = {
			reducer.applyDynamic($0, to: &$1)
		}
		acceptsActionBlock = reducer.acceptsActionDynamic
	}
    
    @inlinable
	public func applyErased<Action>(_ action: Action, to state: inout State) where Action : ActionProtocol {
		applyBlock(action, &state)
	}
    
    @inlinable
	public func acceptsAction<Action>(_ action: Action) -> Bool where Action : ActionProtocol {
		acceptsActionBlock(action)
	}
}


public extension Reducers.Native {
    
    func anyReducer<Wrapped : ErasedReducer>(_ wrapped: Wrapped) -> AnyReducer<Wrapped.State> {
        AnyReducer(wrapped)
    }
    
}
