//
//  ViewStore.swift
//  
//
//  Created by Markus Pfeifer on 10.05.21.
//


extension __StoreProtocol {
    
    public func map<NewState, NewAction>(onAction: @escaping (NewAction) -> Action,
        _ transform: @escaping (State) -> NewState) -> MapStore<Self, NewState, NewAction> {
        MapStore(base: self, transform: transform, embed: onAction)
    }
    
    public func map<NewState>(_ transform: @escaping (State) -> NewState) -> MapStore<Self, NewState, Action> {
        map(onAction: {$0}, transform)
    }
    
    public subscript<NewState>(dynamicMember keyPath: KeyPath<State, NewState>) -> MapStore<Self, NewState, Action> {
        MapStore(base: self, transform: { $0[keyPath: keyPath] }, embed: {$0})
    }
}


public final class MapStore<Base: __StoreProtocol, State, Action>: Store<State, Action> {
    
    @usableFromInline
    let base : Base
    @usableFromInline
    let transform : (Base.State) -> State
    @usableFromInline
    let embed : (Action) -> Base.Action
    
    @inlinable
    public override var state : State {
        transform(base.state)
    }
    
    init(base: Base,
         transform: @escaping (Base.State) -> State,
         embed: @escaping (Action) -> Base.Action) {
        self.base = base
        self.transform = transform
        self.embed = embed
        super.init()
    }
    
    @inlinable
    public override func send(_ action: Action) {
        base.send(embed(action))
    }
    
}

extension MapStore: __ObservableStoreProtocol where Base: __ObservableStoreProtocol {
    
    public func addObserver<S>(_ observer: S) -> StoreUnsubscriber where S : StoreDelegate {
        base.addObserver(observer)
    }

    public func addObserver<S>(_ observer: S) where S : AnyObject, S : StoreDelegate {
        base.addObserver(observer)
    }
    
}

#if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
#if canImport(Combine)

import Combine

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension MapStore: ObservableObject where Base: ObservableObject {
    public typealias ObjectWillChangePublisher = Base.ObjectWillChangePublisher
    public var objectWillChange: Base.ObjectWillChangePublisher { base.objectWillChange }
}
#endif
#endif


#if (os(iOS) && arch(arm64)) || os(macOS) || os(tvOS) || os(watchOS)
#if canImport(SwiftUI)

import SwiftUI

public extension Store {
    
    func withViewStore<A, T, U>(onAction: @escaping (A) -> Action,
                             _ transform: @escaping (State) -> T,
                             @ViewBuilder completion: (MapStore<Store<State, Action>, T, A>) -> U) -> U {
        completion(map(onAction: onAction, transform))
    }
    
}

#endif
#endif
