//
//  ServiceTest.swift
//  
//
//  Created by Markus Pfeifer on 14.06.21.
//

import XCTest
import RedCat


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
        case before1
        case before2
        case after1
        case after2
        case shutdown
    }
    
    class OuterService : Service<[Action], Action> {
        var beforeCalled = false
        var afterCalled = false
        override func onAppInit() {
            store.send(.appInit)
        }
        override func beforeUpdate(action: RedCatTests.Action) {
            if !beforeCalled {
                beforeCalled = true
                store.send(.before1)
            }
        }
        override func afterUpdate(action: RedCatTests.Action) {
            if !afterCalled {
                afterCalled = true
                store.send(.after2)
            }
        }
        override func onShutdown() {
            store.send(.shutdown)
        }
    }
    
    class InnerService : Service<[Action], Action> {
        var beforeCalled = false
        var afterCalled = false
        override func beforeUpdate(action: RedCatTests.Action) {
            if !beforeCalled {
                beforeCalled = true
                store.send(.before2)
            }
        }
        override func afterUpdate(action: RedCatTests.Action) {
            if !afterCalled {
                afterCalled = true
                store.send(.after1)
            }
        }
    }
    
}
