//
//  Store.swift
//  
//
//  Created by Markus Pfeifer on 06.05.21.
//

import Foundation

struct AppInit : ActionProtocol {}

public class Store<State> {
    
    public var state : State {
        fatalError()
    }
    
    internal init() {}
    
    public func send<Action : ActionProtocol>(_ action: Action) {
        fatalError()
    }
    
    func acceptsAction<Action : ActionProtocol>(ofType type: Action.Type) -> Bool {
        fatalError()
    }
    
    @available(OSX 10.11, *)
    public func sendWithUndo<Action: Undoable>(_ action: Action,
                                               undoTitle: String? = nil,
                                               redoTitle: String? = nil,
                                               undoManager: UndoManager?) {
        send(action)
        undoManager?.registerUndo(withTarget: self) {target in
            target.sendWithUndo(action.inverted(),
                                undoTitle: redoTitle,
                                redoTitle: undoTitle,
                                undoManager: undoManager)
        }
        if let undoTitle = undoTitle {
            undoManager?.setActionName(undoTitle)
        }
    }
    
}

final class ConcreteStore<Reducer : ErasedReducer> : Store<Reducer.State> {
    
    @usableFromInline
    override var state : Reducer.State {
        _state
    }
    
    @usableFromInline
    // swiftlint:disable:next identifier_name
    var _state : Reducer.State
    @usableFromInline
    let reducer : Reducer
    
    @usableFromInline
    let services : [Service<Reducer.State>]
    @usableFromInline
    let environment : Dependencies
    
    init(initialState: Reducer.State,
         reducer: Reducer,
         environment: Dependencies,
         services: [Service<Reducer.State>]) {
        self._state = initialState
        self.reducer = reducer
        self.services = services
        self.environment = environment
        super.init()
    }
    
    
    @usableFromInline
    override func send<Action : ActionProtocol>(_ action: Action) {
        for service in services {
            service.beforeUpdate(store: self, action: action, environment: environment)
        }
        reducer.apply(action, to: &_state, environment: environment)
        for service in services {
            service.afterUpdate(store: self, action: action, environment: environment)
        }
    }
    
    @usableFromInline
    override func acceptsAction<Action : ActionProtocol>(ofType type: Action.Type) -> Bool {
        reducer.acceptsAction(ofType: type)
    }
    
}


#if os(iOS) || os(macOS)
#if canImport(Combine)

@available(OSX 10.15, *)
@available(iOS 13.0, *)
public class CombineStore<State> : Store<State>, ObservableObject {
    
}

@available(OSX 10.15, *)
@available(iOS 13.0, *)

// FIXME: Below code is mostly copy+pase from ConcreteReducer
// find a way to reuse ConcreteReducer such that ```send``` is called by services

final class ConcreteCombineStore<Reducer : ErasedReducer> : CombineStore<Reducer.State> {
    
    @usableFromInline
    override var state : Reducer.State {
        _state
    }
    
    @usableFromInline
    // swiftlint:disable:next identifier_name
    var _state : Reducer.State
    @usableFromInline
    let reducer : Reducer
    
    @usableFromInline
    let services : [Service<Reducer.State>]
    @usableFromInline
    let environment : Dependencies
    
    init(initialState: Reducer.State,
         reducer: Reducer,
         environment: Dependencies,
         services: [Service<Reducer.State>]) {
        self._state = initialState
        self.reducer = reducer
        self.services = services
        self.environment = environment
        super.init()
    }
    
    
    @usableFromInline
    override func send<Action : ActionProtocol>(_ action: Action) {
        objectWillChange.send()
        for service in services {
            service.beforeUpdate(store: self, action: action, environment: environment)
        }
        reducer.apply(action, to: &_state, environment: environment)
        for service in services {
            service.afterUpdate(store: self, action: action, environment: environment)
        }
    }
    
    @usableFromInline
    override func acceptsAction<Action : ActionProtocol>(ofType type: Action.Type) -> Bool {
        reducer.acceptsAction(ofType: type)
    }
    
}

#endif
#endif

public extension Store {
    
    static func create<Reducer : ErasedReducer>(initialState: Reducer.State,
                                                reducer: Reducer,
                                                environment: Dependencies,
                                                services: [Service<Reducer.State>]) -> Store<State>
    where Reducer.State == State {
        let result = ConcreteStore(initialState: initialState,
                                   reducer: reducer,
                                   environment: environment,
                                   services: services)
        result.send(AppInit())
        return result
    }
    
    
    #if os(iOS) || os(macOS)
    #if canImport(Combine)
    
    @available(OSX 10.15, *)
    @available(iOS 13.0, *)
    static func combineStore<Reducer : ErasedReducer>(
        initialState: Reducer.State,
        reducer: Reducer,
        environment: Dependencies,
        services: [Service<Reducer.State>]
    ) -> CombineStore<Reducer.State>
    where Reducer.State == State {
        let result = ConcreteCombineStore(initialState: initialState,
                                          reducer: reducer,
                                          environment: environment,
                                          services: services)
        result.send(AppInit())
        return result
    }
    
    #endif
    #endif
    
}



open class Service<State> {
    
    public init() {}
    
    open func beforeUpdate<Action : ActionProtocol>(store: Store<State>, action: Action, environment: Dependencies) {}
    
    open func afterUpdate<Action : ActionProtocol>(store: Store<State>, action: Action, environment: Dependencies) {}
    
}

open class DetailService<State, Detail : Equatable> : Service<State> {
    
    @usableFromInline
    let detail : (State) -> Detail
    @usableFromInline
    var oldValue : Detail?
    
    public init(detail: @escaping (State) -> Detail) {self.detail = detail}
    
    @inlinable
    public override func afterUpdate<Action : ActionProtocol>(store: Store<State>,
                                                              action: Action,
                                                              environment: Dependencies) {
        let detail = self.detail(store.state)
        guard detail != oldValue else {return}
        oldValue = detail
        onUpdate(newValue: detail, store: store, environment: environment)
    }
    
    open func onUpdate(newValue: Detail, store: Store<State>, environment: Dependencies) {
        
    }
    
}
