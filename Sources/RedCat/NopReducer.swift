//
//  NopReducer.swift
//  
//
//  Created by Markus Pfeifer on 12.05.21.
//

import Foundation


/// A ```NopReducer``` accepts no actions and will do absolutely nothing when it sees one. This is useful in conjunction with ```DispatchReducer```s that return an ```IfReducer```.
public struct NopReducer<State> : ErasedReducer {
    
    @inlinable
    public init() {}
    
    @inlinable
    public func applyErased<Action : ActionProtocol>(_ action: Action,
                                                     to state: inout State) {}
    
    @inlinable
    public func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
        false
    }
    
}


public extension Reducers.Native {
    
    static func nop<State>(stateType: State.Type = State.self) -> NopReducer<State> {
        NopReducer()
    }
    
}
