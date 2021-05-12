//
//  ClassReducer.swift
//  
//
//  Created by Markus Pfeifer on 06.05.21.
//

import Foundation


public protocol ErasedClassReducer : ErasedReducer where State : AnyObject {
    
    func apply<Action : ActionProtocol>(_ action: Action,
                                        to state: State,
                                        environment: Dependencies)
    
}


public extension ErasedClassReducer {
    
    func apply<Action : ActionProtocol>(_ action: Action,
                                        to state: inout State,
                                        environment: Dependencies) {
        apply(action, to: state, environment: environment)
    }
    
}


public protocol DependentClassReducer : ErasedClassReducer {
    
    associatedtype Action : ActionProtocol
    func apply(_ action: Action,
               to state: State,
               environment: Dependencies)
    
}


public extension DependentClassReducer {
    
    func apply<Action : ActionProtocol>(_ action: Action,
                                        to state: State,
                                        environment: Dependencies) {
        guard let action = action as? Self.Action else {return}
        apply(action, to: state, environment: environment)
    }
    
    func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
        action is Self.Action
    }
    
}


public protocol ClassReducer : DependentClassReducer {
    
    func apply(_ action: Action,
               to state: State)
    
}


public extension ClassReducer {
    
    func apply<Action : ActionProtocol>(_ action: Action,
                                        to state: State,
                                        environment: Dependencies) {
        guard let action = action as? Self.Action else {return}
        apply(action, to: state)
    }
    
}


public struct RefReducer<State : AnyObject, Action : ActionProtocol> : DependentClassReducer {
    
    @usableFromInline
    let closure : (Action, State, Dependencies) -> Void
    
    @inlinable
    public init(_ closure: @escaping (Action, State, Dependencies) -> Void) {
        self.closure = closure
    }
    
    @inlinable
    public init(_ closure: @escaping (Action, State) -> Void) {
        self.closure = {action, state, _ in closure(action, state)}
    }
    
    @inlinable
    public func apply(_ action: Action, to state: State, environment: Dependencies) {
        closure(action, state, environment)
    }
    
}
