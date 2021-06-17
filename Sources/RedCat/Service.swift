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

fileprivate class AnyStore<State, Action> {
    var state : State {fatalError()}
    func send(_ action: Action) {fatalError()}
    func send(_ list: ActionGroup<Action>) {fatalError()}
}

fileprivate final class ConcreteStore<Store : StoreProtocol & AnyObject> : AnyStore<Store.State, Store.Action> {
    let initialState : Store.State
    weak var base : Store?
    init(base: Store) {self.base = base; self.initialState = base.state}
    override var state : Store.State {base?.state ?? initialState}
    override func send(_ action: Store.Action) {
        base?.send(action)
    }
    override func send(_ list: ActionGroup<Store.Action>) {
        base?.send(list)
    }
}

/// A ```Service``` wraps itself around the ```Reducer``` to enable side-effects.
///
/// Before each application of the App's main ```Reducer```, each ```Service``` will receive a ```beforeUpdate``` message and has the opportunity to react to the action and interact with the ```Store``` and its state before the action is dispatched.
/// After each application, the ```Service```s receive ```afterUpdate``` *in reversed order*.
/// Additionally, ```Service```s get the oportunity to react to the event that the store finished its initialization process and the event that the store is shutting down.
/// ```Service```s cannot modify the actions already being enqueued, nor can they prevent execution. This should be done by high level reducers.
open class Service<State, Action> {
    
    /// A stub of the app's ```Store``` that only allows you to inspect the state and dispatch actions.
    /// - Important: Do not assume that this property is present at the end of the ```Service```'s initializer. It will, however, be present in each open method of the ```Service```.
    public final var store : StoreStub<State, Action> {
        StoreStub(base: _store)
    }
    
    fileprivate final var _store : AnyStore<State, Action>!
    
    public init() {}
    
    /// Implement this method to react to the event that the ```Store``` has been fully initialized and is ready to dispatch actions.
    open func onAppInit() {}
    
    /// Implement this method to be notified about actions that are about to be processed.
    /// - Parameters:
    ///     - action: The action to be processed.
    open func beforeUpdate(action: Action) {}
    
    /// Implement this method to be notified about actions that have been processed.
    /// - Parameters:
    ///     - action: The action that has been processed.
    open func afterUpdate(action: Action) {}
    
    /// Implement this method to be notified about the event that the ```Store``` will soon no longer accept any new actions. Use this method to dispatch some final cleanup actions synchronously.
    open func onShutdown() {}
    
}

public func injectStore<Store : StoreProtocol & AnyObject>(_ store: Store, to service: Service<Store.State, Store.Action>) {
    service._store = ConcreteStore(base: store)
}

/// A ```DetailService``` watches some part of the state for changes and if it detects one, it calls the open method ```onUpdate```.
open class DetailService<State, Detail : Equatable, Action> : Service<State, Action> {
    
    
    public final let detail : (State) -> Detail
    
    /// The last value the watched property had.
    /// - Important: Do not assume that this property is present at the end of the ```Service```'s initializer. It will, however, be present in each open method of the ```Service```.
    @inlinable
    public final var oldValue : Detail {
        _oldValue!
    }
    
    @usableFromInline
    var _oldValue : Detail?
    
    @inlinable
    public init(detail: @escaping (State) -> Detail) {self.detail = detail}
    
    public final override func onAppInit() {
        _oldValue = detail(store.state)
        otherAppInitTasks()
    }
    
    /// Implement this method to react to the event that the ```Store``` has been fully initialized and is ready to dispatch actions.
    open func otherAppInitTasks() {}
    
    public final override func beforeUpdate(action: Action) {}
    
    public final override func afterUpdate(action: Action) {
        let detail = self.detail(store.state)
        guard detail != oldValue else {return}
        onUpdate(newValue: detail)
        _oldValue = detail
    }
    
    /// Implement this method to be notified whenever the watched property actually changes according to the implementation of ```==```.
    /// - Parameters:
    ///     - newValue: The new value of the watched property.
    open func onUpdate(newValue: Detail) {
        
    }
    
}


public enum Services {}
