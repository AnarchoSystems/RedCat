//
//  ComposedReducerTest.swift
//  
//
//  Created by Markus Pfeifer on 06.05.21.
//

import XCTest
@testable import RedCat


extension RedCatTests {
    
    func testIncDec() {
        var number = Int.random(in: -100...100)
        var state = TestState(value: number)
        for _ in 0..<100 {
            if Bool.random() {
                incReducer.apply(.inc(value: \TestState.value), to: &state)
                number += 1
            }
            else {
                decReducer.apply(.dec(value: \TestState.value), to: &state)
                number -= 1
            }
            XCTAssertEqual(number, state.value)
        }
    }
    
    func testComposed() {
        var state1 = TestState(value: Int.random(in: -100...100))
        var state2 = state1
        for _ in 0..<100 {
            let oldValue = state1.value
            let incDec = Bool.random()
            let action = incOrDecUndoable(incDec)
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
    
    func testActionList() {
        
        for _ in 0..<10 {
            
            var state = TestState(value: Int.random(in: -100...100))
            let original = state
            
            let list = (0..<100).map {_ in Bool.random()}
            
            for incDec in list {
                
                composedReducer.apply(incOrDecUndoable(incDec), to: &state)
                
            }
            
            let group2 = UndoGroup(list,
                                   build: incOrDecUndoable).inverted()
            
            for action in group2 {
            
                incDecReducer.apply(action,
                                    to: &state)
            
            }
            
            XCTAssertEqual(state.value, original.value)
            
        }
        
    }
    
}


fileprivate extension RedCatTests {
    
    
    func incOrDecUndoable(_ inc: Bool) -> IncDec<TestState> {
        inc ? .inc(value: \TestState.value) : .dec(value: \TestState.value)
    }
    
    var incReducer : TestReducers.IncReducer<TestState> {
        TestReducers.inc()
    }
    var decReducer : TestReducers.DecReducer<TestState> {
        TestReducers.dec()
    }
    
    var composedReducer : ComposedReducer<TestReducers.IncReducer<TestState>, TestReducers.DecReducer<TestState>> {
        incReducer.compose(with: decReducer)
    }
    
    var incDecReducer : ClosureReducer<TestState, IncDec<TestState>> {
        ClosureReducer {action, state in
            switch action.kind {
            case .inc:
                state[keyPath: action.value] += 1
            case .dec:
                state[keyPath: action.value] -= 1
            }
        }
    }
    
}


fileprivate struct TestState {
    
    var value : Int
    
}
