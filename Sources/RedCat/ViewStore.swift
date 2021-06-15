//
//  ViewStore.swift
//  
//
//  Created by Markus Pfeifer on 10.05.21.
//


extension StoreProtocol {
    
    public func map<NewState, NewAction>(_ transform: @escaping (State) -> NewState,
                                         onAction: @escaping (NewAction) -> Action) -> MapStore<Self, NewState, NewAction> {
        MapStore(base: self, transform: transform, embed: onAction)
    }
    
    public func map<NewState>(_ transform: @escaping (State) -> NewState) -> MapStore<Self, NewState, Action> {
        map(transform, onAction: {$0})
    }
    
    public subscript<NewState>(dynamicMember keyPath: KeyPath<State, NewState>) -> MapStore<Self, NewState, Action> {
        map({ $0[keyPath: keyPath] }, onAction: {$0})
    }
}


public struct MapStore<Base: StoreProtocol, State, Action>: StoreWrapper {
    
    public let wrapped : Base
    @usableFromInline
    let transform : (Base.State) -> State
    @usableFromInline
    let embed : (Action) -> Base.Action
    
    @inlinable
    public var state : State {
        transform(wrapped.state)
    }
    
    @inlinable
    public func recovererFromWrapped() -> Recoverer<Base, MapStore<Base, State, Action>> {
        let trafo = self.transform
        let embed = self.embed
        return Recoverer {MapStore(base: $0, transform: trafo, embed: embed)}
    }
    
    @usableFromInline 
    init(base: Base,
         transform: @escaping (Base.State) -> State,
         embed: @escaping (Action) -> Base.Action) {
        self.wrapped = base
        self.transform = transform
        self.embed = embed
    }
    
    @inlinable
    public func send(_ action: Action) {
        wrapped.send(embed(action))
    }
    
    @inlinable
    public func send(_ list: ActionGroup<Action>) {
        wrapped.send(list, embed: embed)
    }
    
}


#if (os(iOS) && arch(arm64)) || os(macOS) || os(tvOS) || os(watchOS)
#if canImport(SwiftUI)

import SwiftUI

public extension StoreProtocol {
    
    func withViewStore<A, T, U>(_ transform: @escaping (State) -> T,
                                onAction: @escaping (A) -> Action,
                                @ViewBuilder completion: (MapStore<Self, T, A>) -> U) -> U {
        completion(map(transform, onAction: onAction))
    }
    
}

#endif
#endif
