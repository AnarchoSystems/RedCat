//
//  DetailServiceTest.swift
//  
//
//  Created by Markus Pfeifer on 15.06.21.
//

import XCTest
import RedCat



extension RedCatTests {
    
    func testDetailService() {
        
        for idx in 0..<100 {
            
            let start = Int.random(in: -100...100)
            
            let store = Store(initialState: TestState(value: start),
                              reducer: VoidReducer {if idx % 2 == 0 {$0.value += 1}},
                              services: [TestService()])
            
            for _ in 0..<10 {
                store.send(())
            }
            
            XCTAssertEqual(store.state.value, idx % 2 == 0 ? start + 10 : start)
            
        }
        
    }
    
}


fileprivate extension RedCatTests {
    
    struct TestState {
        var value : Int
    }
    
    final class TestService : DetailService<TestState, Int, Void> {
        func onUpdate(newValue: Int) {
            XCTAssert(newValue == oldValue + 1)
        }
        func extractDetail(from state: RedCatTests.TestState) -> Int {
            state.value
        }
    }
    
}
