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

extension AsyncStore: ObservableStoreProtocol where Base: ObservableStoreProtocol {

	public func addObserver<S>(_ observer: S) -> StoreUnsubscriber where S : StoreDelegate, Base.State == S.State {
		base.addObserver(observer)
	}
}

#if os(iOS) || os(macOS)
#if canImport(Combine)

import Combine

@available(OSX 10.15, *)
@available(iOS 13.0, *)
extension AsyncStore: ObservableObject where Base: ObservableObject {
	public typealias ObjectWillChangePublisher = Base.ObjectWillChangePublisher
	public var objectWillChange: Base.ObjectWillChangePublisher { base.objectWillChange }
}
#endif
#endif
	
extension StoreProtocol {
	
	public func async(on queue: DispatchQueue) -> AsyncStore<Self> {
		AsyncStore(self, queue: queue)
	}
}
