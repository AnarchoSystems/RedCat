//
//  Observers.swift
//
//
//  Created by Markus Pfeifer on 15.05.21.
//
import Foundation



public final class Observers {
    
    //faster than reading from dict
    @usableFromInline
    internal var firstObserver : (id: UUID, delegate: StoreDelegate)?
    @usableFromInline
    internal var otherObservers : [UUID : StoreDelegate] = [:]
    
    @usableFromInline
    internal func addObserver<O : StoreDelegate & AnyObject>(_ observer: O) {
        
        if firstObserver == nil {
            firstObserver = (UUID(), observer)
        }
        else {
            otherObservers[UUID()] = WeakStoreDelegate(observer)
        }
        
    }
    
    @usableFromInline
    internal func addObserver<O : StoreDelegate>(_ observer: O) -> StoreUnsubscriber {
        
        let id = UUID()
        if firstObserver == nil {
            firstObserver = (id, observer)
            return StoreUnsubscriber{[weak self] in
                self?.unsubscribeFirstObserver(checkID: id)
            }
        }
        else {
            otherObservers[id] = observer
            return StoreUnsubscriber {[weak self] in
                self?.unsubscribeOtherObserver(checkID: id)
            }
        }
        
    }
    
    @usableFromInline
    internal func unsubscribeFirstObserver(checkID id: UUID) {
        guard self.firstObserver?.id == id else {return}
        self.firstObserver = nil
        if let (id, delegate) = self.otherObservers.first {
            self.otherObservers.removeValue(forKey: id)
            self.firstObserver = (id, delegate)
        }
    }
    
    @usableFromInline
    internal func unsubscribeOtherObserver(checkID id: UUID) {
        if self.firstObserver?.id == id {
            self.firstObserver = nil
            if let (id, delegate) = self.otherObservers.first {
                self.otherObservers.removeValue(forKey: id)
                self.firstObserver = (id, delegate)
            }
        }
        else {
            self.otherObservers.removeValue(forKey: id)
        }
    }
    
    @usableFromInline
    internal func notifyAll() {
        
        if let observer = firstObserver?.delegate {
            if observer.isAlive {
            observer.storeWillChange()
            }
        }
        else {
            if otherObservers.count > 0 {
                Swift.print("RedCat: Implementation invariant broken in Observers.swift: first observer doesn't get special treatment. Please file a bug.")
            }
        }
        
        var invalidIDs : Set<UUID> = []
        
        for (id, observer) in otherObservers {
            if observer.isAlive {
            observer.storeWillChange()
            }
            else {
                invalidIDs.insert(id)
            }
        }
        
        for key in invalidIDs {
            otherObservers.removeValue(forKey: key)
        }
        
        if
            let observer = firstObserver?.delegate,
            !observer.isAlive {
            firstObserver = nil
            if let (id, delegate) = otherObservers.first {
                self.otherObservers.removeValue(forKey: id)
                self.firstObserver = (id, delegate)
            }
        }
        
    }
    
}


public struct StoreUnsubscriber {
    private let unsubscribeAction: () -> Void
    
    public init(_ unsubscribe: @escaping () -> Void) {
        unsubscribeAction = unsubscribe
    }
    
    public func unsubscribe() {
        unsubscribeAction()
    }
}
