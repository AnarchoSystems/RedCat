//
//  Binding.swift
//  RedCat
//
//  Created by Markus Pfeifer on 15.05.21.
//

//https://stackoverflow.com/questions/66716119/cannot-find-swiftui-or-combine-types-when-building-swift-package-for-any-ios-de/67853022#67853022

#if os(macOS) || os(watchOS) || os(tvOS) || (os(iOS) && arch(arm64))
#if canImport(SwiftUI)

import SwiftUI

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension Store {
    
    /// Exposes a value as a binding, if provided with an action that serves as a setter.
    func binding<Value>(for value: @escaping (State) -> Value,
                                action: @escaping (Value) -> Action)
    -> Binding<Value> {
        Binding(get: {value(self.state)},
                set: {self.send(action($0))})
    }
    
    /// Exposes a value as a binding, if provided with an action that serves as a setter.
    func binding<Value, A : Undoable>(for value: @escaping (State) -> Value,
                                           withUndoManager: UndoManager?,
                                           undoTitle: String? = nil,
                                           redoTitle: String? = nil,
                                           embed: @escaping (A) -> Action,
                                           action: @escaping (Value) -> A)
    -> Binding<Value> {
        Binding(get: {value(self.state)},
                set: {self.sendWithUndo(action($0),
                                        embed: embed,
                                        undoTitle: undoTitle,
                                        redoTitle: redoTitle,
                                        undoManager: withUndoManager)})
    }
    
}

#endif
#endif
