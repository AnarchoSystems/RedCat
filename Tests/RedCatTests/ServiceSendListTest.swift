//
//  ServiceSendListTest.swift
//  
//
//  Created by Markus Pfeifer on 16.06.21.
//

import XCTest
@testable import RedCat


extension RedCatTests {
    
    func testServiceSendList() {
        
        let store = Store(initialState: 38,
                          reducer: VoidReducer {$0 += 1},
                          services: [Service(),
                                     Service()])
        
        XCTAssert(store.state == 42)
        
    }
    
}


fileprivate final class Service : DetailService<Int, Int, Void> {
    func onAppInit() {
        XCTAssert(_oldValue != nil)
        store.send([(), ()])
    }
    func extractDetail(from state: Int) -> Int {
        state
    }
    func onUpdate(newValue: Int) {
        
    }
}
