//
//  Undoable.swift
//  
//
//  Created by Markus Pfeifer on 06.05.21.
//

import Foundation


public protocol Undoable : ActionProtocol {
    mutating func invert()
    func inverted() -> Self
    func then<U : Undoable>(_ next: U) -> UndoGroup
}

public extension Undoable {
    func inverted() -> Self {
        var copy = self
        copy.invert()
        return copy
    }
}

public struct UndoGroup : Undoable {
 
    @usableFromInline
    var values : [Undoable]
    
    public init(values: [Undoable]) {self.values = values}
    
    public init<T>(_ list: [T], build: (T) -> Undoable) {self = UndoGroup(values: list.map(build))}
    public init(@UndoBuilder build: () -> UndoGroup) {self = build()}
    
    public mutating func invert() {
        values.reverse()
        for idx in values.indices {
            values[idx].invert()
        }
    }
    
    public mutating func append(_ undoable: Undoable) {
        values.append(undoable)
    }
    
    public func then<U : Undoable>(_ next: U) -> UndoGroup {
        UndoGroup(values: values + ((next as? UndoGroup).map(\.values) ?? [next]))
    }
    
    @usableFromInline
    mutating func unroll() {
        
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
