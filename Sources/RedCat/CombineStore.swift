//
//  CombineStore.swift
//  
//
//  Created by Markus Pfeifer on 15.05.21.
//

import Foundation


#if os(iOS) || os(macOS)
#if canImport(Combine)

import Combine

/// A ```CombineStore``` is an ```ObservableObject``` in ```Combine```'s sense. For every dispatch cycle, ```objectWillChange``` will be notified.
@available(OSX 10.15, *)
@available(iOS 13.0, *)
public class CombineStore<State> : Store<State>, ObservableObject {
		public typealias Output = State
		public typealias Failure = Never
}

@available(OSX 10.15, *)
@available(iOS 13.0, *)
final class ConcreteCombineStore<Body : ErasedReducer> : CombineStore<Body.State>, StoreDelegate {
    
    @usableFromInline
    override var state : Body.State {
        concreteStore.state
    }
    
    @usableFromInline
    let concreteStore : ConcreteStore<Body>
    
    init(initialState: Body.State,
         reducer: Body,
         environment: Dependencies,
         services: [Service<Body.State>]) {
        concreteStore = ConcreteStore(initialState: initialState,
                                      reducer: reducer,
                                      environment: environment,
                                      services: services)
        super.init()
        concreteStore.addObserver(WeakStoreDelegate(self))
    }
    
    
    @usableFromInline
    override func send(_ action: ActionProtocol) {
        concreteStore.send(action)
    }
    
    @usableFromInline
    override func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
        concreteStore.acceptsAction(action)
    }
	
    @usableFromInline
		func storeWillChange(oldState: Body.State, newState: Body.State, action: ActionProtocol) {
        objectWillChange.send()
    }
	
		@usableFromInline
		func storeDidChange(oldState: Body.State, newState: Body.State, action: ActionProtocol) {}
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
				self.send($0)
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
}

#endif
#endif
