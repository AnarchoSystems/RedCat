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
        
        for _ in 0..<100 {
        
            let store = Store(initialState: TestState(value: Int.random(in: -100...100)),
                                    reducer: VoidReducer {$0.value += 1},
                                    services: [TestService(detail: \.value)])
            
            for _ in 0..<10 {
                store.send(())
            }
            
        }
        
    }
    
}


fileprivate extension RedCatTests {
    
    struct TestState {
        var value : Int
    }
    
    final class TestService : DetailService<TestState, Int, Void> {
        override func onUpdate(newValue: Int, store: StoreStub<TestState, Void>, environment: Dependencies) {
            XCTAssert(newValue == oldValue + 1)
        }
    }
    
}
