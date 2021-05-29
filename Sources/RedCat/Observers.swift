//
//  Observers.swift
//  
//
//  Created by Markus Pfeifer on 15.05.21.
//

import Foundation


@usableFromInline
class Observers<State> {
    
    private var observers: [UUID: AnyStoreDelegate<State>] = [:]
    
    @usableFromInline
    func addObserver<S: StoreDelegate>(_ observer: S) -> StoreUnsubscriber where S.State == State {
        let id = UUID()
				observers[id] = AnyStoreDelegate(observer)
				return StoreUnsubscriber { self.observers[id] = nil }
    }
    
		@usableFromInline
	func notifyAllWillChange(old: State, new: State, action: ActionProtocol) {
        for observer in observers.values {
					observer.storeWillChange(oldState: old, newState: new, action: action)
        }
    }
    
		@usableFromInline
		func notifyAllDidChange(old: State, new: State, action: ActionProtocol) {
				for observer in observers.values {
					observer.storeDidChange(oldState: old, newState: new, action: action)
				}
		}
}

public struct StoreUnsubscriber {
	private let unsubscribeAction: () -> Void
	
	public init(_ unsubscribe: @escaping () -> Void) {
		unsubscribeAction = unsubscribe
	}
	
	public func unsubscribe() {
		unsubscribeAction()
	}
}
