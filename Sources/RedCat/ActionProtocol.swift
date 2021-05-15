//
//  ActionProtocol.swift
//  
//
//  Created by Markus Pfeifer on 06.05.21.
//

import Foundation


/// All Actions that are sent to the ```Store``` have to conform to ```ActionProtocol```.
public protocol ActionProtocol {
    
    /// Seqentially chains the action with another action so they can be dispatched in a block.
    /// - Parameters:
    ///     - next: The next action to execute.
    /// - Returns: A group of actions that will be dispatched in a block.
    func then<U : ActionProtocol>(_ next: U) -> ActionGroup

}

/// An ```ActionGroup``` is a block of actions that can be dispatched with one call to ```send```.
/// - Important: Actions enqueued by ```Service```s will execute only after the entire block of actions has been processed.
public struct ActionGroup : ActionProtocol {
 
    @usableFromInline
    var values : [ActionProtocol]
    
    /// Initializes the ```ActionGroup```.
    public init(values: [ActionProtocol]) {self.values = values}
    
    public init<T>(_ list: [T], build: (T) -> ActionProtocol) {self = ActionGroup(values: list.map(build))}
    public init(@ActionBuilder build: () -> ActionGroup) {self = build()}
    
    /// Appends another action to the receiver.
    public mutating func append(_ next: ActionProtocol) {
        values.append(next)
    }
    
    public func then<U : ActionProtocol>(_ next: U) -> ActionGroup {
        ActionGroup(values: values + ((next as? ActionGroup).map(\.values) ?? (next as? UndoGroup).map(\.values) ?? [next]))
    }
    
    ///If the receiver contains any nested ```ActionGroup```s or ```UndoGroup```s, they will be successively unrolled into one long sequence.
    @inlinable
    public mutating func unroll() {
        
        var idx = 0
        while idx < values.count {
            if let subList = values[idx] as? ActionGroup {
                values.replaceSubrange(idx...idx, with: subList.values)
            }
            else if let subList = values[idx] as? UndoGroup {
                values.replaceSubrange(idx...idx, with: subList.values)
            }
            else {
                idx += 1
            }
        }
        
    }
    
}

@resultBuilder
public enum ActionBuilder {
    public static func buildBlock<C : Collection>(_ elements: C) -> ActionGroup where C.Element == ActionProtocol {
        ActionGroup(values: Array(elements))
    }
    public static func buildBlock<C : Collection>(_ elements: C) -> ActionGroup where C.Element : ActionProtocol {
        ActionGroup(values: elements.map {$0 as ActionProtocol})
    }
    public static func buildBlock(_ elements: ActionProtocol...) -> ActionGroup {
        ActionGroup(values: elements)
    }
    public static func buildEither(first: ActionGroup) -> ActionGroup {
        first
    }
    public static func buildEither(second: ActionGroup) -> ActionGroup {
        second
    }
    public static func buildIf(_ content: ActionProtocol?) -> ActionGroup {content.map {[$0]} ?? []}
    
    public static func buildArray(_ components: [ActionProtocol]) -> ActionGroup {
        ActionGroup(values: components)
    }
}

extension ActionGroup : ExpressibleByArrayLiteral {
    
    public init(arrayLiteral elements: ActionProtocol...) {
        values = elements
    }
    
}

public extension ActionProtocol {
    
    func then<U : ActionProtocol>(_ next: U) -> ActionGroup {
        (next as? ActionGroup).map {ActionGroup(values: [self] + $0.values)} ?? [self, next]
    }
    
}
