//
//  Observers.swift
//  
//
//  Created by Markus Pfeifer on 15.05.21.
//

import Foundation



@usableFromInline
class Observers {
    
    //faster than reading from dict
    private weak var firstObserver : StoreDelegate?
    private var otherObservers : [UUID : WeakDelegate] = [:]
    
    @usableFromInline
    func addObserver(_ observer: StoreDelegate) {
        
        if firstObserver == nil {
            firstObserver = observer
        }
        else {
            otherObservers[UUID()] = WeakDelegate(delegate: observer)
        }
    }
    
    @usableFromInline
    func notifyAll() {
        
        firstObserver?.storeWillChange()
        
        for observer in otherObservers.values {
            observer.delegate?.storeWillChange()
        }
        
        let invalidObservers = otherObservers.compactMap{key, value in
            value.delegate == nil ? key : nil
        }
        
        for key in invalidObservers {
            otherObservers.removeValue(forKey: key)
        }
        
        if
            firstObserver == nil,
            let (key, value) = otherObservers.first {
            otherObservers.removeValue(forKey: key)
            firstObserver = value.delegate
        }
        
    }
    
}


private extension Observers {
    
    struct WeakDelegate {
        weak var delegate : StoreDelegate?
    }
    
}
