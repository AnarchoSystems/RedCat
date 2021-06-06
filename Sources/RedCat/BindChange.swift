//
//  BindChange.swift
//  RedCat
//
//  Created by Markus Pfeifer on 12.05.21.
//

import CasePaths


public protocol PropertyChange : Undoable {
    associatedtype Value
    var oldValue : Value {get set}
    var newValue : Value {get set}
}

public extension PropertyChange {
    mutating func invert() {
        (oldValue, newValue) = (newValue, oldValue)
    }
}

public struct BindChange<Root, Changer : PropertyChange> : DetailReducerProtocol {

    public typealias State = Root
    public let keyPath : WritableKeyPath<Root, Changer.Value>
    
    @inlinable
    public init(of property: WritableKeyPath<Root, Changer.Value>, to actionType: Changer.Type) {
        self.keyPath = property
    }
    
    @inline(__always)
    public func apply(_ action: Changer, to state: inout Changer.Value) {
        state = action.newValue
    }
    
}


public struct BindCase<Root : Releasable, Changer : PropertyChange> : AspectReducerProtocol {
    
    public typealias State = Root
    public let casePath: CasePath<Root, Changer.Value>
    
    @inlinable
    public init(of aspect: CasePath<Root, Changer.Value>, to actionType: Changer.Type) {
        self.casePath = aspect
    }
    
    @inline(__always)
    public func apply(_ action: Changer, to aspect: inout Changer.Value) {
        aspect = action.newValue
    }
    
}
