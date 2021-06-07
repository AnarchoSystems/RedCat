//
//  Store.swift
//  
//
//  Created by Markus Pfeifer on 06.05.21.
//

import Foundation

/// A ```Store``` contains the "global" AppState and exposes the main methods to mutate the state.
@dynamicMemberLookup
public class Store<State>: __StoreProtocol {
    
    /// The "global" state of the application.
    public var state : State {
        fatalError()
    }
    
    // prevent external initialization
    // makes external subclasses uninitializable
    @inlinable
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
    
    /// Dispatches ```AppDeinit``` and invalidates the receiver.
    ///
    /// Use this method when your App is about to terminate to trigger cleanup actions.
    public func shutDown(){
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
    @inlinable
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
    static func combineStore<Body : ErasedReducer>(initialState: Body.State,
                                                   reducer: Body,
                                                   environment: Dependencies,
                                                   services: [Service<Body.State>]) -> CombineStore<Body.State>
    where Body.State == State {
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
    static func combineStore<Body : ErasedReducer>(reducer: Body,
                                                   environment: Dependencies,
                                                   services: [Service<Body.State>],
                                                   configure: (_ constants: Dependencies) -> State) -> CombineStore<Body.State>
    where Body.State == State {
        create(reducer: reducer, environment: environment, services: services, configure: configure)
    }
    
    #endif
    #endif
}
