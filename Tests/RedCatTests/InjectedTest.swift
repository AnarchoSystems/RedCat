//
//  InjectedTest.swift
//  
//
//  Created by Markus Pfeifer on 17.06.21.
//

import XCTest
import RedCat


extension RedCatTests {
    
    func testInjected() {
        
        let service = TestService()
        let store = Store(initialState: (),
                          reducer: VoidReducer {_ in },
                          services: [service])
        
        store.send(())
        
        store.shutDown()
        
        XCTAssert(service.tested.allSatisfy{$0})
        
    }
    
}


fileprivate struct TestDep : Dependency {
    static var defaultValue = 42
}

fileprivate extension Dependencies {
    var testValue : Int {
        self[TestDep.self]
    }
}

fileprivate final class TestService : Service<Void, Void> {
    
    @Injected(\.testValue) var value
    var tested = [false, false, false, false]
    
    override func onAppInit() {
        XCTAssert(value == 42)
        tested[0] = true
    }
    
    override func beforeUpdate(action: Void) {
        XCTAssert(value == 42)
        tested[1] = true
    }
    
    override func afterUpdate(action: Void) {
        XCTAssert(value == 42)
        tested[2] = true
    }
    
    override func onShutdown() {
        XCTAssert(value == 42)
        tested[3] = true
    }
    
}
