//
//  Store.swift
//  
//
//  Created by Markus Pfeifer on 06.05.21.
//

import Foundation

/// A ```Store``` contains the "global" AppState and exposes the main methods to mutate the state.
@dynamicMemberLookup
public class Store<State>: StoreProtocol {

    /// The "global" state of the application.
	public var state : State {
        fatalError()
    }
    
    // prevent external initialization
    // makes external subclasses uninitializable
    internal init() {}
    
    /// Applies an action to the state using the App's main reducer.
    /// - Parameters:
    ///     - action: The action to dispatch.
    ///
    /// This method is not threadsafe and has to be called on the mainthread.
		public func send<Action : ActionProtocol>(_ action: Action) {
        fatalError()
    }
    
		public func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
        fatalError()
    }
}

public extension Store {
    
    /// Creates an ```ObservableStore```.
    /// - Parameters:
    ///     - initialState: The initial state of the store.
    ///     - reducer: The method that is used to modify the state.
    ///     - environment: The constants that the reducer and the services need.
    ///     - services: Instances of service classes that can react to state changes and dispatch further actions.
    /// - Returns: A fully configured ```ObservableStore```.
    static func create<Reducer : ErasedReducer>(initialState: Reducer.State,
                                                reducer: Reducer,
                                                environment: Dependencies = [],
                                                services: [Service<Reducer.State>] = []) -> ObservableStore<State>
    where Reducer.State == State {
        let result = ConcreteStore(initialState: initialState,
                                   reducer: reducer,
                                   environment: environment,
                                   services: services)
        return result
    }
    
    /// Creates an ```ObservableStore```.
    /// - Parameters:
    ///     - reducer: The method that is used to modify the state.
    ///     - environment: The constants that the reducer and the services need. Will also be passd to ```configure```.
    ///     - services: Instances of service classes that can react to state changes and dispatch further actions.
    ///     - configure: Creates the initial state of the app from the app's constants.
    ///     - constants: The same as ```environment```.
    /// - Returns: A fully configured ```ObservableStore```.
    static func create<Reducer : ErasedReducer>(reducer: Reducer,
                                                environment: Dependencies = [],
                                                services: [Service<Reducer.State>] = [],
                                                configure: (_ constants: Dependencies) -> State) -> ObservableStore<State>
    where Reducer.State == State {
        let result = ConcreteStore(initialState: configure(environment),
                                   reducer: reducer,
                                   environment: environment,
                                   services: services)
        return result
    }
	
	/// Creates an ```ConnectableStore```.
	/// - Parameters:
	///     - initialState: The initial state of the store.
	///     - environment: The constants that the reducer and the services need.
	///     - services: Instances of service classes that can react to state changes and dispatch further actions.
	/// - Returns: A fully configured ```ConnectableStore```.
	static func connectable(initialState: State,
													environment: Dependencies = [],
													services: [Service<State>] = []) -> ConnectableStore<State> {
		let concrete = ConcreteStore(initialState: initialState,
															 reducer: ConnectableReducer(),
															 environment: environment,
															 services: services)
		return ConnectableStore(base: concrete)
	}
	
	/// Creates an ```ConnectableStore```.
	/// - Parameters:
	///     - reducer: The method that is used to modify the state.
	///     - environment: The constants that the reducer and the services need. Will also be passd to ```configure```.
	///     - services: Instances of service classes that can react to state changes and dispatch further actions.
	///     - configure: Creates the initial state of the app from the app's constants.
	///     - constants: The same as ```environment```.
	/// - Returns: A fully configured ```ConnectableStore```.
	static func connectable<Reducer : ErasedReducer>(initialState: State,
																									 reducer: Reducer,
																									 environment: Dependencies = [],
																									 services: [Service<Reducer.State>] = []) -> ConnectableStore<State>
	where Reducer.State == State {
		let connectableReducer = ConnectableReducer<State>()
		connectableReducer.connect(reducer)
		let concrete = ConcreteStore(initialState: initialState,
															 reducer: connectableReducer,
															 environment: environment,
															 services: services)
		return ConnectableStore(base: concrete)
	}
}
