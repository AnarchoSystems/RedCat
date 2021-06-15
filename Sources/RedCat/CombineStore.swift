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

public typealias CombineStore = ObservableStore

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
extension Store: ObservableObject {
	public typealias ObjectWillChangePublisher = StoreObjectWillChangePublisher
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension StoreProtocol {
	
	public var publisher: StatePublisher<Self> { StatePublisher(wrapped: self) }
	
	public var subscriber: AnySubscriber<Action, Never> {
		AnySubscriber(
			receiveSubscription: {
				$0.request(.unlimited)
			},
			receiveValue: {
                self.send($0)
				return .unlimited
			},
			receiveCompletion: nil
		)
	}
}


@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public struct StatePublisher<StoreStub: StoreProtocol>: Publisher {
	public typealias Failure = Never
	let wrapped: StoreStub
	
	public func receive<S: Subscriber>(subscriber: S) where Never == S.Failure, Output == S.Input {
		let unsubscriber = wrapped.addObserver { wrapped in
			_ = subscriber.receive(Output(store: wrapped))
		}
		subscriber.receive(subscription: StoreSubscription(unsubscriber))
		_ = subscriber.receive(Output(store: wrapped))
	}
	
	@dynamicMemberLookup
	public struct Output {
        
		@usableFromInline
        internal let store: StoreStub
		public var state: StoreStub.State { store.state }
		
		public subscript<T>(dynamicMember keyPath: KeyPath<StoreStub.State, T>) -> T {
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
