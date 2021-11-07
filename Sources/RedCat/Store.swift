//
//  Store.swift
//  
//
//  Created by Markus Pfeifer on 06.05.21.
//

import Foundation

public typealias ObservableStore<State, Action> = Store<AnyReducer<State, Action>>


private extension Store {
    
    func maybeWarnShutdown() {
        #if DEBUG
        if environment.internalFlags.warnActionsAfterShutdown {
            print("RedCat: The store has been invalidated, actions are no longer accepted.\n If sending actions to a dead store is somehow acceptable for your app, you can silence this warning  by setting internalFlags.warnActionsAfterShutdown to false in the environment or by compiling in release mode.")
        }
        #endif
    }
    
}

#if compiler(>=5.5) && canImport(_Concurrency)


/// A ```Store``` contains the "global" AppState and exposes the main methods to mutate the state.
@dynamicMemberLookup
public final class Store<Reducer : ReducerProtocol>: StoreProtocol {
    
    public final var state : Reducer.State {
        _state
    }
    
    @usableFromInline
    final var _state : Reducer.State
    
    @usableFromInline
    internal final var hasInitialized = false
    @usableFromInline
    internal final var hasShutdown = false
    
    public final let objectWillChange = StoreObjectWillChangePublisher()
    
    @usableFromInline
    final let services : [Service<Reducer.State, Reducer.Action>]
    @usableFromInline
    final var environment : Dependencies
    
    
    @usableFromInline
    let reducer : Reducer
    
    @usableFromInline
    var enqueuedActions = [Action]()
    
    @inlinable
    @MainActor
    public init(reducer: Reducer,
                environment: Dependencies = [],
                services: [Service<State, Action>] = [],
                configure: (Dependencies) -> State) {
        self._state = configure(environment)
        self.reducer = reducer
        self.environment = environment
        self.services = services
        for service in services {
            injectStore(self, to: service)
            inject(environment: environment, to: service)
        }
        for service in services {
            service._onAppInit()
        }
        hasInitialized = true
        if !enqueuedActions.isEmpty {
            dispatchActions(expectedActions: enqueuedActions.count)
        }
    }
    
    @inlinable
    @MainActor
    public convenience init(initialState: State,
                            reducer: Reducer,
                            environment: Dependencies = [],
                            services: [Service<State, Action>] = []) {
        self.init(reducer: reducer,
                  environment: environment,
                  services: services,
                  configure: {_ in initialState})
    }
    
    @inlinable
    @MainActor
    public func send(_ list: ActionGroup<Reducer.Action>) {
        enqueuedActions.append(contentsOf: list.values)
        dispatchActions(expectedActions: list.values.count)
    }
    
    @inlinable
    @MainActor
    public func send(_ action: Reducer.Action) {
        enqueuedActions.append(action)
        dispatchActions(expectedActions: 1)
    }
    
    @usableFromInline
    @MainActor
    internal func dispatchActions(expectedActions: Int) {
        
        guard hasInitialized else {
            return
        }
        
        guard enqueuedActions.count == expectedActions else {
            // All calls to this method are assumed to happen on
            // main dispatch queue - a serial queue.
            // Therefore, if more than one action is in the queue,
            // the action must have been enqueued by the below while loop
            return
        }
        
        guard !hasShutdown else {
            return maybeWarnShutdown()
        }
        
        objectWillChange.notifyAll(warnInefficientObservers: environment.internalFlags.warnInefficientObservers)
        
        var idx = 0
        
        while idx < enqueuedActions.count {
            
            let action = enqueuedActions[idx]
            
            reducer.apply(action, to: &_state)
            
            // services have an outermost to innermost semantics, hence second loop is reversed order
            
            for service in services {
                service._onUpdate()
            }
            
            idx += 1
            
        }
        
        enqueuedActions = []
        
    }
    
    @MainActor
    public final func shutDown() {
        guard !hasShutdown else {
            return maybeWarnShutdown()
        }
        for service in services {
            service.onShutdown()
        }
        hasShutdown = true
    }
    
}

public extension Store {
    
    @inlinable
    @MainActor
    convenience init<R : ReducerProtocol>(erasing: R,
                                          environment: Dependencies = [],
                                          services: [Service<R.State, R.Action>] = [],
                                          configure: (Dependencies) -> R.State)
    where Reducer == AnyReducer<R.State, R.Action> {
        self.init(reducer: erasing.erased(),
                  environment: environment,
                  services: services,
                  configure: configure)
    }
    
