//
//  ListReducer.swift
//  
//
//  Created by Markus Pfeifer on 06.05.21.
//

import Foundation


public extension ErasedReducer {
    
    func handlingLists() -> ListHandling<Self> {
        ListHandling(self)
    }
    
    func handlingActionLists() -> ActionListHandling<Self> {
        ActionListHandling(self)
    }
    
    func handlingUndoLists() -> UndoListHandling<Self> {
        UndoListHandling(self)
    }
    
}


extension ActionProtocol {
    
    @usableFromInline
    func apply<T : ErasedReducer>(to target: inout T.State, using reducer: T, environment: Dependencies) {
        reducer.apply(self, to: &target, environment: environment)
    }
    
}


public struct ListHandling<I : ErasedReducer> : ReducerWrapper {
    
    @usableFromInline
    let wrapped : I
    
    @usableFromInline
    init(_ wrapped: I) {
        self.wrapped = wrapped
    }
    
    @inlinable
    public var body : UndoListHandling<ActionListHandling<I>> {
        wrapped.handlingActionLists().handlingUndoLists()
    }
    
}


public struct ActionListHandling<I : ErasedReducer> : ErasedReducer {
    
    @usableFromInline
    let wrapped : I
    
    @usableFromInline
    init(_ wrapped: I) {self.wrapped = wrapped}
    
    @inlinable
    public func apply<Action : ActionProtocol>(_ action: Action, to state: inout I.State, environment: Dependencies) {
        if let list = action as? ActionGroup {
            for elm in list.values {
                elm.apply(to: &state, using: self, environment: environment)
            }
        }
        else {
            wrapped.apply(action, to: &state, environment: environment)
        }
    }
    
    
    public func acceptsAction<Action : ActionProtocol>(ofType type: Action.Type) -> Bool {
        wrapped.acceptsAction(ofType: type)
    }
    
}


public struct UndoListHandling<I : ErasedReducer> : ErasedReducer {
    
    @usableFromInline
    let wrapped : I
    
    @usableFromInline
    init(_ wrapped: I) {self.wrapped = wrapped}
    
    @inlinable
    public func apply<Action : ActionProtocol>(_ action: Action, to state: inout I.State, environment: Dependencies) {
        if let list = action as? UndoGroup {
            for elm in list.values {
                elm.apply(to: &state, using: self, environment: environment)
            }
        }
        else {
            wrapped.apply(action, to: &state, environment: environment)
        }
    }
    
    public func acceptsAction<Action : ActionProtocol>(ofType type: Action.Type) -> Bool {
        wrapped.acceptsAction(ofType: type)
    }
    
}
