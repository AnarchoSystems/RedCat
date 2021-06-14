//
//  StoreDelegate.swift
//  
//
//  Created by Данил Войдилов on 29.05.2021.
//

import Foundation


/// Implement this protocol (in absence of ```Combine```) to monitor the store for dispatch cycles that are about to happen.
public protocol StoreDelegate {
    /// Indicates if this ```StoreDelegate``` is still interested in updates. If this property is ```false```, the ```StoreDelegate``` will be removed automatically from the subscriber list at the next dispatch cycle.
	var isAlive: Bool { get }
	/// The store will call this method whenever a dispatch cycle is about to happen.
	/// - Important: The method will be called *once* per dispatch cycle, *not* per change of state.
	/// - Note: The receiver needs to be registered as an observer to receive updates.
	func storeWillChange()
}

extension StoreDelegate {
	public var isAlive: Bool { true }
}

public struct ClosureStoreDelegate: StoreDelegate {
    
	private let didChange: () -> Void
	
	public init(_ didChange: @escaping () -> Void = {}) {
		self.didChange = didChange
	}
	
	public func storeWillChange() {
		didChange()
	}
}

public struct WeakStoreDelegate: StoreDelegate {
    private weak var delegate : (StoreDelegate & AnyObject)?
	public var isAlive: Bool { delegate != nil }
	
	public init(_ delegate: StoreDelegate & AnyObject) {
        self.delegate = delegate
	}
	
	public func storeWillChange() {
        delegate?.storeWillChange()
	}
}