    @inlinable
    @MainActor
    convenience init<R : ReducerProtocol>(initialState: R.State,
                                          erasing: R,
                                          environment: Dependencies = [],
                                          services: [Service<R.State, R.Action>] = [])
    where Reducer == AnyReducer<R.State, R.Action> {
        self.init(erasing: erasing,
                  environment: environment,
                  services: services,
                  configure: {_ in initialState})
    }
    
}

#else

/// A ```Store``` contains the "global" AppState and exposes the main methods to mutate the state.
@dynamicMemberLookup
public final class Store<Reducer : ReducerProtocol>: StoreProtocol {
    
    public final var state : Reducer.State {
        _state
    }
    
    @usableFromInline
    final var _state : Reducer.State
    
    @usableFromInline
    internal final var hasInitialized = false
    @usableFromInline
    internal final var hasShutdown = false
    
    public final let objectWillChange = StoreObjectWillChangePublisher()
    
    @usableFromInline
    final let services : [Service<Reducer.State, Reducer.Action>]
    @usableFromInline
    final var environment : Dependencies
    
    
    @usableFromInline
    let reducer : Reducer
    
    @usableFromInline
    var enqueuedActions = [Action]()
    
    @inlinable
    public init(reducer: Reducer,
                environment: Dependencies = [],
                services: [Service<State, Action>] = [],
                configure: (Dependencies) -> State) {
        self._state = configure(environment)
        self.reducer = reducer
        self.environment = environment
        self.services = services
        for service in services {
            injectStore(self, to: service)
            inject(environment: environment, to: service)
        }
        for service in services {
            service._onAppInit()
        }
        hasInitialized = true
        if !enqueuedActions.isEmpty {
            dispatchActions(expectedActions: enqueuedActions.count)
        }
    }
    
    @inlinable
    public convenience init(initialState: State,
                            reducer: Reducer,
                            environment: Dependencies = [],
                            services: [Service<State, Action>] = []) {
        self.init(reducer: reducer,
                  environment: environment,
                  services: services,
                  configure: {_ in initialState})
    }
    
    @inlinable
    public func send(_ list: ActionGroup<Reducer.Action>) {
        enqueuedActions.append(contentsOf: list.values)
        dispatchActions(expectedActions: list.values.count)
    }
    
    @inlinable
    public func send(_ action: Reducer.Action) {
        enqueuedActions.append(action)
        dispatchActions(expectedActions: 1)
    }
    
    @usableFromInline
    internal func dispatchActions(expectedActions: Int) {
        
        guard hasInitialized else {
            return
        }
        
        guard enqueuedActions.count == expectedActions else {
            // All calls to this method are assumed to happen on
            // main dispatch queue - a serial queue.
            // Therefore, if more than one action is in the queue,
            // the action must have been enqueued by the below while loop
            return
        }
        
        guard !hasShutdown else {
            return maybeWarnShutdown()
        }
        
        objectWillChange.notifyAll(warnInefficientObservers: environment.internalFlags.warnInefficientObservers)
        
        var idx = 0
        
        while idx < enqueuedActions.count {
            
            let action = enqueuedActions[idx]
            
            reducer.apply(action, to: &_state)
            
            // services have an outermost to innermost semantics, hence second loop is reversed order
            
            for service in services {
                service._onUpdate()
            }
            
            idx += 1
            
        }
        
        enqueuedActions = []
        
    }
    
    
    public final func shutDown() {
        guard !hasShutdown else {
            return maybeWarnShutdown()
        }
        for service in services {
            service.onShutdown()
        }
        hasShutdown = true
    }
    
}


public extension Store {
    
    @inlinable
    convenience init<R : ReducerProtocol>(erasing: R,
                                          environment: Dependencies = [],
                                          services: [Service<R.State, R.Action>] = [],
                                          configure: (Dependencies) -> R.State)
    where Reducer == AnyReducer<R.State, R.Action> {
        self.init(reducer: erasing.erased(),
                  environment: environment,
                  services: services,
                  configure: configure)
    }
    
    @inlinable
    convenience init<R : ReducerProtocol>(initialState: R.State,
                                          erasing: R,
                                          environment: Dependencies = [],
                                          services: [Service<R.State, R.Action>] = [])
    where Reducer == AnyReducer<R.State, R.Action> {
        self.init(erasing: erasing,
                  environment: environment,
                  services: services,
                  configure: {_ in initialState})
    }
    
}

#endif
