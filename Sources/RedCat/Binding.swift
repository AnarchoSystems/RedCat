//
//  Binding.swift
//  RedCat
//
//  Created by Markus Pfeifer on 15.05.21.
//

#if canImport(SwiftUI)
import SwiftUI

@available(watchOS 6.0, *)
@available(tvOS 13.0, *)
@available(iOS 13.0, *)
@available(macOS 10.15, *)
public extension Store {
    
    func binding<Value, Action: ActionProtocol>(for value: @escaping (State) -> Value,
                                                action: @escaping (Value) -> Action)
    -> Binding<Value> {
        Binding(get: {value(self.state)},
                set: {self.send(action($0))})
    }
    
    func binding<Value, Action : Undoable>(for value: @escaping (State) -> Value,
                                           withUndoManager: UndoManager?,
                                           undoTitle: String? = nil,
                                           redoTitle: String? = nil,
                                           action: @escaping (Value) -> Action)
    -> Binding<Value> {
        Binding(get: {value(self.state)},
                set: {self.sendWithUndo(action($0),
                                        undoTitle: undoTitle,
                                        redoTitle: redoTitle,
                                        undoManager: withUndoManager)})
    }
    
}

#endif
