//
//  StoreProtocol.swift
//  
//
//  Created by Данил Войдилов on 30.05.2021.
//

import Foundation

/// ```StoreProtocol``` is the ideal place to extend the functionality of all stores.
/// Conforming to this protocol directly is, however, not advised. ```Store``` should provide all functionality that you need.
/// If you want to write *decorators* for existing store types, conform to ```StoreWrapper``` instead.
public protocol StoreProtocol {
    
    associatedtype RootStore : StoreProtocol & AnyObject
    associatedtype State
    associatedtype Action
    
    var rootStore : RootStore {get}
    func getRecoverer() -> Recoverer<RootStore, Self>
    
    /// The "global" state of the application.
    var state: State { get }
    
    var objectWillChange : StoreObjectWillChangePublisher {get}
    
    /// Applies an action to the state using the App's main reducer.
    /// - Parameters:
    ///     - action: The action to dispatch.
    ///
    /// This method is not threadsafe and has to be called on the mainthread.
    func send(_ action: Action)
    
    /// Applies a group of actions to the state using the App's main reducer.
    /// - Parameters:
    ///     - list: The list of actions to dispatch in one dispatch cycle.
    func send(_ list: ActionGroup<Action>)
    
    /// Notifies the services that the app is about to be terminated and invalidates the receiver.
    ///
    /// Use this method when your App is about to terminate to trigger cleanup actions.
    func shutDown()
    
}

public struct Recoverer<Root, Value> {
    @usableFromInline
    let _recover : (Root) -> Value
    public init(_ recover: @escaping (Root) -> Value) {
        self._recover = recover
    }
    public func recover(from root: Root) -> Value {
        _recover(root)
    }
}

public extension StoreProtocol where Self : AnyObject {
    
    @inlinable
    var rootStore : Self {self}
    
    @inlinable
    func getRecoverer() -> Recoverer<Self, Self> {
        Recoverer{$0}
    }
    
    
}

public extension StoreProtocol {
    
    /// Applies a group of actions to the state using the App's main reducer.
    /// - Parameters:
    ///     - list: The list of actions to dispatch in one dispatch cycle.
    ///     - embed: How the actions are to be interpreted by the reducer.
    func send<A>(_ list: ActionGroup<A>,
                 embed: (A) -> Action) {
        send(ActionGroup(values: list.map(embed)))
    }
    
}

public extension StoreProtocol {
    
    /// Applies an undoable action to the state using the App's main reducer and registers the inverted action at the specified ```UndoManager```.
    /// - Parameters:
    ///     - action: The action to dispatch.
    ///     - undoTitle: The name of the inverted action.
    ///     - redoTitle: The name of the action.
    ///     - undoManager: An ```UndoManager```, for example the one attached to the current window.
    ///     - embed: Turns the given action into an action recognized by the store.
    /// This method is not threadsafe and has to be called on the mainthread.
    @available(OSX 10.11, *)
    func sendWithUndo<Action: Undoable>(_ action: Action,
                                        undoTitle: String? = nil,
                                        redoTitle: String? = nil,
                                        undoManager: UndoManager?,
                                        embed: @escaping (Action) -> Self.Action) {
        let recoverer = getRecoverer()
        send(embed(action))
        undoManager?.registerUndo(withTarget: rootStore) {target in
            recoverer.recover(from: target).sendWithUndo(action.inverted(),
                                                         undoTitle: redoTitle,
                                                         redoTitle: undoTitle,
                                                         undoManager: undoManager,
                                                         embed: embed)
        }
        if let undoTitle = undoTitle {
            undoManager?.setActionName(undoTitle)
        }
    }
    
    /// Applies an undoable action to the state using the App's main reducer and registers the inverted action at the specified ```UndoManager```.
    /// - Parameters:
    ///     - list: The actions to dispatch.
    ///     - undoTitle: The name of the inverted action.
    ///     - redoTitle: The name of the action.
    ///     - undoManager: An ```UndoManager```, for example the one attached to the current window.
    ///     - embed: Turns the given action into an action recognized by the store.
    /// This method is not threadsafe and has to be called on the mainthread.
    @available(OSX 10.11, *)
    func sendWithUndo<Action: Undoable>(_ list: UndoGroup<Action>,
                                        undoTitle: String? = nil,
                                        redoTitle: String? = nil,
                                        undoManager: UndoManager?,
                                        embed: @escaping (Action) -> Self.Action) {
        let recoverer = getRecoverer()
        send(ActionGroup(values: list.values), embed: embed)
        undoManager?.registerUndo(withTarget: rootStore) {target in
            recoverer.recover(from: target).sendWithUndo(list.inverted(),
                                                         undoTitle: redoTitle,
                                                         redoTitle: undoTitle,
                                                         undoManager: undoManager,
                                                         embed: embed)
        }
        if let undoTitle = undoTitle {
            undoManager?.setActionName(undoTitle)
        }
    }
    
}


public extension StoreProtocol where Action : Undoable {
    
    /// Applies an undoable action to the state using the App's main reducer and registers the inverted action at the specified ```UndoManager```.
    /// - Parameters:
    ///     - action: The action to dispatch.
    ///     - undoTitle: The name of the inverted action.
    ///     - redoTitle: The name of the action.
    ///     - undoManager: An ```UndoManager```, for example the one attached to the current window.     
    /// This method is not threadsafe and has to be called on the mainthread.
    @available(OSX 10.11, *)
    func sendWithUndo(_ action: Action,
                      undoTitle: String? = nil,
                      redoTitle: String? = nil,
                      undoManager: UndoManager?) {
        sendWithUndo(action,
                     undoTitle: undoTitle,
                     redoTitle: redoTitle,
                     undoManager: undoManager,
                     embed: {$0})
    }
    
    /// Applies an undoable action to the state using the App's main reducer and registers the inverted action at the specified ```UndoManager```.
    /// - Parameters:
    ///     - list: The actions to dispatch.
    ///     - undoTitle: The name of the inverted action.
    ///     - redoTitle: The name of the action.
    ///     - undoManager: An ```UndoManager```, for example the one attached to the current window.
    /// This method is not threadsafe and has to be called on the mainthread.
    @available(OSX 10.11, *)
    func sendWithUndo(_ list: UndoGroup<Action>,
                      undoTitle: String? = nil,
                      redoTitle: String? = nil,
                      undoManager: UndoManager?) {
        sendWithUndo(list,
                     undoTitle: undoTitle,
                     redoTitle: redoTitle,
                     undoManager: undoManager,
                     embed: {$0})
    }
    
}
