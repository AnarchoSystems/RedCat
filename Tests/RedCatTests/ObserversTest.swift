//
//  ObserversTest.swift
//  
//
//  Created by Markus Pfeifer on 15.06.21.
//

import XCTest
@testable import RedCat


extension RedCatTests {
    
    func testObservers() {
        
        var s1 : ExplicitObserver? = ExplicitObserver()
        var s2 : ImplicitObserver? = ImplicitObserver()
        var s3 : ExplicitObserver? = ExplicitObserver()
        var s4 : ImplicitObserver? = ImplicitObserver()
        var s5 : ExplicitObserver? = ExplicitObserver()
        var s6 : ImplicitObserver? = ImplicitObserver()
        
        let store = Store.create(initialState: (), reducer: VoidReducer{_ in })
        
        s1!.unsubscriber = store.addObserver(s1!)
        store.addObserver(s2!)
        s3!.unsubscriber = store.addObserver(s3!)
        store.addObserver(s4!)
        s5!.unsubscriber = store.addObserver(s5!)
        store.addObserver(s6!)
        
        XCTAssert(store.objectWillChange.firstObserver != nil && store.objectWillChange.otherObservers.count == 5)
        
        s5 = nil
        
        XCTAssert(store.objectWillChange.firstObserver != nil && store.objectWillChange.otherObservers.count == 4)
        
        s6 = nil
        
        XCTAssert(store.objectWillChange.firstObserver != nil && store.objectWillChange.otherObservers.count == 4)
        
        store.send(())
        
        XCTAssert(store.objectWillChange.firstObserver != nil && store.objectWillChange.otherObservers.count == 3)
        
        s1 = nil
        
        XCTAssert(store.objectWillChange.firstObserver != nil && store.objectWillChange.otherObservers.count == 2)
        
        s2 = nil
        
        XCTAssert(store.objectWillChange.firstObserver != nil && store.objectWillChange.otherObservers.count == 2)
        
        store.send(())
        
        XCTAssert(store.objectWillChange.firstObserver != nil && store.objectWillChange.otherObservers.count == 1)
        
        s3 = nil
        
        XCTAssert(store.objectWillChange.firstObserver != nil && store.objectWillChange.otherObservers.isEmpty)
        
        s4 = nil
        store.send(())
        
        XCTAssert(store.objectWillChange.firstObserver == nil)
        
    }
    
    func testClosureObservers() {
        
        let store = Store.create(initialState: false, reducer: VoidReducer{$0 = true})
        
        var called = false
        
        let u1 = store.addObserver{called = true}
        let u2 = store.addObserver{store in XCTAssertFalse(store.state)} // WILL change, not DID change 
        
        store.send(())
        
        XCTAssert(called)
        
        u1.unsubscribe()
        u2.unsubscribe()
        
        XCTAssert(store.objectWillChange.firstObserver == nil && store.objectWillChange.otherObservers.isEmpty)
        
    }
    
}

fileprivate extension RedCatTests {
    
    class ExplicitObserver : StoreDelegate {
        var unsubscriber : StoreUnsubscriber?
        func storeWillChange() {}
        deinit {
            unsubscriber?.unsubscribe()
        }
    }
    class ImplicitObserver : StoreDelegate {
        func storeWillChange() {}
    }
    
}
