//
//  ServiceTest.swift
//  
//
//  Created by Markus Pfeifer on 14.06.21.
//

import XCTest
@testable import RedCat


extension RedCatTests {
    
    func testStoreEventOrder() {
        
        let store = Store(initialState: [Action](),
                          reducer: Reducer{($1.append($0))},
                          services: [OuterService(), InnerService()])
        
        store.shutDown()
        
        XCTAssert(Action.allCases.count == store.state.count)
        
        for (expected, actual) in zip(Action.allCases, store.state) {
            XCTAssertEqual(expected, actual)
        }
        
    }
    
}


fileprivate extension RedCatTests {
    
    enum Action : Equatable, CaseIterable {
        case appInit
        case after1
        case after2
        case shutdown
    }
    
    class OuterService : Service<[Action], Action> {
        var beforeCalled = false
        var afterCalled = false
        func _onAppInit() {
            store.send(.appInit)
        }
        
        func _onUpdate() {
            if !afterCalled {
                afterCalled = true
                store.send(.after1)
            }
        }
        func onShutdown() {
            store.send(.shutdown)
        }
    }
    
    class InnerService : Service<[Action], Action> {
        func _onAppInit() {}
        func onShutdown() {}
        var beforeCalled = false
        var afterCalled = false
        func _onUpdate() {
            if !afterCalled {
                afterCalled = true
                store.send(.after2)
            }
        }
    }
    
}
