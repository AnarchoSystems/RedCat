//
//  CasePathExtensionTests.swift
//  
//
//  Created by Markus Pfeifer on 16.06.21.
//

import XCTest
import RedCat
import CasePaths

extension RedCatTests {
    
    func testCasePathModify() {
        
        for _ in 0..<1000 {
            
            var maybeInt : Int? = nil
            var maybeInt2 = maybeInt
            var maybeInt3 = maybeInt2
            
            let defaultValue = Int.random(in: -1000...1000)
            
            (/Optional.some).mutate(&maybeInt, default: defaultValue, closure: {_ in XCTFail()})
            maybeInt2.modify(default: defaultValue, {_ in XCTFail()})
            maybeInt3 = defaultValue
            
            XCTAssert(maybeInt == maybeInt2)
            XCTAssert(maybeInt2 == maybeInt3)
            
        }
        
    }
    
}
