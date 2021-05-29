//
//  File.swift
//  
//
//  Created by Данил Войдилов on 29.05.2021.
//

import Foundation


/// Implement this protocol (in absence of ```Combine```) to monitor the store for dispatch cycles that are about to happen.
public protocol StoreDelegate {
	associatedtype State
	/// The store will call this method whenever a dispatch cycle is about to happen.
	/// - Important: The method will be called *once* per dispatch cycle, *not* per change of state.
	/// - Note: The receiver needs to be registered as an observer to receive updates.
	func storeWillChange(oldState: State, newState: State, action: ActionProtocol)
	
	/// The store will call this method whenever a dispatch cycle is about to happen.
	/// - Important: The method will be called *once* per dispatch cycle, *not* per change of state.
	/// - Note: The receiver needs to be registered as an observer to receive updates.
	func storeDidChange(oldState: State, newState: State, action: ActionProtocol)
}

public struct AnyStoreDelegate<State>: StoreDelegate {
	private let willChange: (State, State, ActionProtocol) -> Void
	private let didChange: (State, State, ActionProtocol) -> Void
	
	public init() {
		willChange = { _, _, _ in }
		didChange = { _, _, _ in  }
	}
	
	public init(didChange: @escaping (State, State, ActionProtocol) -> Void, willChange: @escaping (State, State, ActionProtocol) -> Void) {
		self.willChange = willChange
		self.didChange = didChange
	}
	
	public init<S: StoreDelegate>(_ delegate: S) where S.State == State {
		willChange = delegate.storeWillChange
		didChange = delegate.storeDidChange
	}
	
	public func storeWillChange(oldState: State, newState: State, action: ActionProtocol) {
		willChange(oldState, newState, action)
	}
	
	public func storeDidChange(oldState: State, newState: State, action: ActionProtocol) {
		didChange(oldState, newState, action)
	}
}

public struct WeakStoreDelegate<State>: StoreDelegate {
	private let willChange: (State, State, ActionProtocol) -> Void
	private let didChange: (State, State, ActionProtocol) -> Void
	
	public init<S: StoreDelegate & AnyObject>(_ delegate: S) where S.State == State {
		willChange = {[weak delegate] in delegate?.storeWillChange(oldState: $0, newState: $1, action: $2) }
		didChange = {[weak delegate] in delegate?.storeDidChange(oldState: $0, newState: $1, action: $2) }
	}
	
	public func storeWillChange(oldState: State, newState: State, action: ActionProtocol) {
		willChange(oldState, newState, action)
	}
	
	public func storeDidChange(oldState: State, newState: State, action: ActionProtocol) {
		didChange(oldState, newState, action)
	}
}

public struct MapStoreDelegate<Base: StoreDelegate, State>: StoreDelegate {
	public let mapper: (State) -> Base.State
	public let base: Base
	
	public func storeWillChange(oldState: State, newState: State, action: ActionProtocol) {
		base.storeWillChange(oldState: mapper(oldState), newState: mapper(newState), action: action)
	}
	
	public func storeDidChange(oldState: State, newState: State, action: ActionProtocol) {
		base.storeDidChange(oldState: mapper(oldState), newState: mapper(newState), action: action)
	}
}

extension StoreDelegate {
	public func map<T>(_ block: @escaping (T) -> State) -> MapStoreDelegate<Self, T> {
		MapStoreDelegate(mapper: block, base: self)
	}
}

public struct FilterStoreDelegate<Base: StoreDelegate>: StoreDelegate {
	public let base: Base
	public let condition: (Base.State, Base.State, ActionProtocol) -> Bool
	
	public func storeWillChange(oldState: Base.State, newState: Base.State, action: ActionProtocol) {
		guard condition(oldState, newState, action) else { return }
		base.storeWillChange(oldState: oldState, newState: newState, action: action)
	}
	
	public func storeDidChange(oldState: Base.State, newState: Base.State, action: ActionProtocol) {
		guard condition(oldState, newState, action) else { return }
		base.storeDidChange(oldState: oldState, newState: newState, action: action)
	}
}

extension StoreDelegate {
	public func filter(_ block: @escaping (State) -> Bool) -> FilterStoreDelegate<Self> {
		FilterStoreDelegate(base: self) { _, new, _ in
			block(new)
		}
	}
	
	public func skipEqual(_ block: @escaping (State, State) -> Bool) -> FilterStoreDelegate<Self> {
		FilterStoreDelegate(base: self) { old, new, _ in !block(old, new) }
	}
}

extension StoreDelegate where State: Equatable {
	
	public func skipEqual() -> FilterStoreDelegate<Self> {
		skipEqual(==)
	}
}
