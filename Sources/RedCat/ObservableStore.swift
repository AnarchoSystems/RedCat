//
//  ObservableStore.swift
//  
//
//  Created by Markus Pfeifer on 15.05.21.
//

import Foundation

public extension StoreProtocol {
    
    /// Tells the receiver that the observer wants to be notified about dispatch cycles.
    @inlinable
    func addObserver<S: StoreDelegate>(_ observer: S) -> StoreUnsubscriber {
        objectWillChange.addObserver(observer)
    }
    
    /// Tells the receiver that the observer wants to be notified about dispatch cycles.
    @inlinable
    func addObserver<S : StoreDelegate & AnyObject>(_ observer: S) {
        objectWillChange.addObserver(observer)
    }
    
}

extension StoreProtocol {
    
    /// Tells the receiver that the observer wants to be notified about dispatch cycles.
    @inlinable
    public func addObserver(_ willChange: @escaping (Self) -> Void) -> StoreUnsubscriber {
        let recoverer = getRecoverer()
        return addObserver(
            ClosureStoreDelegate({[weak rootStore] in
                guard let rootStore = rootStore else { return }
                willChange(recoverer.recover(from: rootStore))
            })
        )
    }
    
    /// Tells the receiver that the observer wants to be notified about dispatch cycles.
    @inlinable
    public func addObserver(_ willChange: @escaping () -> Void) -> StoreUnsubscriber {
        addObserver(ClosureStoreDelegate(willChange))
    }
    
}
