//
//  File.swift
//  
//
//  Created by Данил Войдилов on 30.05.2021.
//

import Foundation

public class ConnectableStore<State> : ObservableStore<State> {
	
	let base: ConcreteStore<ConnectableReducer<State>>
	
	public override var state : State {
		base.state
	}
	
	init(base: ConcreteStore<ConnectableReducer<State>>) {
		self.base = base
		super.init()
	}
	
	public override func send<Action: ActionProtocol>(_ action: Action) {
		base.send(action)
	}
	
	public override func acceptsAction<Action>(_ action: Action) -> Bool where Action : ActionProtocol {
		base.acceptsAction(action)
	}
	
	@discardableResult
	public func connect<R: ErasedReducer>(_ reducer: R) -> StoreUnsubscriber where R.State == State {
		base.reducer.connect(reducer)
	}
	
	@discardableResult
	public func connect<R: ErasedReducer>(_ reducer: R, at keyPath: WritableKeyPath<State, R.State>) -> StoreUnsubscriber {
		base.reducer.connect(reducer, at: keyPath)
	}
}
