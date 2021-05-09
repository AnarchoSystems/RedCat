//
//  Store.swift
//  
//
//  Created by Markus Pfeifer on 06.05.21.
//

import Foundation

struct AppInit : ActionProtocol{}

public class Store<State> {
    
    public var state : State
    
    let services : [Service<State>]
    let environment : Dependencies
    
    fileprivate init(initialState: State,
                     services: [Service<State>],
                     environment: Dependencies) {
        state = initialState
        self.services = services
        self.environment = environment
        send(AppInit())
    }
    
    public func send<Action : ActionProtocol>(_ action: Action){
        fatalError()
    }
    
    @available(OSX 10.11, *)
    public func sendWithUndo<Action: Undoable>(_ action: Action,
                                               undoTitle: String? = nil,
                                               redoTitle: String? = nil,
                                               undoManager: UndoManager?) {
        send(action)
        undoManager?.registerUndo(withTarget: self){target in
            target.sendWithUndo(action.inverted(),
                                undoTitle: redoTitle,
                                redoTitle: undoTitle,
                                undoManager: undoManager)
        }
        if let undoTitle = undoTitle {
            undoManager?.setActionName(undoTitle)
        }
    }
    
    public static func create<Reducer : DependentReducer>(initialState: Reducer.State,
                                                          reducer: Reducer,
                                                          environment: Dependencies,
                                                          services: [Service<Reducer.State>]) -> Store<State>
    where Reducer.State == State {
        ConcreteStore(initialState: initialState, reducer: reducer, environment: environment, services: services)
    }
    
}


public class ConcreteStore<Reducer : DependentReducer> : Store<Reducer.State> {
    
    let reducer : Reducer
    
    init(initialState: Reducer.State,
         reducer: Reducer,
         environment: Dependencies,
         services: [Service<Reducer.State>]) {
        self.reducer = reducer
        super.init(initialState: initialState, services: services, environment: environment)
    }
    
    public override func send<Action : ActionProtocol>(_ action: Action) {
        for service in services {
            service.beforeUpdate(store: self, action: action, environment: environment)
        }
        reducer.apply(action, to: &state, environment: environment)
        for service in services {
            service.afterUpdate(store: self, action: action, environment: environment)
        }
    }
    
}


#if os(iOS) || os(macOS)
#if canImport(Combine)

@available(OSX 10.15, *)
@available(iOS 13.0, *)
public final class CombineStore<Reducer : DependentReducer> : ConcreteStore<Reducer>, ObservableObject {
    
    public override func send<Action : ActionProtocol>(_ action: Action) {
        objectWillChange.send()
        super.send(action)
    }
    
}

public extension Store {
    
    @available(OSX 10.15, *)
    @available(iOS 13.0, *)
    static func combineStore<Reducer : DependentReducer>(initialState: Reducer.State,
                                                                reducer: Reducer,
                                                                environment: Dependencies,
                                                                services: [Service<Reducer.State>]) -> CombineStore<Reducer>
    where Reducer.State == State {
        CombineStore(initialState: initialState, reducer: reducer, environment: environment, services: services)
    }
}

#endif
#endif


open class Service<State> {
    
    public init(){}
    
    open func beforeUpdate<Action>(store: Store<State>, action: Action, environment: Dependencies) {}
    
    open func afterUpdate<Action>(store: Store<State>, action: Action, environment: Dependencies) {}
    
}

open class DetailService<State, Detail : Equatable> : Service<State> {
    
    @usableFromInline
    let detail : (State) -> Detail
    @usableFromInline
    var oldValue : Detail?
    
    public init(detail: @escaping (State) -> Detail) {self.detail = detail}
    
    @inlinable
    public override func afterUpdate<Action>(store: Store<State>, action: Action, environment: Dependencies) {
        let detail = self.detail(store.state)
        guard detail != oldValue else{return}
        oldValue = detail
        onUpdate(newValue: detail, store: store, environment: environment)
    }
    
    open func onUpdate(newValue: Detail, store: Store<State>, environment: Dependencies) {
        
    }
    
}
