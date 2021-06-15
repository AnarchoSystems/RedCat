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

    public let keyPath : WritableKeyPath<Root, Changer.Value>
    
    @inlinable
    public init(of property: WritableKeyPath<Root, Changer.Value>,
                to type: Changer.Type = Changer.self) {
        self.keyPath = property
    }
    
    @inlinable
    public func apply(_ action: Changer, to state: inout Changer.Value) {
        state = action.newValue
    }
    
}


public struct BindCase<Root : Releasable, Changer : PropertyChange> : AspectReducerProtocol {
    
    public let casePath: CasePath<Root, Changer.Value>
    
    @inlinable
    public init(of aspect: CasePath<Root, Changer.Value>,
                to type: Changer.Type = Changer.self) {
        self.casePath = aspect
    }
    
    @inlinable
    public func apply(_ action: Changer, to aspect: inout Changer.Value) {
        aspect = action.newValue
    }
    
}


public extension Reducers.Native {
    
    static func bind<Root, Changer : PropertyChange>(_ property: WritableKeyPath<Root, Changer.Value>,
                                                     to type: Changer.Type = Changer.self) -> BindChange<Root, Changer> {
        BindChange(of: property, to: type)
    }
    
    static func bind<Root : Releasable, Changer : PropertyChange>(_ aspect: CasePath<Root, Changer.Value>,
                                                                  to type: Changer.Type) -> BindCase<Root, Changer> {
        BindCase(of: aspect, to: type)
    }
    
}
