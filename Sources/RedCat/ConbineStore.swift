//
//  CombineStore.swift
//  
//
//  Created by Markus Pfeifer on 15.05.21.
//

import Foundation


#if os(iOS) || os(macOS)
#if canImport(Combine)

/// A ```CombineStore``` is an ```ObservableObject``` in ```Combine```'s sense. For every dispatch cycle, ```objectWillChange``` will be notified.
@available(OSX 10.15, *)
@available(iOS 13.0, *)
public class CombineStore<State> : Store<State>, ObservableObject {}

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
        concreteStore.addObserver(self)
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
