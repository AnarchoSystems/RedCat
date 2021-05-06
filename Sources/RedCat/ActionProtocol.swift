//
//  ActionProtocol.swift
//  
//
//  Created by Markus Pfeifer on 06.05.21.
//

import Foundation


public protocol ActionProtocol{
    func then<U : ActionProtocol>(_ next: U) -> ActionGroup
}

public struct ActionGroup : ActionProtocol {
 
    @usableFromInline
    var values : [ActionProtocol]
    
    public init(values: [ActionProtocol]){self.values = values}
    
    public init<T>(_ list: [T], build: (T) -> ActionProtocol){self = ActionGroup(values: list.map(build))}
    public init(@ActionBuilder build: () -> ActionGroup){self = build()}
    
    public mutating func append(_ undoable: ActionProtocol) {
        values.append(undoable)
    }
    
    public func then<U : ActionProtocol>(_ next: U) -> ActionGroup {
        ActionGroup(values: values + ((next as? UndoGroup).map(\.values) ?? [next]))
    }
    
}

@_functionBuilder
public enum ActionBuilder {
    public static func buildBlock<C : Collection>(_ elements: C) -> UndoGroup where C.Element == Undoable {
        UndoGroup(values: Array(elements))
    }
    public static func buildBlock<C : Collection>(_ elements: C) -> UndoGroup where C.Element : Undoable {
        UndoGroup(values: elements.map{$0 as Undoable})
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
    public static func buildIf(_ content: Undoable?) -> UndoGroup {content.map{[$0]} ?? []}
}

extension ActionGroup : ExpressibleByArrayLiteral {
    
    public init(arrayLiteral elements: ActionProtocol...) {
        values = elements
    }
    
}

public extension ActionProtocol {
    
    func then<U : ActionProtocol>(_ next: U) -> ActionGroup {
        (next as? ActionGroup).map{ActionGroup(values: [self] + $0.values)} ?? [self, next]
    }
    
}
