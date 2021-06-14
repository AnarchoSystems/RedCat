//
//  NativeDepsTest.swift
//  
//
//  Created by Markus Pfeifer on 15.06.21.
//

import XCTest
import RedCat


extension RedCatTests {
    
    func testNativeDependencies() {
        
        let natives = Dependencies().nativeValues
        
        #if DEBUG
        XCTAssert(natives.debug)
        #else
        XCTAssertFalse(natives.debug)
        #endif
        
        #if targetEnvironment(simulator)
        XCTAssert(natives.isSimulator)
        #else
        XCTAssertFalse(natives.isSimulator)
        #endif
    }
    
}
