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

public struct ListHandling<I : ErasedReducer> : ReducerWrapper {
    
    @usableFromInline
    let wrapped : I
    
    @inlinable
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
    
    @inlinable
    init(_ wrapped: I) {self.wrapped = wrapped}
    
    @inline(__always)
    public func apply<Action : ActionProtocol>(_ action: Action, to state: inout I.State, environment: Dependencies) {
        
        guard var list = action as? ActionGroup else {
            return wrapped.apply(action, to: &state, environment: environment)
        }
        
        list.unroll()
        
        for elm in list.values {
            wrapped.applyDynamic(elm, to: &state, environment: environment)
        }
        
    }
    
    @inline(__always)
    public func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
        wrapped.acceptsAction(action) || action is ActionGroup
    }
    
}


public struct UndoListHandling<I : ErasedReducer> : ErasedReducer {
    
    @usableFromInline
    let wrapped : I
    
    @inlinable
    init(_ wrapped: I) {self.wrapped = wrapped}
    
    @inline(__always)
    public func apply<Action : ActionProtocol>(_ action: Action, to state: inout I.State, environment: Dependencies) {
        
        guard var list = action as? UndoGroup else {
            return wrapped.apply(action, to: &state, environment: environment)
        }
        
        list.unroll()
        
        for elm in list.values {
            wrapped.applyDynamic(elm, to: &state, environment: environment)
        }
        
    }
    
    @inline(__always)
    public func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
        wrapped.acceptsAction(action) || action is UndoGroup
    }
    
}
