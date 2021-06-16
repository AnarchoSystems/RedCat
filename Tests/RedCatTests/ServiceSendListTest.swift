//
//  ServiceSendListTest.swift
//  
//
//  Created by Markus Pfeifer on 16.06.21.
//

import XCTest
import RedCat


extension RedCatTests {
    
    func testServiceSendList() {
        
        let store = Store(initialState: 40,
                          reducer: VoidReducer {$0 += 1},
                          services: [Service()])
        
        XCTAssert(store.state == 42)
        
    }
    
}


fileprivate final class Service : RedCat.Service<Int, Void> {
    override func onAppInit(store: StoreStub<Int, Void>, environment: Dependencies) {
        store.send([(), ()])
    }
}
