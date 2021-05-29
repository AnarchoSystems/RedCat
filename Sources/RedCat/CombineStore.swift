//
//  CombineStore.swift
//  
//
//  Created by Markus Pfeifer on 15.05.21.
//

import Foundation

public final class StoreObjectWillChangePublisher {
	private var observers: [UUID: () -> Void] = [:]
	
	public func send() {
		observers.forEach { $0.value() }
	}
	
	func subscribe(_ subscriber: @escaping () -> Void) -> StoreUnsubscriber {
		let id = UUID()
		observers[id] = subscriber
		return StoreUnsubscriber { self.observers[id] = nil }
	}
}

#if os(iOS) || os(macOS)
#if canImport(Combine)

import Combine

@available(OSX 10.15, *)
@available(iOS 13.0, *)
extension StoreObjectWillChangePublisher: Publisher {
	public typealias Output = Void
	public typealias Failure = Never
	
	public func receive<S: Subscriber>(subscriber: S) where Never == S.Failure, Void == S.Input {
		let unsubscriber = subscribe {
			_ = subscriber.receive()
		}
		subscriber.receive(subscription: StoreSubscription(unsubscriber))
	}
}

@available(OSX 10.15, *)
@available(iOS 13.0, *)
extension ObservableStore: ObservableObject {
	public typealias ObjectWillChangePublisher = StoreObjectWillChangePublisher
}

@available(OSX 10.15, *)
@available(iOS 13.0, *)
extension ObservableStore {
	
	public var publisher: StorePublisher { StorePublisher(base: self) }
	public var actionsPublisher: StoreActionsPublisher { StoreActionsPublisher(base: self) }
	
	public var subscriber: AnySubscriber<ActionProtocol, Never> {
		AnySubscriber(
			receiveSubscription: {
				$0.request(.unlimited)
			},
			receiveValue: {
				$0.send(to: self)
				return .unlimited
			},
			receiveCompletion: nil
		)
	}
	
	public struct StorePublisher: Publisher {
		public typealias Failure = Never
		public typealias Output = State
		let base: ObservableStore
		
		public func receive<S: Subscriber>(subscriber: S) where Never == S.Failure, Output == S.Input {
			let unsubscriber = base.addObserver(didChange: {
				_ = subscriber.receive($0)
			})
			subscriber.receive(subscription: StoreSubscription(unsubscriber))
			_ = subscriber.receive(base.state)
		}
	}
	
	public struct StoreActionsPublisher: Publisher {
		public typealias Failure = Never
		public typealias Output = ActionProtocol
		let base: ObservableStore<State>
		
		public func receive<S: Subscriber>(subscriber: S) where Never == S.Failure, Output == S.Input {
			let unsubscriber = base.addObserver(didChange: {_, _, action in
				_ = subscriber.receive(action)
			})
			subscriber.receive(subscription: StoreSubscription(unsubscriber))
		}
	}
}

@available(OSX 10.15, *)
@available(iOS 13.0, *)
private final class StoreSubscription: Subscription {
	let unsubscriber: StoreUnsubscriber
	
	init(_ unsubscriber: StoreUnsubscriber) {
		self.unsubscriber = unsubscriber
	}
	
	func request(_ demand: Subscribers.Demand) {}
	
	func cancel() {
		unsubscriber.unsubscribe()
	}
}

#endif
#endif
