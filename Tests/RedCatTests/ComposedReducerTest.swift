//
//  ComposedReducerTest.swift
//  
//
//  Created by Markus Pfeifer on 06.05.21.
//

import XCTest
import RedCat


extension RedCatTests {
    
    func testIncDec() {
        var number = Int.random(in: -100...100)
        var state = TestState(value: number)
        for _ in 0..<100 {
            if Bool.random() {
                incReducer.apply(Inc(value: \TestState.value), to: &state)
                number += 1
            }
            else {
                decReducer.apply(Dec(value: \TestState.value), to: &state)
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
            let action : ActionProtocol = incOrDec(incDec)
            if incDec {
                incReducer.applyDynamic(action, to: &state1)
            }
            else {
                decReducer.applyDynamic(action, to: &state1)
            }
            composedReducer.applyDynamic(action, to: &state2)
            XCTAssertEqual(state1.value, state2.value)
            XCTAssertEqual(oldValue + (incDec ? 1 : -1), state1.value)
        }
    }
    
    func testActionList() {
        
        for _ in 0..<10 {
            
            var state1 = TestState(value: Int.random(in: -100...100))
            var state2 = state1
            
            let list = (0..<100).map {_ in Bool.random()}
            
            for incDec in list {
                
                composedReducer.applyDynamic(incOrDec(incDec), to: &state1)
                
            }
            
            composedReducer.handlingActionLists().applyDynamic(ActionGroup(list, build: incOrDec), to: &state2)
            
            XCTAssertEqual(state1.value, state2.value)
            
        }
        
    }
    
}


fileprivate extension RedCatTests {
    
    func incOrDec(_ inc: Bool) -> ActionProtocol {
        inc ? Inc(value: \TestState.value) : Dec(value: \TestState.value)
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
    
}


fileprivate struct TestState {
    
    var value : Int
    
}
