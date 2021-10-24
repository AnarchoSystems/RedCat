//
//  StoreWrapper.swift
//  
//
//  Created by Markus Pfeifer on 15.06.21.
//

import Foundation


/// ```StoreWrapper``` is the ideal protocol to implement decorators for stores. All you need to provide is a ```wrapped``` property and a way to recover the current store from this ```wrapped``` store if your store gets deleted. It is a good idea to use value types here.
/// Notice that the two ```send``` functions are type constrained when conforming.
public protocol StoreWrapper : StoreProtocol {
    
    associatedtype Wrapped : StoreProtocol
    var wrapped : Wrapped {get}
    func recovererFromWrapped() -> Recoverer<Wrapped, Self>
    
}

public extension StoreWrapper {
    
    @inlinable
    var rootStore : Wrapped.RootStore {wrapped.rootStore}
    
    @inlinable
    func getRecoverer() -> Recoverer<Wrapped.RootStore, Self> {
        let p1 = wrapped.getRecoverer()
        let p2 = recovererFromWrapped()
        return Recoverer{p2.recover(from: p1.recover(from: $0))}
    }
    
}

public extension StoreWrapper {
    
    var state: Wrapped.State { wrapped.state }
    
}

public extension StoreWrapper {
    
    func shutDown() {
        wrapped.shutDown()
    }
    
    var objectWillChange: StoreObjectWillChangePublisher {
        rootStore.objectWillChange
    }
    
}

public extension StoreWrapper {
    
    
    func send(_ action: Wrapped.Action) {
        wrapped.send(action)
    }
    
    func send(_ list: ActionGroup<Wrapped.Action>) {
        wrapped.send(list)
    }
    
}
