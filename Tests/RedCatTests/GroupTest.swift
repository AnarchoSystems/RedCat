//
//  GroupTest.swift
//  
//
//  Created by Markus Pfeifer on 16.06.21.
//

import XCTest
import RedCat


extension RedCatTests {
    
    func testActionAppend() {
        
        let action = 0.then(0).then(1).then([2, 3, 4])
        
        var state = 0
        
        let r = Reducer {(action: Int, state: inout Int) in state += action}
        
        r.applyAll(action, to: &state)
        
        XCTAssertEqual(state, 10)
        
    }
    
    func testUndoAppend() {
        
        let action = Action.inc(0).then(.inc(0)).then(.inc(1)).then([.inc(2), .inc(3), .inc(4)])
        
        var state = 0
        
        let r = Reducer {(action: Action, state: inout Int) in
            switch action {
            case .inc(let v):
                state += v
            case .dec(let v):
                state -= v
            }
        }
        
        r.applyAll(action.asActionGroup(), to: &state)
        
        XCTAssertEqual(state, 10)
        
        r.applyAll(action.inverted(), to: &state)
        
        XCTAssertEqual(state, 0)
        
    }
    
    func testActionBuilder() {
        
        for value in [true, false] {
            
            let group = ActionGroup<Int> {
                1
                2
                for i in 3...10 {
                    i
                }
                if value {
                    100
                }
                else {
                    200
                }
            }
            
            XCTAssertEqual(Array(group), Array(1...10) + [value ? 100 : 200])
            
        }
        
    }
    
    func testUndoBuilder() {
        
        for value in [true, false] {
            
            let group = UndoGroup<Action> {
                Action.inc(1)
                Action.inc(2)
                for i in 3...10 {
                    Action.inc(i)
                }
                if value {
                    Action.inc(100)
                }
                else {
                    Action.inc(200)
                }
            }
            
            XCTAssertEqual(Array(group), (Array(1...10) + [value ? 100 : 200]).map(Action.inc))
            
        }
    }
    
}

fileprivate enum Action : Undoable, Equatable {
    case inc(Int)
    case dec(Int)
    mutating func invert() {
        switch self {
        case .inc(let v):
            self = .dec(v)
        case .dec(let v):
            self = .inc(v)
        }
    }
}

extension Int : SequentiallyComposable {}
