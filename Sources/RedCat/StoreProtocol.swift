//
//  StoreProtocol.swift
//  
//
//  Created by Данил Войдилов on 30.05.2021.
//

import Foundation

public protocol __StoreProtocol : AnyObject {
    associatedtype State
    associatedtype Action
    var state: State { get }
    func send(_ action: Action)
}

public extension __StoreProtocol {
    
    /// Applies an undoable action to the state using the App's main reducer and registers the inverted action at the specified ```UndoManager```.
    /// - Parameters:
    ///     - action: The action to dispatch.
    ///     - embed: Turns the given action into an action recognized by the store.
    ///     - undoTitle: The name of the inverted action.
    ///     - redoTitle: The name of the action.
    /// This method is not threadsafe and has to be called on the mainthread.
    @available(OSX 10.11, *)
    func sendWithUndo<Action: Undoable>(_ action: Action,
                                               embed: @escaping (Action) -> Self.Action,
                                               undoTitle: String? = nil,
                                               redoTitle: String? = nil,
                                               undoManager: UndoManager?) {
        send(embed(action))
        undoManager?.registerUndo(withTarget: self) {target in
            target.sendWithUndo(action.inverted(),
                                embed: embed,
                                undoTitle: redoTitle,
                                redoTitle: undoTitle,
                                undoManager: undoManager)
        }
        if let undoTitle = undoTitle {
            undoManager?.setActionName(undoTitle)
        }
    }
    
}


public extension __StoreProtocol where Action : Undoable {
    
    /// Applies an undoable action to the state using the App's main reducer and registers the inverted action at the specified ```UndoManager```.
    /// - Parameters:
    ///     - action: The action to dispatch.
    ///     - undoTitle: The name of the inverted action.
    ///     - redoTitle: The name of the action.
    /// This method is not threadsafe and has to be called on the mainthread.
    @available(OSX 10.11, *)
    func sendWithUndo(_ action: Action,
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
