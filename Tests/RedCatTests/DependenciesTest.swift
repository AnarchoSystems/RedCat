//
//  DependenciesTest.swift
//  
//
//  Created by Markus Pfeifer on 15.06.21.
//

import XCTest
import RedCat


extension RedCatTests {
    
    func testDependencies() {
        
        for value in [true, false] {
            
            let env = Dependencies {
                Bind(\.testFlag, to: value)
                Bind(given: \.testFlag) {flag in
                    if flag {
                        Bind(\.testValue, to: "The answer is 42!")
                    }
                }
            }
            
            XCTAssert(env.testValue == (env.testFlag ? "The answer is 42!" : "Hello, world!"))
            
        }
        
    }
    
    func testDependenciesValueSemantics() {
        
        var env1 = Dependencies()
        let env2 = env1
        env1.testFlag = false
        
        XCTAssert(env2.testFlag)
        XCTAssertFalse(env1.testFlag)
        
    }
    
}


fileprivate enum TestKey : Dependency {
    static let defaultValue = "Hello, world!"
}

fileprivate enum TestFlagKey : Dependency {
    static let defaultValue = true
}


fileprivate extension Dependencies {
    
    var testFlag : Bool {
        get {self[TestFlagKey.self]}
        set {self[TestFlagKey.self] = newValue}
    }
    
    var testValue : String {
        get {self[TestKey.self]}
        set {self[TestKey.self] = newValue}
    }
    
}
