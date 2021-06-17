//
//  ShutdownWarnTest.swift
//  
//
//  Created by Markus Pfeifer on 15.06.21.
//

import XCTest
@testable import RedCat


extension RedCatTests {
    
    func testShutdownWarning() {
        
        let store = Store(initialState: (), erasing: VoidReducer {_ in })
        
        store.send(())
        
        XCTAssert(!store.environment.hasStoredValue(for: InternalFlags.self))
        
        store.shutDown()
        
        XCTAssert(!store.environment.hasStoredValue(for: InternalFlags.self))
        
        store.send(())
        
        XCTAssert(store.environment.hasStoredValue(for: InternalFlags.self))
        
    }
    
    func testOtherShutdownWarning() {
        
        let store = Store(initialState: (), erasing: VoidReducer {_ in })
        
        store.send(())
        
        XCTAssert(!store.environment.hasStoredValue(for: InternalFlags.self))
        
        store.shutDown()
        
        XCTAssert(!store.environment.hasStoredValue(for: InternalFlags.self))
        
        store.shutDown()
        
        XCTAssert(store.environment.hasStoredValue(for: InternalFlags.self))
        
    }
    
}
