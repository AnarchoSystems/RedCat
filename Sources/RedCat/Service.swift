//
//  Service.swift
//  RedCat
//
//  Created by Markus Pfeifer on 13.05.21.
//

import Foundation

// MARK: STORE STUB

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

// MARK: SERVICE

public protocol ServiceProtocol : AnyObject {
    
    /// This method is called when the ```Store``` has been fully initialized and is ready to dispatch actions. Do *not* attempt to implement it in ```DetailStore``` or ```AppEventStore```. Instead, trust the default implementation (which calls ```onAppInit``` without underscore).
    func _onAppInit()
    /// This method is called when the ```Store``` dispatched an action. Do *not* attempt to implement it in ```DetailStore``` or ```AppEventStore```. ```AppEventStore``` exists specifically to only watch app events, while the default implementation for ```DetailStore``` calls ```onUpdate``` without underscore.
    func _onUpdate()
    /// Implement this method to be notified about the event that the ```Store``` will soon no longer accept any new actions. Use this method to dispatch some final cleanup actions synchronously.
    func onShutdown()
    
}

open class _Service<State, Action> {
    
    /// A stub of the app's ```Store``` that only allows you to inspect the state and dispatch actions.
    /// - Important: Do not assume that this property is present at the end of the ```Service```'s initializer. It will, however, be present in each open method of the ```Service```.
    public final var store : StoreStub<State, Action> {
        StoreStub(base: _store)
    }
    
    @usableFromInline
    final var _store : AnyStore<State, Action>!
    
    @inlinable
    public init() {}
    
}

/// A ```Service``` is an erasure type for ```DetailService```s and ```AppEventService```s.
/// Do not attempt to subclass ```Service``` directly. Instead, subclass ```DetailService``` or ```AppEventService```.
public typealias Service<State, Action> = _Service<State, Action> & ServiceProtocol

public func injectStore<Store : StoreProtocol & AnyObject>(_ store: Store, to service: _Service<Store.State, Store.Action>) {
    service._store = ConcreteStore(base: store)
}

// MARK: APP EVENT SERVICE

public protocol AppEventServiceProtocol : ServiceProtocol {
    
    /// Implement this method to react to the event that the ```Store``` has been fully initialized and is ready to dispatch actions.
    func onAppInit()
    
}

open class _AppEventService<State, Action> : _Service<State, Action> {
    
    /// This method is called when the ```Store``` dispatched an action. Do *not* attempt to implement it in ```DetailStore``` or ```AppEventStore```. ```AppEventStore``` exists specifically to only watch app events, while the default implementation for ```DetailStore``` calls ```onUpdate``` without underscore.
    public final func _onUpdate() {}
    
}

public extension AppEventServiceProtocol {
    
    /// This method is called when the ```Store``` has been fully initialized and is ready to dispatch actions. Do *not* attempt to implement it in ```DetailStore``` or ```AppEventStore```. Instead, trust the default implementation (which calls ```onAppInit``` without underscore).
    @inlinable
    func _onAppInit() {
        onAppInit()
    }
    
}

/// An ```AppEventService``` is a specialized ```Service``` class that only reacts to app events.
public typealias AppEventService<State, Action> = _AppEventService<State, Action> & AppEventServiceProtocol


// MARK: DETAIL SERVICE

public protocol DetailServiceProtocol : ServiceProtocol {
    
    associatedtype AppState
    associatedtype Action
    associatedtype Detail : Equatable
    
    /// Implement this method to react to the event that the ```Store``` has been fully initialized and is ready to dispatch actions.
    func onAppInit()
    
    /// Implement this method to extract the part of the app that you want to watch.
    /// - Parameters:
    ///     - state: The current state of the app.
    func extractDetail(from state: AppState) -> Detail
    
    /// Implement this method to be notified whenever the watched property actually changes according to the implementation of ```==```.
    /// - Parameters:
    ///     - newValue: The new value of the watched property.
    func onUpdate(newValue: Detail)
    
    /// A stub of the app's ```Store``` that only allows you to inspect the state and dispatch actions.
    /// - Important: Do not assume that this property is present at the end of the ```Service```'s initializer. It will, however, be present in each open method of the ```Service```.
    var store : StoreStub<AppState, Action> {get}
    
    /// The last value the watched property had.
    /// - Important: Do not assume that this property is present at the end of the ```Service```'s initializer. It will, however, be present in each open method of the ```Service```.
    var oldValue : Detail {get}
    
    /// This method is used to set the old value. It is public only for technical reasons. Do *not* attempt to call this method, otherwise you will get inconsistent results.
    func _setOldValue(_ detail: Detail)
    
}

open class _DetailService<State, Detail : Equatable, Action> : _Service<State, Action> {
    
    /// The last value the watched property had.
    /// - Important: Do not assume that this property is present at the end of the ```Service```'s initializer. It will, however, be present in each open method of the ```Service```.
    @inlinable
    public final var oldValue : Detail {
        _oldValue!
    }
    
    @usableFromInline
    final var _oldValue : Detail?
    
    /// This method is used to set the old value. It is public only for technical reasons. Do *not* attempt to call this method, otherwise you will get inconsistent results.
    @inlinable
    public final func _setOldValue(_ detail: Detail) {
        _oldValue = detail
    }
    
}

public extension DetailServiceProtocol {
    
    typealias Ask = _Lens<Dependencies, Dependencies>
    
    /// Implement this method to react to the event that the ```Store``` has been fully initialized and is ready to dispatch actions.
    @inlinable
    func _onAppInit() {
        _setOldValue(extractDetail(from: store.state))
        onAppInit()
    }
    
    @inlinable
    func onAppInit() {}
    
    @inlinable
    func _onUpdate() {
        let detail = self.extractDetail(from: store.state)
        guard detail != oldValue else {return}
        onUpdate(newValue: detail)
        _setOldValue(detail)
    }
    
    @inlinable
    func onShutdown() {}
    
}


/// A ```DetailService``` wraps itself around the ```Reducer``` to enable side-effects.
///
/// A ```DetailService``` watches the ```Store``` for changes of some ```Detail``` of interest. Whenever the detail changes, the ```DetailService``` receives a ```onUpdate``` message and has a chance to inspect the new value of the ```Detail```. Additionally, each ```DetailService``` stores the old value publicly.
/// The ```onUpdate``` method won't run when the ```Store``` has just been set up. If it is important for you to react to the completion of the ```Store```'s initializer even if no actions have been dispatched yet, you can implement ```onAppInit```.
/// In case your service needs to react to the termination of the app, e.g. to store some data, you can implement ```onShutdown```.
/// Just being informed about those events wouldn't be terribly useful. Therefore, ```DetailService```s give you access to a simplified version of the ```Store``` so you can dispatch actions as needed. Also, you can use the ```Injected``` property wrapper to read the app's ```Dependencies```.
public typealias DetailService<AppState, Detail : Equatable, Action> = _DetailService<AppState, Detail, Action> & DetailServiceProtocol


public enum Services {}
