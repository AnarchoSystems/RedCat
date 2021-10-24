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


public struct KeyPathReducer<Root, Value> : DetailReducerProtocol {
    
    public let keyPath: WritableKeyPath<Root, Value>
    
    public init(_ keyPath: WritableKeyPath<Root, Value>) {
        self.keyPath = keyPath
    }
    
    public func apply(_ action: Value, to detail: inout Value) {
        detail = action
    }
    
}


public struct SetValueWithUndo<Root> : Undoable {
    
    let write : (inout Root, Any) -> Void
    var oldValue : Any
    var newValue : Any
    
    public init<Value>(_ keyPath: WritableKeyPath<Root, Value>,
                oldValue: Value,
                newValue: Value)
    {
        write = {$0[keyPath: keyPath] = $1 as! Value}
        self.oldValue = oldValue
        self.newValue = newValue
    }
    
    public mutating func invert() {
        (oldValue, newValue) = (newValue, oldValue)
    }
    
}


public struct SetValueNoUndo<Root> {
    
    let write : (inout Root, Any) -> Void
    let newValue : Any
    
    public init<Value>(_ keyPath: WritableKeyPath<Root, Value>,
                       newValue: Value)
    {
        write = {$0[keyPath: keyPath] = $1 as! Value}
        self.newValue = newValue
    }
    
}

public enum SetValue<Root> {
    
    case withUndo(SetValueWithUndo<Root>)
    case noUndo(SetValueNoUndo<Root>)
    
}


public struct TakeControlWithUndo<Root> : ReducerProtocol {
  
    public init() {}
    
    public func apply(_ action: SetValueWithUndo<Root>, to state: inout Root) {
        action.write(&state, action.newValue)
    }
    
}


public struct TakeControlNoUndo<Root> : ReducerProtocol {
    
    public init() {}
    
    public func apply(_ action: SetValueNoUndo<Root>, to state: inout Root) {
        action.write(&state, action.newValue)
    }
    
}


public struct TakeControl<Root> : DispatchReducerProtocol {
    
    public init() {}
    
    public func dispatch(_ action: SetValue<Root>) -> VoidReducer<Root> {
        
        switch action {
        case .withUndo(let withUndo):
            return TakeControlWithUndo().send(withUndo)
        case .noUndo(let noUndo):
            return TakeControlNoUndo().send(noUndo)
        }
        
    }
    
}
