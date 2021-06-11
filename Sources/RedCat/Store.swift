//
//  Store.swift
//  
//
//  Created by Markus Pfeifer on 06.05.21.
//

import Foundation

/// A ```Store``` contains the "global" AppState and exposes the main methods to mutate the state.
@dynamicMemberLookup
public class Store<State, Action>: __StoreProtocol {
    
    public var state : State {
        fatalError()
    }
    
    // prevent external initialization
    // makes external subclasses uninitializable
    @inlinable
    internal init() {}
    
    public func send(_ action: Action) {
        fatalError()
    }
    
    public func shutDown(){
        fatalError()
    }
    
    public func send(_ list: ActionGroup<Action>) {
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
    @inlinable
    static func create<Reducer : ReducerProtocol>(initialState: Reducer.State,
                                                  reducer: Reducer,
                                                  environment: Dependencies = [],
                                                  services: [Service<State, Action>] = []) -> ObservableStore<State, Action>
    where Reducer.State == State, Reducer.Action == Action {
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
    @inlinable
    static func create<Reducer : ReducerProtocol>(reducer: Reducer,
                                                  environment: Dependencies = [],
                                                  services: [Service<State, Action>] = [],
                                                  configure: (_ constants: Dependencies) -> State) -> ObservableStore<State, Action>
    where Reducer.State == State, Reducer.Action == Action {
        let result = ConcreteStore(initialState: configure(environment),
                                   reducer: reducer,
                                   environment: environment,
                                   services: services)
        return result
    }
    
    #if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
    #if canImport(Combine)
    
    /// Creates a ```CombineStore```.
    /// - Parameters:
    ///     - initialState: The initial state of the store.
    ///     - reducer: The method that is used to modify the state.
    ///     - environment: The constants that the reducer and the services need.
    ///     - services: Instances of service classes that can react to state changes and dispatch further actions.
    /// - Returns: A fully configured ```CombineStore```.
    /// - Note: Exactly the same as Store.create(initialState:reducer:environment:services:).
    
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    @inlinable
    static func combineStore<Reducer : ReducerProtocol>(initialState: Reducer.State,
                                                        reducer: Reducer,
                                                        environment: Dependencies,
                                                        services: [Service<State, Action>]) -> CombineStore<State, Action>
    where Reducer.State == State, Reducer.Action == Action {
        create(initialState: initialState, reducer: reducer, environment: environment, services: services)
    }
    
    
    /// Creates an ```CombineStore```.
    /// - Parameters:
    ///     - reducer: The method that is used to modify the state.
    ///     - environment: The constants that the reducer and the services need. Will also be passd to ```configure```.
    ///     - services: Instances of service classes that can react to state changes and dispatch further actions.
    ///     - configure: Creates the initial state of the app from the app's constants.
    ///     - constants: The same as ```environment```.
    /// - Returns: A fully configured ```CombineStore```.
    /// - Note: Exactly the same as Store.create(reducer:environment:services:configure:).
    
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    @inlinable
    static func combineStore<Reducer : ReducerProtocol>(reducer: Reducer,
                                                        environment: Dependencies,
                                                        services: [Service<State, Action>],
                                                        configure: (_ constants: Dependencies) -> State) -> CombineStore<State, Action>
    where Reducer.State == State, Reducer.Action == Action {
        create(reducer: reducer, environment: environment, services: services, configure: configure)
    }
    
    #endif
    #endif
}
