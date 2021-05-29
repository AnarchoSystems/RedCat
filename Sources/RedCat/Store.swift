//
//  Store.swift
//  
//
//  Created by Markus Pfeifer on 06.05.21.
//

import Foundation


/// A ```Store``` contains the "global" AppState and exposes the main methods to mutate the state.
@dynamicMemberLookup
open class Store<State> {
    
    /// The "global" state of the application.
		open var state : State {
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
		open func send<Action : ActionProtocol>(_ action: Action) {
        fatalError()
    }
    
		open func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
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
}
