//
//  NopReducer.swift
//  
//
//  Created by Markus Pfeifer on 12.05.21.
//

import Foundation


/// A ```NopReducer``` accepts no actions and will do absolutely nothing when it sees one. This is useful in conjunction with ```DispatchReducer```s that return an ```IfReducer```.
public struct NopReducer<State, Action> : ReducerProtocol {
    
    @inlinable
    public init() {}
    
    @inlinable
    public func apply(_ action: Action,
                      to state: inout State) {}
    
    
}


public extension Reducers.Native {
    
    @inlinable
    static func nop<State, Action>(stateType: State.Type = State.self) -> NopReducer<State, Action> {
        NopReducer()
    }
    
}
