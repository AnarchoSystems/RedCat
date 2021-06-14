//
//  SequentiallyComposable.swift
//  
//
//  Created by Markus Pfeifer on 06.05.21.
//

import Foundation


public protocol SequentiallyComposable {}

public extension SequentiallyComposable {
    func then(_ other: Self) -> ActionGroup<Self> {
        [self, other]
    }
}


/// An ```ActionGroup``` is a block of actions that can be dispatched with one call to ```send```.
/// - Important: Actions enqueued by ```Service```s will execute only after the entire block of actions has been processed.
public struct ActionGroup<Action> : RandomAccessCollection {
 
    @usableFromInline
    var values : [Action]
    
    /// Initializes the ```ActionGroup```.
    public init(values: [Action]) {self.values = values}
    
    public init<T>(_ list: [T], build: (T) -> Action) {self = ActionGroup(values: list.map(build))}
    public init(@ActionBuilder build: () -> ActionGroup) {self = build()}
    
    /// Appends another action to the receiver.
    public mutating func append(_ next: Action) {
        values.append(next)
    }
    
    public mutating func append(contentsOf group: Self) {
        values.append(contentsOf: group.values)
    }
    
    public func then(_ next: Action) -> ActionGroup {
        ActionGroup(values: values + [next])
    }
    
    public func then(_ group: Self) -> Self {
        ActionGroup(values: values + group.values)
    }
    
    public var startIndex : Int {values.startIndex}
    public var endIndex : Int {values.endIndex}
    public func index(after i: Int) -> Int {values.index(after: i)}
    public subscript(position: Int) -> Action {values[position]}
    
}

extension ActionGroup : Equatable where Action : Equatable {}

@resultBuilder
public enum ActionBuilder {
    public static func buildBlock<Action>(_ elements: Action...) -> ActionGroup<Action> {
        ActionGroup(values: elements)
    }
    public static func buildEither<Action>(first: ActionGroup<Action>) -> ActionGroup<Action> {
        first
    }
    public static func buildEither<Action>(second: ActionGroup<Action>) -> ActionGroup<Action> {
        second
    }
    public static func buildIf<Action>(_ content: Action?) -> ActionGroup<Action> {
        content.map {[$0]} ?? []
    }
    
    public static func buildArray<Action>(_ components: [Action]) -> ActionGroup<Action> {
        ActionGroup(values: components)
    }
}

extension ActionGroup : ExpressibleByArrayLiteral {
    
    public init(arrayLiteral elements: Action...) {
        values = elements
    }
    
}
