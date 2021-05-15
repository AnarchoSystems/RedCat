//
//  Undoable.swift
//  
//
//  Created by Markus Pfeifer on 06.05.21.
//

import Foundation


///```Undoable``` actions can be sent to a ```Store``` along with an ```UndoManager``` to enable undo and redo.
public protocol Undoable : ActionProtocol {
    
    ///Inverts the action.
    mutating func invert()
    
    ///Returns the opposite of the action.
    func inverted() -> Self
    
    /// Seqentially chains the undoable action with another undoable action so they can be dispatched in a block.
    /// - Parameters:
    ///     - next: The next undoable action to execute.
    /// - Returns: A group of undoable actions that will be dispatched in a block.
    func then<U : Undoable>(_ next: U) -> UndoGroup
}

public extension Undoable {
    func inverted() -> Self {
        var copy = self
        copy.invert()
        return copy
    }
}

/// An ```UndoGroup``` is a block of undoable actions that can be dispatched with one call to ```send``` or ```sendWithUndo```.
/// - Important: Actions enqueued by ```Service```s will execute only after the entire block of actions has been processed.
public struct UndoGroup : Undoable {
 
    @usableFromInline
    var values : [Undoable]
    
    /// Initializes the ```UndoGroup```.
    public init(values: [Undoable]) {self.values = values}
    
    public init<T>(_ list: [T], build: (T) -> Undoable) {self = UndoGroup(values: list.map(build))}
    public init(@UndoBuilder build: () -> UndoGroup) {self = build()}
    
    public mutating func invert() {
        values.reverse()
        for idx in values.indices {
            values[idx].invert()
        }
    }
    
    /// Appends another action to the receiver.
    public mutating func append(_ undoable: Undoable) {
        values.append(undoable)
    }
    
    public func then<U : ActionProtocol>(_ next: U) -> ActionGroup {
        ActionGroup(values: values + ((next as? ActionGroup).map(\.values) ?? [next]))
    }
    
    public func then<U : Undoable>(_ next: U) -> UndoGroup {
        UndoGroup(values: values + ((next as? UndoGroup).map(\.values) ?? [next]))
    }
    
    ///If the receiver contains any nested ```UndoGroup```s, they will be successively unrolled into one long sequence.
    @inlinable
    public mutating func unroll() {
        
        var idx = 0
        while idx < values.count {
            if let subList = values[idx] as? UndoGroup {
                values.replaceSubrange(idx...idx, with: subList.values)
            }
            else {
                idx += 1
            }
        }
        
    }
    
}

@resultBuilder
public enum UndoBuilder {
    public static func buildBlock<C : Collection>(_ elements: C) -> UndoGroup where C.Element == Undoable {
        UndoGroup(values: Array(elements))
    }
    public static func buildBlock<C : Collection>(_ elements: C) -> UndoGroup where C.Element : Undoable {
        UndoGroup(values: elements.map {$0 as Undoable})
    }
    public static func buildBlock(_ elements: Undoable...) -> UndoGroup {
        UndoGroup(values: elements)
    }
    public static func buildEither(first: UndoGroup) -> UndoGroup {
        first
    }
    public static func buildEither(second: UndoGroup) -> UndoGroup {
        second
    }
    public static func buildIf(_ content: Undoable?) -> UndoGroup {content.map {[$0]} ?? []}
    
    public func buildArray(_ components: [Undoable]) -> UndoGroup {
        UndoGroup(values: components)
    }
}

extension UndoGroup : ExpressibleByArrayLiteral {
    
    public init(arrayLiteral elements: Undoable...) {
        values = elements
    }
    
}

public extension Undoable {
    
    func then<U : Undoable>(_ next: U) -> UndoGroup {
        (next as? UndoGroup).map {UndoGroup(values: [self] + $0.values)} ?? [self, next]
    }
    
}
