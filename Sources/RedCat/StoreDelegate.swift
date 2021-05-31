//
//  File.swift
//  
//
//  Created by Данил Войдилов on 29.05.2021.
//

import Foundation


/// Implement this protocol (in absence of ```Combine```) to monitor the store for dispatch cycles that are about to happen.
public protocol StoreDelegate {
	var isAlive: Bool { get }
	/// The store will call this method whenever a dispatch cycle is about to happen.
	/// - Important: The method will be called *once* per dispatch cycle, *not* per change of state.
	/// - Note: The receiver needs to be registered as an observer to receive updates.
	func storeDidChange()
}

extension StoreDelegate {
	public var isAlive: Bool { true }
}

public struct AnyStoreDelegate: StoreDelegate {
	private let didChange: () -> Void
	
	public init(_ didChange: @escaping () -> Void = {}) {
		self.didChange = didChange
	}
	
	public init<S: StoreDelegate>(_ delegate: S) {
		didChange = delegate.storeDidChange
	}
	
	public func storeDidChange() {
		didChange()
	}
}

public struct WeakStoreDelegate: StoreDelegate {
	private let didChange: () -> Void
	private var checkWeak: () -> Bool
	public var isAlive: Bool { checkWeak() }
	
	public init<S: StoreDelegate & AnyObject>(_ delegate: S) {
		checkWeak = {[weak delegate] in delegate != nil }
		didChange = {[weak delegate] in delegate?.storeDidChange() }
	}
	
	public func storeDidChange() {
		didChange()
	}
}
