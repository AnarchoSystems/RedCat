//
//  File.swift
//  
//
//  Created by Данил Войдилов on 30.05.2021.
//

import Foundation

public final class ComposedStore<First: StoreProtocol, Second: StoreProtocol, State>: Store<State> {
	
	public let first: First
	public let second: Second
	public let getState: (First.State, Second.State) -> State
	
	public override var state: State {
		getState(first.state, second.state)
	}
	
	public init(_ first: First, _ second: Second, state: @escaping (First.State, Second.State) -> State) {
		self.first = first
		self.second = second
		self.getState = state
	}
	
	override public func send<Action>(_ action: Action) where Action : ActionProtocol {
		first.send(action)
		second.send(action)
	}
	
	override public func acceptsAction<Action>(_ action: Action) -> Bool where Action : ActionProtocol {
		first.acceptsAction(action) && second.acceptsAction(action)
	}
}

extension ComposedStore: ObservableStoreProtocol where First: ObservableStoreProtocol, Second: ObservableStoreProtocol {
	
	public func addObserver<S>(_ observer: S) -> StoreUnsubscriber where S : StoreDelegate, State == S.State {
		let firstUnsubscriber = first.addObserver(observer.map {[unowned self] in getState($0, second.state) })
		let secondUnsubscriber = second.addObserver(observer.map {[unowned self] in getState(first.state, $0) })
		return StoreUnsubscriber {
			firstUnsubscriber.unsubscribe()
			secondUnsubscriber.unsubscribe()
		}
	}
}

#if os(iOS) || os(macOS)
#if canImport(Combine)

import Combine

@available(OSX 10.15, *)
@available(iOS 13.0, *)
extension ComposedStore: ObservableObject where First: ObservableObject, Second: ObservableObject {
	
	public var objectWillChange: AnyPublisher<Void, Never> {
		first.objectWillChange.map {_ in () }
			.merge(with: second.objectWillChange.map {_ in () })
			.eraseToAnyPublisher()
	}
}
#endif
#endif

extension ComposedStore where State == TupleState<First.State, Second.State> {
	
	public convenience init(_ first: First, _ second: Second) {
		self.init(first, second, state: TupleState.init)
	}
}

@dynamicMemberLookup
public struct TupleState<First, Second> {
	public var _0: First
	public var _1: Second
	
	public init(_ first: First, _ second: Second) {
		_0 = first
		_1 = second
	}
	
	public subscript<T>(dynamicMember keyPath: KeyPath<First, T>) -> T {
		_0[keyPath: keyPath]
	}
	
	public subscript<T>(dynamicMember keyPath: KeyPath<Second, T>) -> T {
		_1[keyPath: keyPath]
	}
	
	public subscript<T>(dynamicMember keyPath: WritableKeyPath<First, T>) -> T {
		get { _0[keyPath: keyPath] }
		set { _0[keyPath: keyPath] = newValue }
	}
	
	public subscript<T>(dynamicMember keyPath: WritableKeyPath<Second, T>) -> T {
		get { _1[keyPath: keyPath] }
		set { _1[keyPath: keyPath] = newValue }
	}
	
	public subscript<T>(dynamicMember keyPath: ReferenceWritableKeyPath<First, T>) -> T {
		get { _0[keyPath: keyPath] }
		nonmutating set { _0[keyPath: keyPath] = newValue }
	}
	
	public subscript<T>(dynamicMember keyPath: ReferenceWritableKeyPath<Second, T>) -> T {
		get { _1[keyPath: keyPath] }
		nonmutating set { _1[keyPath: keyPath] = newValue }
	}
}
