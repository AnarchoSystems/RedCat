//
//  NopReducer.swift
//  
//
//  Created by Markus Pfeifer on 12.05.21.
//

import Foundation



public struct NopReducer<State> : ErasedReducer {
    
    @inlinable
    public init() {}
    
    @inline(__always)
    public func apply<Action : ActionProtocol>(_ action: Action,
                                               to state: inout State,
                                               environment: Dependencies) {}
    
    @inline(__always)
    public func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
        false
    }
    
}
