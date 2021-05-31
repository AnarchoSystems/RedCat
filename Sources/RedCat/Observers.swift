//
//  Observers.swift
//  
//
//  Created by Markus Pfeifer on 15.05.21.
//

import Foundation


@usableFromInline
class Observers {
    
		private var firstObserver: AnyStoreDelegate?
    private var observers: [UUID: AnyStoreDelegate] = [:]
		var isEmpty: Bool { firstObserver == nil && observers.isEmpty }
	
    @usableFromInline
    func addObserver<S: StoreDelegate>(_ observer: S) -> StoreUnsubscriber {
				if firstObserver == nil {
						firstObserver = AnyStoreDelegate(observer)
						return StoreUnsubscriber { self.firstObserver = nil }
				}
        let id = UUID()
				observers[id] = AnyStoreDelegate(observer)
				return StoreUnsubscriber { self.observers[id] = nil }
    }
    
		@usableFromInline
		func notifyAll() {
				if firstObserver?.isAlive == false {
						firstObserver = nil
				}
				observers.filter({ !$0.value.isAlive }).forEach {
						observers[$0.key] = nil
				}
				firstObserver?.storeDidChange()
				for observer in observers.values {
					observer.storeDidChange()
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
