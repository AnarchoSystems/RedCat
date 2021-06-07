//
//  ConcreteStore.swift
//  
//
//  Created by Markus Pfeifer on 06.06.21.
//

import Foundation

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

@usableFromInline
final class ConcreteStore<Reducer : ErasedReducer> : ObservableStore<Reducer.State> {
    
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
    let services : [Service<Reducer.State>]
    @usableFromInline
    var environment : Dependencies
    
    @usableFromInline
    var enqueuedActions = [ActionProtocol]()
    
    @inlinable
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
    
    
    @inlinable
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
        
        let expectedCount : Int
        
        if var action = action as? ActionGroup {
            action.unroll()
            enqueuedActions.append(contentsOf: action.values)
            expectedCount = action.values.count
        }
        else if var action = action as? UndoGroup {
            action.unroll()
            enqueuedActions.append(contentsOf: action.values)
            expectedCount = action.values.count
        }
        else {
            enqueuedActions.append(action)
            expectedCount = 1
        }
        
        guard enqueuedActions.count == expectedCount else {
            // All calls to this method are assumed to happen on
            // main dispatch queue - a serial queue.
            // Therefore, if more than one action is in the queue,
            // the action must have been enqueued by the below while loop
            return
        }
        
        objectWillChange.notifyAll()
        dispatchActions()
    }
    
    @inlinable
    func dispatchActions() {
        var idx = 0
        
        while idx < enqueuedActions.count {
            
            let action = enqueuedActions[idx]
            
            for service in services {
                action.beforeUpdate(service: service, store: self, environment: environment)
            }
            
            reducer.applyDynamic(action, to: &_state, environment: environment)
            
            // services have an outermost to innermost semantics, hence second loop is reversed order
            
            for service in services.reversed() {
                action.afterUpdate(service: service, store: self, environment: environment)
            }
            
            idx += 1
            
        }
        
        enqueuedActions = []
    }
    
    @inlinable
    override func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
        reducer.acceptsAction(action)
    }
    
    public override final func shutDown() {
        send(Actions.AppDeinit())
        hasShutdown = true
    }
}

