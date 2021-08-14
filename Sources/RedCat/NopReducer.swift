//
//  NopReducer.swift
//  
//
//  Created by Markus Pfeifer on 12.05.21.
//

import Foundation


/// A ```NopReducer``` accepts no actions and will do absolutely nothing when it sees one. This is useful in conjunction with ```DispatchReducer```s that return an ```IfReducer```.
public struct NopReducer<State, Action, Response> : ReducerProtocol {
    
    @inlinable
    public init() {}
    
    @inlinable
    public func apply(_ action: Action,
                      to state: inout State) -> Response? {nil}
    
    
}


public extension Reducers.Native {
    
    @inlinable
    static func nop<State, Action, Response>(stateType: State.Type = State.self) -> NopReducer<State, Action, Response> {
        NopReducer()
    }
    
}
