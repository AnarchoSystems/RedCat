//
//  CombineStore.swift
//  
//
//  Created by Markus Pfeifer on 15.05.21.
//

import Foundation

@available(*, deprecated, message: "Use 'ObservableStore' instead")
public typealias CombineStore<State> = ObservableStore<State>

public final class StoreObjectWillChangePublisher {
	private var observers: [UUID: () -> Void] = [:]
	private var firstObserver: (() -> Void)?
	
	public func send() {
		firstObserver?()
		observers.forEach { $0.value() }
	}
	
	func subscribe(_ subscriber: @escaping () -> Void) -> StoreUnsubscriber {
		if firstObserver == nil {
			firstObserver = subscriber
			return StoreUnsubscriber { self.firstObserver = nil }
		}
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
extension ObservableStoreProtocol {
	
	public var publisher: StatePublisher<Self> { StatePublisher(base: self) }
	
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
}

@available(OSX 10.15, *)
@available(iOS 13.0, *)
public struct StatePublisher<Store: ObservableStoreProtocol>: Publisher {
	public typealias Failure = Never
	let base: Store
	
	public func receive<S: Subscriber>(subscriber: S) where Never == S.Failure, Output == S.Input {
		let unsubscriber = base.addObserver { base in
			_ = subscriber.receive(Output(store: base))
		}
		subscriber.receive(subscription: StoreSubscription(unsubscriber))
		_ = subscriber.receive(Output(store: base))
	}
	
	@dynamicMemberLookup
	public struct Output {
		public let store: Store
		public var state: Store.State { store.state }
		
		public subscript<T>(dynamicMember keyPath: KeyPath<Store.State, T>) -> T {
			store.state[keyPath: keyPath]
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
