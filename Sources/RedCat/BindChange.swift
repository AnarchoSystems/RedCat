//
//  BindChange.swift
//  RedCat
//
//  Created by Markus Pfeifer on 12.05.21.
//

import CasePaths


public protocol Change : Undoable {
    associatedtype Value
    var oldValue : Value {get set}
    var newValue : Value {get set}
}

public extension Change {
    mutating func invert() {
        (oldValue, newValue) = (newValue, oldValue)
    }
}

public struct BindChange<Root, Changer : Change> : DetailReducer {

    public typealias State = Root
    public let keyPath : WritableKeyPath<Root, Changer.Value>
    
    public init(of property: WritableKeyPath<Root, Changer.Value>, to actionType: Changer.Type) {
        self.keyPath = property
    }
    
    public func apply(_ action: Changer, to state: inout Changer.Value) {
        state = action.newValue
    }
    
}


public struct BindMaybeChange<Root : Emptyable, Changer : Change> : AspectReducer {
    
    public typealias State = Root
    public let casePath: CasePath<Root, Changer.Value>
    
    public init(of aspect: CasePath<Root, Changer.Value>, to actionType: Changer.Type) {
        self.casePath = aspect
    }
    
    public func apply(_ action: Changer, to aspect: inout Changer.Value) {
        aspect = action.newValue
    }
    
}
