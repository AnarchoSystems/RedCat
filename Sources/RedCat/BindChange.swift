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

public struct BindChange<Root, Changer : PropertyChange, Action> : DetailReducerProtocol {

    public let keyPath : WritableKeyPath<Root, Changer.Value>
    public let matchAction: CasePath<Action, Changer>
    
    @inlinable
    public init(of property: WritableKeyPath<Root, Changer.Value>,
                to match: @escaping (Changer) -> Action) {
        self.keyPath = property
        self.matchAction = /match
    }
    
    @inlinable
    public func apply(_ action: Changer, to state: inout Changer.Value) {
        state = action.newValue
    }
    
}


public struct BindCase<Root : Releasable, Changer : PropertyChange, Action> : AspectReducerProtocol {
    
    public let casePath: CasePath<Root, Changer.Value>
    public let matchAction: CasePath<Action, Changer>
    
    @inlinable
    public init(of aspect: CasePath<Root, Changer.Value>,
                to match: @escaping (Changer) -> Action) {
        self.casePath = aspect
        self.matchAction = /match
    }
    
    @inlinable
    public func apply(_ action: Changer, to aspect: inout Changer.Value) {
        aspect = action.newValue
    }
    
}


public extension Reducers.Native {
    
    static func bind<Root, Changer : PropertyChange, Action>(_ property: WritableKeyPath<Root, Changer.Value>,
                                                     to match: @escaping (Changer) -> Action) -> BindChange<Root, Changer, Action> {
        BindChange(of: property, to: match)
    }
    
    static func bind<Root : Releasable, Changer : PropertyChange, Action>(_ aspect: CasePath<Root, Changer.Value>,
                                                                          to match: @escaping (Changer) -> Action) -> BindCase<Root, Changer, Action> {
        BindCase(of: aspect, to: match)
    }
    
}
