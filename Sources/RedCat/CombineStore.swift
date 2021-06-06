//
//  CombineStore.swift
//  
//
//  Created by Markus Pfeifer on 15.05.21.
//

import Foundation

public typealias StoreObjectWillChangePublisher = Observers

public extension StoreObjectWillChangePublisher {
    
    func subscribe(_ observer: @escaping () -> Void) -> StoreUnsubscriber {
        addObserver(ClosureStoreDelegate(observer))
    }
    
}

#if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
#if canImport(Combine)

import Combine

public typealias CombineStore<State> = ObservableStore<State>


@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
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

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension ObservableStore: ObservableObject {
	public typealias ObjectWillChangePublisher = StoreObjectWillChangePublisher
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension __ObservableStoreProtocol {
	
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

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public struct StatePublisher<Store: __ObservableStoreProtocol>: Publisher {
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
        
		@usableFromInline
        internal let store: Store
		public var state: Store.State { store.state }
		
		public subscript<T>(dynamicMember keyPath: KeyPath<Store.State, T>) -> T {
			store.state[keyPath: keyPath]
		}
        
	}
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
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
