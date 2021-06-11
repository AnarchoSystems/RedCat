//
//  ConcreteStore.swift
//  
//
//  Created by Markus Pfeifer on 06.06.21.
//

import Foundation

@usableFromInline
final class ConcreteStore<Reducer : ReducerProtocol> : ObservableStore<Reducer.State, Reducer.Action> {
    
    @inlinable
    override var state : Reducer.State {
        _state
    }
    
    @usableFromInline
    var _state : Reducer.State
    @usableFromInline
    let reducer : Reducer
    
    
    @usableFromInline
    internal var hasInitialized = false
    @usableFromInline
    internal var hasShutdown = false
    
    @usableFromInline
    let services : [Service<Reducer.State, Action>]
    @usableFromInline
    var environment : Dependencies
    
    @usableFromInline
    var enqueuedActions = [Action]()
    
    @inlinable
    init(initialState: Reducer.State,
         reducer: Reducer,
         environment: Dependencies,
         services: [Service<Reducer.State, Action>]) {
        self._state = initialState
        self.reducer = reducer
        self.services = services
        self.environment = environment
        super.init()
        for service in services {
            service.onAppInit(store: self, environment: environment)
        }
    }
    
    @usableFromInline
    override func send(_ list: ActionGroup<Reducer.Action>) {
        enqueuedActions.append(contentsOf: list.values)
        dispatchActions(expectedActions: list.values.count)
    }
    
    @usableFromInline 
    override func send(_ action: Action) {
        enqueuedActions.append(action)
        dispatchActions(expectedActions: 1)
    }
    
    @inlinable
    internal func dispatchActions(expectedActions: Int) {
        
        guard enqueuedActions.count == expectedActions else {
            // All calls to this method are assumed to happen on
            // main dispatch queue - a serial queue.
            // Therefore, if more than one action is in the queue,
            // the action must have been enqueued by the below while loop
            return
        }
        
        guard !hasShutdown else {
            if environment.internalFlags.warnActionsAfterShutdown {
                print("RedCat: The store has been invalidated, actions are no longer accepted.\n If sending actions to a dead store is somehow acceptable for your app, you can silence this warning  by setting internalFlags.warnActionsAfterShutdown to false in the environment.")
            }
            return
        }
        
        objectWillChange.notifyAll(warnInefficientObservers: environment.internalFlags.warnInefficientObservers)
        
        var idx = 0
        
        while idx < enqueuedActions.count {
            
            let action = enqueuedActions[idx]
            
            for service in services {
                service.beforeUpdate(store: self, action: action, environment: environment)
            }
            
            reducer.apply(action, to: &_state)
            
            // services have an outermost to innermost semantics, hence second loop is reversed order
            
            for service in services.reversed() {
                service.afterUpdate(store: self, action: action, environment: environment)
            }
            
            idx += 1
            
        }
        
        enqueuedActions = []
        
    }
    
    
    public override final func shutDown() {
        for service in services {
            service.onShutdown(store: self, environment: environment)
        }
        hasShutdown = true
    }
}

