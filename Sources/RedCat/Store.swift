//
//  Store.swift
//  
//
//  Created by Markus Pfeifer on 06.05.21.
//

import Foundation

public struct AppInit : ActionProtocol {}
public struct AppDeinit : ActionProtocol {}

public class Store<State> {
    
    public var state : State {
        fatalError()
    }
    
    // prevent external initialization
    // makes external subclasses uninitializable
    internal init() {
        send(AppInit())
    }
    
    public func shutDown() {
        send(AppDeinit())
    }
    
    public func send<Action : ActionProtocol>(_ action: Action) {
        fatalError()
    }
    
    func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
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

public protocol StoreDelegate : AnyObject {
    func storeWillChange()
}

public class DelegateStore<State> : Store<State> {
    weak var delegate : StoreDelegate?
    fileprivate override init() {}
}

final class ConcreteStore<Reducer : ErasedReducer> : DelegateStore<Reducer.State> {
    
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
    
    var enqueuedActions = [ActionProtocol]()
    
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
        
        delegate?.storeWillChange()
        enqueuedActions.append(action)
        
        guard enqueuedActions.count == 1 else {
            // All calls to this method are assumed to happen on
            // main dispatch queue - a serial queue.
            // Therefore, if more than one action is in the queue,
            // the action must have been enqueued by the below while loop
            return
        }
        
        var idx = 0
        
        while idx < enqueuedActions.count {
            
            let action = enqueuedActions[idx]
            
            for service in services {
                action.beforeUpdate(service: service, store: self, environment: environment)
            }
            reducer.applyDynamic(action, to: &_state, environment: environment)
            for service in services {
                action.afterUpdate(service: service, store: self, environment: environment)
            }
            
            idx += 1
            
        }
        
        enqueuedActions = []
        
    }
    
    @usableFromInline
    override func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
        reducer.acceptsAction(action)
    }
    
}


#if os(iOS) || os(macOS)
#if canImport(Combine)

@available(OSX 10.15, *)
@available(iOS 13.0, *)
public class CombineStore<State> : Store<State>, ObservableObject {
    fileprivate override init() {}
}

@available(OSX 10.15, *)
@available(iOS 13.0, *)

final class ConcreteCombineStore<Reducer : ErasedReducer> : CombineStore<Reducer.State>, StoreDelegate {
    
    @usableFromInline
    override var state : Reducer.State {
        concreteStore.state
    }
    
    @usableFromInline
    let concreteStore : ConcreteStore<Reducer>
    
    init(initialState: Reducer.State,
         reducer: Reducer,
         environment: Dependencies,
         services: [Service<Reducer.State>]) {
        concreteStore = ConcreteStore(initialState: initialState,
                                      reducer: reducer,
                                      environment: environment,
                                      services: services)
        super.init()
        concreteStore.delegate = self
    }
    
    
    @usableFromInline
    override func send<Action : ActionProtocol>(_ action: Action) {
        concreteStore.send(action)
    }
    
    @usableFromInline
    override func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
        concreteStore.acceptsAction(action)
    }
    
    @usableFromInline
    func storeWillChange() {
        objectWillChange.send()
    }
    
}

#endif
#endif

public extension Store {
    
    static func create<Reducer : ErasedReducer>(initialState: Reducer.State,
                                                reducer: Reducer,
                                                environment: Dependencies,
                                                services: [Service<Reducer.State>]) -> DelegateStore<State>
    where Reducer.State == State {
        let result = ConcreteStore(initialState: initialState,
                                   reducer: reducer,
                                   environment: environment,
                                   services: services)
        return result
    }
    
    static func create<Reducer : ErasedReducer>(reducer: Reducer,
                                                environment: Dependencies,
                                                services: [Service<Reducer.State>],
                                                configure: (Dependencies) -> State) -> DelegateStore<State>
    where Reducer.State == State {
        let result = ConcreteStore(initialState: configure(environment),
                                   reducer: reducer,
                                   environment: environment,
                                   services: services)
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
        return result
    }
    
    
    @available(OSX 10.15, *)
    @available(iOS 13.0, *)
    static func combineStore<Reducer : ErasedReducer>(
        reducer: Reducer,
        environment: Dependencies,
        services: [Service<Reducer.State>],
        configure: (Dependencies) -> State
    ) -> CombineStore<Reducer.State>
    where Reducer.State == State {
        let result = ConcreteCombineStore(initialState: configure(environment),
                                          reducer: reducer,
                                          environment: environment,
                                          services: services)
        return result
    }
    
    #endif
    #endif
    
}
