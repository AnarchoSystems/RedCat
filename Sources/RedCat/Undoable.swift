//
//  Undoable.swift
//  
//
//  Created by Markus Pfeifer on 06.05.21.
//

import Foundation


///```Undoable``` actions can be sent to a ```Store``` along with an ```UndoManager``` to enable undo and redo.
public protocol Undoable : SequentiallyComposable {
    
    ///Inverts the action.
    mutating func invert()
    
    ///Returns the opposite of the action.
    func inverted() -> Self
    
}

public extension Undoable {
    
    func inverted() -> Self {
        var copy = self
        copy.invert()
        return copy
    }
    
    /// Seqentially chains the undoable action with another undoable action so they can be dispatched in a block.
    /// - Parameters:
    ///     - next: The next undoable action to execute.
    /// - Returns: A group of undoable actions that will be dispatched in a block.
    func then(_ next: Self) -> UndoGroup<Self> {
        [self, next]
    }
    
}

/// An ```UndoGroup``` is a block of undoable actions that can be dispatched with one call to ```send``` or ```sendWithUndo```.
/// - Important: Actions enqueued by ```Service```s will execute only after the entire block of actions has been processed.
public struct UndoGroup<Action : Undoable> : Undoable, RandomAccessCollection {
 
    @usableFromInline
    var values : [Action]
    
    /// Initializes the ```UndoGroup```.
    public init(values: [Action]) {self.values = values}
    
    public init<T>(_ list: [T], build: (T) -> Action) {self = UndoGroup(values: list.map(build))}
    public init(@UndoBuilder build: () -> UndoGroup) {self = build()}
    
    public mutating func invert() {
        values.reverse()
        for idx in values.indices {
            values[idx].invert()
        }
    }
    
    /// Appends another action to the receiver.
    public mutating func append(_ undoable: Action) {
        values.append(undoable)
    }
    
    public mutating func append(contentsOf other: Self) {
        values.append(contentsOf: other.values)
    }
    
    public func then(_ next: Action) -> Self {
        var result = self
        result.append(next)
        return result
    }
    
    public func then(_ next: Self) -> Self {
        var result = self
        result.append(contentsOf: next)
        return result 
    }
    
    public func asActionGroup() -> ActionGroup<Action> {
        ActionGroup(values: values)
    }
    
    public var startIndex : Int {values.startIndex}
    public var endIndex : Int {values.endIndex}
    public func index(after i: Int) -> Int {values.index(after: i)}
    public subscript(position: Int) -> Action {values[position]}
    
}

extension UndoGroup : Equatable where Action : Equatable {}

@resultBuilder
public enum UndoBuilder {
    
    public static func buildExpression<Action>(_ expression: Action) -> UndoGroup<Action> {
        UndoGroup(values: [expression])
    }
    
    public static func buildBlock<Action>(_ elements: UndoGroup<Action>...) -> UndoGroup<Action> {
        UndoGroup(values: elements.flatMap(\.values))
    }
    
    public static func buildEither<Action>(first: UndoGroup<Action>) -> UndoGroup<Action> {
        first
    }
    
    public static func buildEither<Action>(second: UndoGroup<Action>) -> UndoGroup<Action> {
        second
    }
    
    public static func buildIf<Action>(_ content: Action?) -> UndoGroup<Action> {
        content.map {[$0]} ?? []
    }
    
    public static func buildArray<Action>(_ components: [UndoGroup<Action>]) -> UndoGroup<Action> {
        UndoGroup(values: components.flatMap(\.values))
    }
    
}

extension UndoGroup : ExpressibleByArrayLiteral {
    
    public init(arrayLiteral elements: Action...) {
        values = elements
    }
    
}
