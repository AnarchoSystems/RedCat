//
//  ComposedReducerTest.swift
//  
//
//  Created by Markus Pfeifer on 06.05.21.
//

import XCTest
@testable import RedCat


extension RedCatTests {
    
    // basic semantic test of reducers
    func testIncDec() {
        var number = Int.random(in: -100...100)
        var state = TestState(value: number)
        for _ in 0..<100 {
            if Bool.random() {
                incReducer.apply(.inc, to: &state)
                number += 1
            }
            else {
                decReducer.apply(.dec, to: &state)
                number -= 1
            }
            XCTAssertEqual(number, state.value)
        }
    }
    
    // test of basic sequential composition
    func testComposed() {
        var state1 = TestState(value: Int.random(in: -100...100))
        var state2 = state1
        for _ in 0..<100 {
            let oldValue = state1.value
            let incDec = Bool.random()
            let action = IncDec(incDec)
            if incDec {
                incReducer.apply(action, to: &state1)
            }
            else {
                decReducer.apply(action, to: &state1)
            }
            composedReducer.apply(action, to: &state2)
            XCTAssertEqual(state1.value, state2.value)
            XCTAssertEqual(oldValue + (incDec ? 1 : -1), state1.value)
        }
    }
    
    // basic test of
    func testActionList() {
        
        for _ in 0..<10 {
            
            var state = TestState(value: Int.random(in: -100...100))
            let original = state
            
            let list = (0..<100).map {_ in Bool.random()}
            
            let group1 = ActionGroup(list, build: IncDec.init)
            
            composedReducer.applyAll(group1, to: &state)
            
            
            let group2 = UndoGroup(list, build: IncDec.init).inverted()
            
            incDecReducer.applyAll(group2,
                                   to: &state)
            
            XCTAssertEqual(state.value, original.value)
            
        }
        
    }
    
}


fileprivate extension RedCatTests {
    
    var incReducer : IncReducer {
        IncReducer()
    }
    var decReducer : DecReducer {
        DecReducer()
    }
    
    var composedReducer : ComposedReducer<IncReducer, DecReducer> {
        incReducer.compose(with: decReducer)
    }
    
    struct IncReducer : ReducerProtocol {
        
        func apply(_ action: IncDec, to state: inout TestState) {
            guard case .inc = action else {return}
            RedCatTests.apply(action, to: &state.value)
        }
        
    }
    
    struct DecReducer : ReducerProtocol {
        
        func apply(_ action: IncDec, to state: inout TestState) {
            guard case .dec = action else {return}
            RedCatTests.apply(action, to: &state.value)
        }
        
    }
    
    var incDecReducer : ClosureReducer<TestState, IncDec> {
        Reducers.Native.withClosure {RedCatTests.apply($0, to: &$1.value)}
    }
    
}


fileprivate struct TestState {
    
    var value : Int
    
}
