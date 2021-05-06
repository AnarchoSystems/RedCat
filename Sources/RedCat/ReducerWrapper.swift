//
//  ReducerWrapper.swift
//  
//
//  Created by Markus Pfeifer on 06.05.21.
//

import Foundation



public protocol ReducerWrapper : DependentReducer {
    
    associatedtype Body : DependentReducer
    var body : Body{get}
    
}


public extension ReducerWrapper {
    
    func apply<Action : ActionProtocol>(_ action: Action,
                       to state: inout Body.State,
                       environment: Environment) {
        body.apply(action,
                   to: &state,
                   environment: environment)
    }
    
}


public struct Wrap<Reducer : DependentReducer> : ReducerWrapper {
    
    public let body : Reducer
    
    public init(_ body: Reducer) {
        self.body = body
    }
    
    public init(_ build: () -> Reducer) {
        self.body = build()
    }
    
}
