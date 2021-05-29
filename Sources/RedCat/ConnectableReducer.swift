//
//  File.swift
//  
//
//  Created by Данил Войдилов on 29.05.2021.
//

import Foundation

public final class ConnectableReducer<State>: ErasedReducer {
	
	private var reducers: [(UUID, AnyReducer<State>)] = []
	
	public func apply<Action>(_ action: Action, to state: inout State, environment: Dependencies) where Action : ActionProtocol {
		reducers.forEach {
			$0.1.apply(action, to: &state, environment: environment)
		}
	}
	
	public func acceptsAction<Action>(_ action: Action) -> Bool where Action : ActionProtocol {
		!reducers.contains(where: { !$0.1.acceptsAction(action) })
	}
	
	@discardableResult
	public func connect<R: ErasedReducer>(_ reducer: R) -> StoreUnsubscriber where R.State == State {
		let id = UUID()
		reducers.append((id, AnyReducer(reducer)))
		return StoreUnsubscriber {[self] in
			if let i = reducers.firstIndex(where: { $0.0 == id }) {
				reducers.remove(at: i)
			}
		}
	}
	
	@discardableResult
	public func connect<R: ErasedReducer>(_ reducer: R, at keyPath: WritableKeyPath<State, R.State>) -> StoreUnsubscriber {
		connect(reducer.bind(to: keyPath))
	}
}
