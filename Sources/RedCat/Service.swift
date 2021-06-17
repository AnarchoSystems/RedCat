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

@usableFromInline
internal class AnyStore<State, Action> {
    var state : State {fatalError()}
    func send(_ action: Action) {fatalError()}
    func send(_ list: ActionGroup<Action>) {fatalError()}
}

@usableFromInline
internal final class ConcreteStore<Store : StoreProtocol & AnyObject> : AnyStore<Store.State, Store.Action> {
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

/// A ```Service``` is an erasure type for ```DetailService```s.
/// Do not attempt to subclass ```Service``` directly. Instead, subclass ```DetailService```.
open class Service<State, Action> {
    
    /// A stub of the app's ```Store``` that only allows you to inspect the state and dispatch actions.
    /// - Important: Do not assume that this property is present at the end of the ```Service```'s initializer. It will, however, be present in each open method of the ```Service```.
    public final var store : StoreStub<State, Action> {
        StoreStub(base: _store)
    }
    
    @usableFromInline
    final var _store : AnyStore<State, Action>!
    
    @usableFromInline
    internal init() {}
    
    @usableFromInline
    internal func _onAppInit() {}
    
    @usableFromInline
    internal func _afterUpdate() {}
    
    @usableFromInline
    internal func _onShutdown() {}
    
}

public func injectStore<Store : StoreProtocol & AnyObject>(_ store: Store, to service: Service<Store.State, Store.Action>) {
    service._store = ConcreteStore(base: store)
}


/// A ```DetailService``` wraps itself around the ```Reducer``` to enable side-effects.
///
/// A ```DetailService``` watches the ```Store``` for changes of some ```Detail``` of interest. Whenever the detail changes, the ```DetailService``` receives a ```onUpdate``` message and has a chance to inspect the new value of the ```Detail```. Additionally, each ```DetailService``` stores the old value publicly.
/// The ```onUpdate``` method won't run when the ```Store``` has just been set up. If it is important for you to react to the completion of the ```Store```'s initializer even if no actions have been dispatched yet, you can implement ```onAppInit```.
/// In case your service needs to react to the termination of the app, e.g. to store some data, you can implement ```onShutdown```.
/// Just being informed about those events wouldn't be terribly useful. Therefore, ```DetailService```s give you access to a simplified version of the ```Store``` so you can dispatch actions as needed. Also, you can use the ```Injected``` property wrapper to read the app's ```Dependencies```.
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
    
    /// Implement this method to react to the event that the ```Store``` has been fully initialized and is ready to dispatch actions.
    @usableFromInline
    internal final override func _onAppInit() {
        _oldValue = detail(store.state)
        onAppInit()
    }
    
    /// Implement this method to react to the event that the ```Store``` has been fully initialized and is ready to dispatch actions.
    open func onAppInit() {}
    
    @usableFromInline
    internal final override func _afterUpdate() {
        let detail = self.detail(store.state)
        guard detail != oldValue else {return}
        onUpdate(newValue: detail)
        _oldValue = detail
    }
    
    /// Implement this method to be notified whenever the watched property actually changes according to the implementation of ```==```.
    /// - Parameters:
    ///     - newValue: The new value of the watched property.
    open func onUpdate(newValue: Detail) {}
    
    @usableFromInline
    internal final override func _onShutdown() {
        onShutdown()
    }
    
    /// Implement this method to be notified about the event that the ```Store``` will soon no longer accept any new actions. Use this method to dispatch some final cleanup actions synchronously.
    open func onShutdown() {}
    
}


public enum Services {}
