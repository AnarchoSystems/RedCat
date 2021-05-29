//
//  File.swift
//  
//
//  Created by Данил Войдилов on 30.05.2021.
//

import Foundation

public final class AsyncStore<Base: StoreProtocol>: Store<Base.State> {
	
	public let base: Base
	public let queue: DispatchQueue
	
	override public var state: Base.State {
		base.state
	}
	
	init(_ base: Base, queue: DispatchQueue) {
		self.base = base
		self.queue = queue
	}
	
	override public func send<Action>(_ action: Action) where Action : ActionProtocol {
		if Thread.isMainThread, queue == .main {
			base.send(action)
		} else {
			queue.async {
				self.base.send(action)
			}
		}
	}
	
	override public func acceptsAction<Action>(_ action: Action) -> Bool where Action : ActionProtocol {
		base.acceptsAction(action)
	}
}

extension StoreProtocol {
	
	public func async(on queue: DispatchQueue) -> AsyncStore<Self> {
		AsyncStore(self, queue: queue)
	}
}
