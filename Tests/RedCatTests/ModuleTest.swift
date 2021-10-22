//
//  ModuleTest.swift
//  
//
//  Created by Markus Kasperczyk on 22.10.21.
//

import XCTest
import RedCat



extension RedCatTests {
    
    
    func testProjection() {
        
        let whole = StateToProject()
        let bar = TestProjection.project(whole)
        
        XCTAssert(bar.sum == 1337 + 42)
        
    }
    
    func testModule() {
        
        let store = Store(initialState: StateToProject(),
                          reducer: IncDecReducer())
        
        let moduleStore = store.map(TestModule())
        
        XCTAssert(moduleStore.state.sum == 1337 + 42)
        
        store.send(.dec)
        
        XCTAssert(moduleStore.state.sum == 1337 + 42 - 1)
        
        moduleStore.send(Inc())
        
        XCTAssert(store.state.foo + store.state.bar == 1337 + 42)
        
    }
    
    fileprivate struct StateToProject {
        
        var foo = 42
        var bar = 1337
        
    }
    
    fileprivate struct TestProjection : Projection {
        
        typealias WholeState = StateToProject
        
        @Lens(\.foo) var foo
        var sum = 0
        
        mutating func inject(from whole: StateToProject) {
            sum = foo + whole.bar
        }
        
    }
    
    
    fileprivate struct Inc : RestrictedAction {
        
        var contextualized : IncDec {
            .inc
        }
        
    }
    
    
    fileprivate struct IncDecReducer : ReducerProtocol {
        
        func apply(_ action: IncDec, to state: inout StateToProject) {
            switch action {
            case .inc:
                state.bar += 1
            case .dec:
                state.bar -= 1
            }
        }
        
    }
    
    
    fileprivate struct TestModule : StoreModule {
        
        typealias State = TestProjection
        typealias Action = Inc
        
    }
    
}
