//
//  File.swift
//  
//
//  Created by Данил Войдилов on 30.05.2021.
//

import Foundation

public protocol StoreProtocol: AnyObject {
	associatedtype State
	var state: State { get }
	func send<Action : ActionProtocol>(_ action: Action)
	func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool
}

extension StoreProtocol where Self: AnyObject {
	
	/// Applies an undoable action to the state using the App's main reducer and registers the inverted action at the specified ```UndoManager```.
	/// - Parameters:
	///     - action: The action to dispatch.
	///     - undoTitle: The name of the inverted action.
	///     - redoTitle: The name of the action.
	/// This method is not threadsafe and has to be called on the mainthread.
	@available(OSX 10.11, *)
	public func sendWithUndo<Action: Undoable>(_ action: Action,
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
