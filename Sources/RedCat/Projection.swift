//
//  Projection.swift
//  
//
//  Created by Markus Kasperczyk on 21.10.21.
//

import Foundation

/// Projections of the store's state can be used to focus on certain parts of the state.
/// - Important: This type is not meant to be used for composing the state, but for rearranging its properties in a manner suitable for, e.g., a view.
public protocol Projection {
    
    associatedtype WholeState
    
    init()
    mutating func inject(from whole: WholeState)
    
}


public extension Projection {
    
    typealias Lens<Part> = _Lens<WholeState, Part>
    typealias Ask = _Lens<WholeState, WholeState>
    
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

#if compiler(>=5.5) && canImport(_Concurrency)


public extension StoreProtocol {
    
    @MainActor
    func send<Action : RestrictedAction>(_ action: Action) where Action.BroaderAction == Self.Action {
        self.send(action.contextualized)
    }
    
    @MainActor
    func send<Action : RestrictedAction>(_ list: ActionGroup<Action>) where Action.BroaderAction == Self.Action {
        self.send(ActionGroup(values: list.values.map(\.contextualized)))
    }
    
    @available(macOS 10.11, *)
    @MainActor
    func sendWithUndo<Action : RestrictedAction & Undoable>(_ action: Action,
                                                            undoTitle: String? = nil,
                                                            redoTitle: String? = nil,
                                                            undoManager: UndoManager?)
    where Action.BroaderAction == Self.Action {
        self.sendWithUndo(action,
                          undoTitle: undoTitle,
                          redoTitle: redoTitle,
                          undoManager: undoManager,
                          embed: \.contextualized)
    }
    
    @available(macOS 10.11, *)
    @MainActor
    func sendWithUndo<Action : RestrictedAction & Undoable>(_ list: UndoGroup<Action>,
                                                            undoTitle: String? = nil,
                                                            redoTitle: String? = nil,
                                                            undoManager: UndoManager?) where Action.BroaderAction == Self.Action {
        self.sendWithUndo(list,
                          undoTitle: undoTitle,
                          redoTitle: redoTitle,
                          undoManager: undoManager,
                          embed: \.contextualized)
    }
    
}


#else

public extension StoreProtocol {
    
    func send<Action : RestrictedAction>(_ action: Action) where Action.BroaderAction == Self.Action {
        self.send(action.contextualized)
    }
    
    func send<Action : RestrictedAction>(_ list: ActionGroup<Action>) where Action.BroaderAction == Self.Action {
        self.send(ActionGroup(values: list.values.map(\.contextualized)))
    }
    
    @available(macOS 10.11, *)
    func sendWithUndo<Action : RestrictedAction & Undoable>(_ action: Action,
                                                            undoTitle: String? = nil,
                                                            redoTitle: String? = nil,
                                                            undoManager: UndoManager?)
    where Action.BroaderAction == Self.Action {
        self.sendWithUndo(action,
                          undoTitle: undoTitle,
                          redoTitle: redoTitle,
                          undoManager: undoManager,
                          embed: \.contextualized)
    }
    
    @available(macOS 10.11, *)
    func sendWithUndo<Action : RestrictedAction & Undoable>(_ list: UndoGroup<Action>,
                                                            undoTitle: String? = nil,
                                                            redoTitle: String? = nil,
                                                            undoManager: UndoManager?) where Action.BroaderAction == Self.Action {
        self.sendWithUndo(list,
                          undoTitle: undoTitle,
                          redoTitle: redoTitle,
                          undoManager: undoManager,
                          embed: \.contextualized)
    }
    
}

#endif

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


public extension MapStore {
    
    func map<Module : StoreModule>(_ module: Module) -> MapStore<Wrapped, Module.State, Module.Action>
    where Module.StateToProject == State, Module.ContextualizedAction == Action {
        let trafo = self.transform
        let onAction = self.embed
        return wrapped.map({module.project(trafo($0))},
                           onAction: {onAction(module.contextualize($0))})
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
