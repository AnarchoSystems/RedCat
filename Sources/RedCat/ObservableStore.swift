//
//  ObservableStore.swift
//  
//
//  Created by Markus Pfeifer on 15.05.21.
//

import Foundation

public protocol __ObservableStoreProtocol: __StoreProtocol {
    /// Tells the receiver that the observer wants to be notified about dispatch cycles.
    func addObserver<S: StoreDelegate>(_ observer: S) -> StoreUnsubscriber
    /// Tells the receiver that the observer wants to be notified about dispatch cycles.
    func addObserver<S : StoreDelegate & AnyObject>(_ observer: S)
}

extension __ObservableStoreProtocol {
    
    /// Tells the receiver that the observer wants to be notified about dispatch cycles.
    @inlinable
    public func addObserver(_ didChange: @escaping (Self) -> Void) -> StoreUnsubscriber {
        addObserver(
            ClosureStoreDelegate({[weak self] in
                guard let self = self else { return }
                didChange(self)
            })
        )
    }
    
    /// Tells the receiver that the observer wants to be notified about dispatch cycles.
    @inlinable
    public func addObserver(_ didChange: @escaping () -> Void) -> StoreUnsubscriber {
        addObserver(ClosureStoreDelegate(didChange))
    }
    
}

/// An ```ObservableStore``` exposes an ```addObserver``` method so other parts can be notified of dispatch cycles (in absence of ```Combine```).
public class ObservableStore<State> : Store<State>, __ObservableStoreProtocol {
    
    public let objectWillChange = StoreObjectWillChangePublisher()
    
    /// Tells the receiver that the observer wants to be notified about dispatch cycles.
    /// - Parameters:
    ///     - observer: The object to be notified.
    
    @inlinable
    public func addObserver<S: StoreDelegate>(_ observer: S) -> StoreUnsubscriber {
        objectWillChange.addObserver(observer)
    }
    
    @inlinable
    public func addObserver<S : StoreDelegate & AnyObject>(_ observer: S) {
        objectWillChange.addObserver(observer)
    }
    
}
