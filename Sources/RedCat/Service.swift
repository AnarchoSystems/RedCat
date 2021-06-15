//
//  Service.swift
//  RedCat
//
//  Created by Markus Pfeifer on 13.05.21.
//

import Foundation


public struct StoreStub<State, Action> {
    
    fileprivate let base : AnyStore<State, Action>
    
    public var state : State {base.state}
    
    public func send(_ action: Action) {
        base.send(action)
    }
    
    public func send(_ list: ActionGroup<Action>) {
        base.send(list)
    }
    
}

public extension StoreProtocol {
    func stub() -> StoreStub<State, Action> {
        StoreStub(base: ConcreteStore(base: self))
    }
}

fileprivate class AnyStore<State, Action> {
    var state : State {fatalError()}
    func send(_ action: Action) {fatalError()}
    func send(_ list: ActionGroup<Action>) {fatalError()}
}

fileprivate final class ConcreteStore<Store : StoreProtocol> : AnyStore<Store.State, Store.Action> {
    let base : Store
    init(base: Store) {self.base = base}
    override var state : Store.State {base.state}
    override func send(_ action: Store.Action) {
        base.send(action)
    }
    override func send(_ list: ActionGroup<Store.Action>) {
        base.send(list)
    }
}

/// A ```Service``` wraps itself around the reducer to enable side-effects.
///
/// Before each application of the App's main reducer, each service will receive a ```beforeUpdate``` message and has the opportunity to react to the action and interact with the store and its state before the action is dispatched.
/// After each application, the services receive ```afterUpdate``` *in reversed order*.
/// Services cannot modify the actions already being enqueued, nor can they prevent execution. This should be done by high level reducers.
open class Service<State, Action> {
    
    public init() {}
    
    open func onAppInit(store: StoreStub<State, Action>, environment: Dependencies) {}
    
    open func beforeUpdate(store: StoreStub<State, Action>, action: Action, environment: Dependencies) {}
    
    open func afterUpdate(store: StoreStub<State, Action>, action: Action, environment: Dependencies) {}
    
    open func onShutdown(store: StoreStub<State, Action>, environment: Dependencies) {}
    
}


/// A ```DetailService``` watches some part of the state for changes and if it detects one, it calls the open method ```onUpdate```.
open class DetailService<State, Detail : Equatable, Action> : Service<State, Action> {
    
    
    public final let detail : (State) -> Detail
    
    @inlinable
    public final var oldValue : Detail {
        _oldValue!
    }
    
    @usableFromInline
    var _oldValue : Detail?
    
    @inlinable
    public init(detail: @escaping (State) -> Detail) {self.detail = detail}
    
    public final override func onAppInit(store: StoreStub<State, Action>, environment: Dependencies) {
        _oldValue = detail(store.state)
        otherAppInitTasks(store: store, environment: environment)
    }
    
    open func otherAppInitTasks(store: StoreStub<State, Action>, environment: Dependencies) {}
    
    public final override func beforeUpdate(store: StoreStub<State, Action>,
                                            action: Action,
                                            environment: Dependencies) {
        
    }
    
    public final override func afterUpdate(store: StoreStub<State, Action>,
                                           action: Action,
                                           environment: Dependencies) {
        let detail = self.detail(store.state)
        guard detail != oldValue else {return}
        onUpdate(newValue: detail, store: store, environment: environment)
        _oldValue = detail
    }
    
    open func onUpdate(newValue: Detail, store: StoreStub<State, Action>, environment: Dependencies) {
        
    }
    
}


public enum Services {}
