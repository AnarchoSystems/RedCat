//
//  Projection.swift
//  
//
//  Created by Markus Kasperczyk on 21.10.21.
//


/// Projections of the store's state can be used to focus on certain parts of the state.
/// - Important: This type is not meant to be used for composing the state, but for rearranging its properties in a manner suitable for, e.g., a view.
public protocol Projection {
    
    associatedtype WholeState
    
    init()
    mutating func inject(from whole: WholeState)
    
}


public extension Projection {
    
    typealias Lens<Part> = _Lens<WholeState, Part>
    
    mutating func inject(from whole: WholeState){}
    
    static func project(_ whole: WholeState) -> Self {
        
        var result = Self()
        RedCat.inject(environment: whole, to: result)
        result.inject(from: whole)
        
        return result
        
    }
    
}


public extension DetailServiceProtocol where Detail : Projection {
    
    func extractDetail(from state: Detail.WholeState) -> Detail {
        Detail.project(state)
    }
    
}


public protocol RestrictedAction {
    
    associatedtype BroaderAction
    
    var contextualized : BroaderAction {get}
    
}


public protocol StoreModule {
    
    associatedtype StateToProject
    associatedtype ContextualizedAction
    associatedtype State
    associatedtype Action
    
    func project(_ wholeState: StateToProject) -> State
    func contextualize(_ action: Action) -> ContextualizedAction
    
}


public extension StoreModule where State : Projection {
    
    func project(_ wholeState: State.WholeState) -> State {
        State.project(wholeState)
    }
    
}


public extension StoreModule where Action : RestrictedAction {
    
    func contextualize(_ action: Action) -> Action.BroaderAction {
        action.contextualized
    }
    
}


public extension StoreProtocol {
    
    func map<Module : StoreModule>(_ module: Module) -> MapStore<Self, Module.State, Module.Action>
    where Module.StateToProject == State, Module.ContextualizedAction == Action {
        map(module.project, onAction: module.contextualize)
    }
    
}


#if (os(iOS) && arch(arm64)) || os(macOS) || os(tvOS) || os(watchOS)
#if canImport(SwiftUI)

import SwiftUI

public extension StoreProtocol {
    
    func withViewStore<Module : StoreModule, U>(_ module: Module,
                                                @ViewBuilder completion: (MapStore<Self, Module.State, Module.Action>) -> U) -> U
    where Module.StateToProject == State, Module.ContextualizedAction == Action {
        completion(map(module))
    }
    
}

#endif
#endif
