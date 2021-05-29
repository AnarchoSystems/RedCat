//
//  ObservableStore.swift
//  
//
//  Created by Markus Pfeifer on 15.05.21.
//

import Foundation


/// An ```ObservableStore``` exposes an ```addObserver``` method so other parts can be notified of dispatch cycles (in absence of ```Combine```).
open class ObservableStore<State> : Store<State> {
    
    @usableFromInline
    final let observers = Observers<State>()
		public let objectWillChange = StoreObjectWillChangePublisher()
    
    /// Tells the receiver that the observer wants to be notified about dispatch cycles.
    /// - Parameters:
    ///     - observer: The object to be notified.
		@discardableResult
    @inlinable
		public final func addObserver<S: StoreDelegate>(_ observer: S) -> StoreUnsubscriber where S.State == State {
        observers.addObserver(observer)
    }
	
	/// Tells the receiver that the observer wants to be notified about dispatch cycles.
	@discardableResult
	@inlinable
	public final func addObserver(didChange: @escaping (State, State, ActionProtocol) -> Void, willChange: @escaping (State, State, ActionProtocol) -> Void = {_, _, _ in}) -> StoreUnsubscriber {
		observers.addObserver(AnyStoreDelegate(didChange: didChange, willChange: willChange))
	}
	
	/// Tells the receiver that the observer wants to be notified about dispatch cycles.
	@discardableResult
	@inlinable
	public final func addObserver(didChange: @escaping (State) -> Void, willChange: @escaping (State) -> Void = {_ in}) -> StoreUnsubscriber {
		observers.addObserver(AnyStoreDelegate(didChange: { _, new, _ in didChange(new) }, willChange: { _, new, _ in didChange(new) }))
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
		internal var hasInitialized = false
		@usableFromInline
		internal var hasShutdown = false
	
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
			
				let oldState = _state
				let newState = dispatchActions()
        
				observers.notifyAllWillChange(old: oldState, new: newState, action: action)
				objectWillChange.send()
				_state = newState
				observers.notifyAllDidChange(old: oldState, new: newState, action: action)
    }
    
    @usableFromInline
		func dispatchActions() -> Reducer.State {
        var newState = _state
        var idx = 0
        
        while idx < enqueuedActions.count {
            
            let action = enqueuedActions[idx]
            
            // services have an outermost to innermost semantics, hence second loop is reversed order
            for service in services.reversed() {
                action.beforeUpdate(service: service, store: self, environment: environment)
            }
            reducer.applyDynamic(action, to: &newState, environment: environment)
            for service in services {
                action.afterUpdate(service: service, store: self, environment: environment)
            }
            
            idx += 1
            
        }
        
        enqueuedActions = []
        return newState
    }
    
    @usableFromInline
    override func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
        reducer.acceptsAction(action)
    }
	
		/// Dispatches ```AppDeinit``` and invalidates the receiver.
		///
		/// Use this method when your App is about to terminate to trigger cleanup actions.
		public final func shutDown() {
				send(Actions.AppDeinit())
				hasShutdown = true
		}
}

extension ActionProtocol {
	@usableFromInline
	func send<State>(to store: Store<State>) {
		store.send(self)
	}
}
