//
//  AnyReducer.swift
//  
//
//  Created by Данил Войдилов on 29.05.2021.
//

import Foundation

public struct AnyReducer<State>: ErasedReducer {
	
    @usableFromInline
	internal let applyBlock: (ActionProtocol, inout State, Dependencies) -> Void
    @usableFromInline
	internal let acceptsActionBlock: (ActionProtocol) -> Bool
	
	public init<R: ErasedReducer>(_ reducer: R) where R.State == State {
		applyBlock = {
			reducer.applyDynamic($0, to: &$1, environment: $2)
		}
		acceptsActionBlock = reducer.acceptsActionDynamic
	}
    
    @inlinable
	public func apply<Action>(_ action: Action, to state: inout State, environment: Dependencies) where Action : ActionProtocol {
		applyBlock(action, &state, environment)
	}
    
    @inlinable
	public func acceptsAction<Action>(_ action: Action) -> Bool where Action : ActionProtocol {
		acceptsActionBlock(action)
	}
}
