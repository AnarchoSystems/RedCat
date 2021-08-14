//
//  AnyReducer.swift
//  
//
//  Created by Данил Войдилов on 29.05.2021.
//

import Foundation


///```AnyReducer``` is the proper type erasure for all reducers.
public struct AnyReducer<State, Action, Response>: ReducerProtocol {
	
    @usableFromInline
	internal let applyBlock: (Action, inout State) -> Response
	
    
    /// Initializes the erased reducer from an arbitrary other reducer.
    /// - Parameters:
    ///     - reducer: The reducer to type-erase.
    @inlinable
    public init<R: ReducerProtocol>(_ reducer: R) where R.State == State, R.Action == Action, R.Response == Response {
		applyBlock = {
			reducer.apply($0, to: &$1)
		}
	}
    
    @inlinable
	public func apply(_ action: Action, to state: inout State) -> Response {
		applyBlock(action, &state)
	}
    
}


public extension ReducerProtocol {
    
    @inlinable
    func erased() -> AnyReducer<State, Action, Response> {
        AnyReducer(self)
    }
    
}


public extension Reducers.Native {
    
    @inlinable
    static func anyReducer<Wrapped : ReducerProtocol>(_ wrapped: Wrapped) -> AnyReducer<Wrapped.State, Wrapped.Action, Wrapped.Response> {
        AnyReducer(wrapped)
    }
    
}
