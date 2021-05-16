//
//  Store.swift
//  
//
//  Created by Markus Pfeifer on 06.05.21.
//

import Foundation


/// ```AppInit``` is dispatched exactly once right after the initialization of a ```CombineStore``` or a ```ObservableStore```.
public struct AppInit : ActionProtocol {}
/// ```AppDeinit``` is dispatched, when ```shotDown()``` is called on a ```Store```. After the dispatch has finished (including actions synchronously dispatched by ```Service```s during ```AppDeinit```), the store becomes invalid.
public struct AppDeinit : ActionProtocol {}


/// A ```Store``` contains the "global" AppState and exposes the main methods to mutate the state.
public class Store<State> {
    
    /// The "global" state of the application.
    public var state : State {
        fatalError()
    }
    
    @usableFromInline
    internal var hasInitialized = false
    @usableFromInline
    internal var hasShutdown = false
    
    // prevent external initialization
    // makes external subclasses uninitializable
    internal init() {}
    
    
    /// Dispatches ```AppDeinit``` and invalidates the receiver.
    ///
    /// Use this method when your App is about to terminate to trigger cleanup actions.
    public final func shutDown() {
        send(AppDeinit())
        hasShutdown = true
    }
    
    /// Applies an action to the state using the App's main reducer.
    /// - Parameters:
    ///     - action: The action to dispatch.
    ///
    /// This method is not threadsafe and has to be called on the mainthread.
    public func send<Action : ActionProtocol>(_ action: Action) {
        fatalError()
    }
    
    func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
        fatalError()
    }
    
    /// Applies an undoable action to the state using the App's main reducer and registers the inverted action at the specified ```UndoManager```.
    /// - Parameters:
    ///     - action: The action to dispatch.
    ///     - undoTitle: The name of the inverted action.
    ///     - redoTitle: The name of the action.
    /// This method is not threadsafe and has to be called on the mainthread.
    @available(OSX 10.11, *)
    public final func sendWithUndo<Action: Undoable>(_ action: Action,
                                               undoTitle: String? = nil,
                                               redoTitle: String? = nil,
                                               undoManager: UndoManager?) {
        send(action)
        undoManager?.registerUndo(withTarget: self) {target in
            target.sendWithUndo(action.inverted(),
                                undoTitle: redoTitle,
                                redoTitle: undoTitle,
                                undoManager: undoManager)
        }
        if let undoTitle = undoTitle {
            undoManager?.setActionName(undoTitle)
        }
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
                                                environment: Dependencies,
                                                services: [Service<Reducer.State>]) -> ObservableStore<State>
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
                                                environment: Dependencies,
                                                services: [Service<Reducer.State>],
                                                configure: (_ constants: Dependencies) -> State) -> ObservableStore<State>
    where Reducer.State == State {
        let result = ConcreteStore(initialState: configure(environment),
                                   reducer: reducer,
                                   environment: environment,
                                   services: services)
        return result
    }
    
    
    #if os(iOS) || os(macOS)
    #if canImport(Combine)
    
    /// Creates a ```CombineStore```.
    /// - Parameters:
    ///     - initialState: The initial state of the store.
    ///     - reducer: The method that is used to modify the state.
    ///     - environment: The constants that the reducer and the services need.
    ///     - services: Instances of service classes that can react to state changes and dispatch further actions.
    /// - Returns: A fully configured ```CombineStore```.
    @available(OSX 10.15, *)
    @available(iOS 13.0, *)
    static func combineStore<Body : ErasedReducer>(initialState: Body.State,
                                                      reducer: Body,
                                                      environment: Dependencies,
                                                      services: [Service<Body.State>]) -> CombineStore<Body.State>
    where Body.State == State {
        let result = ConcreteCombineStore(initialState: initialState,
                                          reducer: reducer,
                                          environment: environment,
                                          services: services)
        return result
    }
    
    
    /// Creates an ```CombineStore```.
    /// - Parameters:
    ///     - reducer: The method that is used to modify the state.
    ///     - environment: The constants that the reducer and the services need. Will also be passd to ```configure```.
    ///     - services: Instances of service classes that can react to state changes and dispatch further actions.
    ///     - configure: Creates the initial state of the app from the app's constants.
    ///     - constants: The same as ```environment```.
    /// - Returns: A fully configured ```CombineStore```.
    @available(OSX 10.15, *)
    @available(iOS 13.0, *)
    static func combineStore<Body : ErasedReducer>(reducer: Body,
                                                      environment: Dependencies,
                                                      services: [Service<Body.State>],
                                                      configure: (_ constants: Dependencies) -> State) -> CombineStore<Body.State>
    where Body.State == State {
        let result = ConcreteCombineStore(initialState: configure(environment),
                                          reducer: reducer,
                                          environment: environment,
                                          services: services)
        return result
    }
    
    #endif
    #endif
    
}
