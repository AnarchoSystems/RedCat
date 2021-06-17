//
//  TestMapStore.swift
//  
//
//  Created by Markus Pfeifer on 15.06.21.
//

import XCTest
@testable import RedCat



extension RedCatTests {
    
    func testMapStore() {
        
        let store = Store(initialState: StructState(value: 42),
                                reducer: VoidReducer{$0.value += 1})
        
        let mapped = store.value
        
        var hasRun = false
        
        let unSub = mapped.addObserver {store in hasRun = true; XCTAssert(store.state == 42)} // WILL change, not DID change
        
        XCTAssert(store.objectWillChange.firstObserver != nil)
        
        mapped.send(())
        
        XCTAssert(hasRun)
        
        unSub.unsubscribe()
        
        XCTAssert(store.objectWillChange.firstObserver == nil)
        XCTAssert(mapped.state == 43)
        
        mapped.send([(), ()])
        
        XCTAssert(mapped.state == 45)
        
    }
    
    func testStoreWrapper() {
        
        let service = HasShutDownService()
        
        let store = Store(initialState: 42,
                                reducer: VoidReducer{$0 += 1},
                                services: [service])
        
        let mapped = SimpleStoreWrapper(wrapped: store)
        
        mapped.send(())
        
        XCTAssert(mapped.state == 43)
        
        mapped.send([(), ()])
        
        XCTAssert(mapped.state == 45)
        
        mapped.shutDown()
        
        XCTAssert(service.hasShutdown)
        
    }
    
}


fileprivate extension RedCatTests {
    
    struct StructState {
        var value : Int
    }
    
    struct SimpleStoreWrapper<Base : StoreProtocol> : StoreWrapper {
        let wrapped : Base
        func recovererFromWrapped() -> Recoverer<Base, RedCatTests.SimpleStoreWrapper<Base>> {
            Recoverer {SimpleStoreWrapper(wrapped: $0)}
        }
    }
    
    class HasShutDownService : Service<Int, Void> {
        var hasShutdown = false
        override func _onShutdown() {
            hasShutdown = true
        }
    }
    
}
