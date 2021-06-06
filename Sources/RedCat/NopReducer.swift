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
    
    @inlinable
    public func apply<Action : ActionProtocol>(_ action: Action,
                                               to state: inout State,
                                               environment: Dependencies) {}
    
    @inlinable
    public func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
        false
    }
    
}
