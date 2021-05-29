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
public class CombineStore<State> : Store<State>, ObservableObject, Publisher, Subscriber {
		public typealias Output = State
		public typealias Failure = Never
	
		public var actions: AnyPublisher<ActionProtocol, Never> { actionsSubject.eraseToAnyPublisher() }
		let actionsSubject = PassthroughSubject<ActionProtocol, Never>()
	
		public func receive<S: Subscriber>(subscriber: S) where Never == S.Failure, State == S.Input {}
	
		public func receive(_ input: ActionProtocol) -> Subscribers.Demand {
				send(ActionGroup(values: [input]))
				return .unlimited
		}
	
		public func receive(subscription: Subscription) {
				subscription.request(.unlimited)
		}
	
		public func receive(completion: Subscribers.Completion<Never>) {}
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
		private let subject = PassthroughSubject<Body.State, Never>()
    
    init(initialState: Body.State,
         reducer: Body,
         environment: Dependencies,
         services: [Service<Body.State>]) {
        concreteStore = ConcreteStore(initialState: initialState,
                                      reducer: reducer,
                                      environment: environment,
                                      services: services)
        super.init()
        concreteStore.addObserver(self)
    }
    
    
    @usableFromInline
    override func send<Action : ActionProtocol>(_ action: Action) {
        concreteStore.send(action)
				actionsSubject.send(action)
    }
    
    @usableFromInline
    override func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
        concreteStore.acceptsAction(action)
    }
    
		override func receive<S>(subscriber: S) where Body.State == S.Input, S : Subscriber, S.Failure == Never {
				if subscriber.receive(state) > 0 {
						subject.receive(subscriber: subscriber)
				}
		}
	
    @usableFromInline
    func storeWillChange() {
        objectWillChange.send()
    }
	
		func storeDidChange() {
				subject.send(state)
		}
}

#endif
#endif
