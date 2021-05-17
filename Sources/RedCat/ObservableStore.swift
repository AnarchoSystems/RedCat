//
//  ObservableStore.swift
//  
//
//  Created by Markus Pfeifer on 15.05.21.
//

import Foundation


/// Implement this protocol (in absence of ```Combine```) to monitor the store for dispatch cycles that are about to happen.
public protocol StoreDelegate : AnyObject {
    
    /// The store will call this method whenever a dispatch cycle is about to happen.
    /// - Important: The method will be called *once* per dispatch cycle, *not* per change of state.
    /// - Note: The receiver needs to be registered as an observer to receive updates.
    func storeWillChange()
    
}

/// An ```ObservableStore``` exposes an ```addObserver``` method so other parts can be notified of dispatch cycles (in absence of ```Combine```).
public class ObservableStore<State> : Store<State> {
    
    @usableFromInline
    final let observers = Observers()
    
    /// Tells the receiver that the observer wants to be notified about dispatch cycles.
    /// - Parameters:
    ///     - observer: The object to be notified.
    @inlinable
    public final func addObserver(_ observer: StoreDelegate) {
        observers.addObserver(observer)
    }
    
}

enum AppInitCheck : Config {
    static func value(given: Dependencies) -> Bool {
        given.debug
    }
}

public extension Dependencies {
    
    /// If true, a warning will be printed, if the ```AppInit``` is somehow sent more than once.
    var __appInitCheck : Bool {
        get {self[AppInitCheck.self]}
        set {self[AppInitCheck.self] = newValue}
    }
}

final class ConcreteStore<Reducer : ErasedReducer> : ObservableStore<Reducer.State> {
    
    @usableFromInline
    override var state : Reducer.State {
        _state
    }
    
    @usableFromInline
    var _state : Reducer.State
    @usableFromInline
    let reducer : Reducer
    
    @usableFromInline
    let services : [Service<Reducer.State>]
    @usableFromInline
    var environment : Dependencies
    
    var enqueuedActions = [ActionProtocol]()
    
    init(initialState: Reducer.State,
         reducer: Reducer,
         environment: Dependencies,
         services: [Service<Reducer.State>]) {
        self._state = initialState
        self.reducer = reducer
        self.services = services
        self.environment = environment
        super.init()
        self.send(Actions.AppInit())
    }
    
    
    @usableFromInline
    override func send<Action : ActionProtocol>(_ action: Action) {
        
        if action is Actions.AppInit {
            if hasInitialized && environment.__appInitCheck {
                print("RedCat: AppInit has been sent more than once. Please file a bug report.\nIf your app works fine otherwise, you can silence this warning by setting __appInitCheck to false in the environment.")
            }
            hasInitialized = true
        }
        
        guard !hasShutdown else {
            fatalError("App has shutdown, actions are no longer accepted.")
        }
        
        enqueuedActions.append(action)
        
        guard enqueuedActions.count == 1 else {
            // All calls to this method are assumed to happen on
            // main dispatch queue - a serial queue.
            // Therefore, if more than one action is in the queue,
            // the action must have been enqueued by the below while loop
            return
        }
        
        observers.notifyAll()
        
        dispatchActions()
        
    }
    
    @usableFromInline
    func dispatchActions() {
        
        var idx = 0
        
        while idx < enqueuedActions.count {
            
            if var list = enqueuedActions[idx] as? ActionGroup {
                list.unroll()
                enqueuedActions.replaceSubrange(idx...idx, with: list.values)
            }
            if var list = enqueuedActions[idx] as? UndoGroup {
                list.unroll()
                enqueuedActions.replaceSubrange(idx...idx, with: list.values)
            }
            
            let action = enqueuedActions[idx]
            
            // services have an outermost to innermost semantics, hence second loop is reversed order
            for service in services.reversed() {
                action.beforeUpdate(service: service, store: self, environment: environment)
            }
            reducer.applyDynamic(action, to: &_state, environment: environment)
            for service in services {
                action.afterUpdate(service: service, store: self, environment: environment)
            }
            
            idx += 1
            
        }
        
        enqueuedActions = []
        
    }
    
    @usableFromInline
    override func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
        reducer.acceptsAction(action)
    }
    
}
