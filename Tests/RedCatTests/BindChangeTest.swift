//
//  BindChangeTest.swift
//  
//
//  Created by Markus Pfeifer on 15.06.21.
//

import XCTest
import RedCat
import CasePaths


extension RedCatTests {
    
    func testBindChange() {
        
        for _ in 0..<100 {
            
            var state1 = StructState(value: .random(in: -100...100))
            var state2 = EnumState.value(state1.value)
            
            let r1 = Reducers.Native.bind(\StructState.value, to: IntChange.self)
            let r2 = Reducers.Native.bind(/EnumState.value, to: IntChange.self)
            
            var change = IntChange(oldValue: state1.value,
                                   newValue: .random(in: -100...100))
            
            r1.apply(change, to: &state1)
            r2.apply(change, to: &state2)
            
            XCTAssert(state1.value == change.newValue)
            XCTAssert(state2.value == state1.value)
            
            change = change.inverted()
            
            r1.apply(change, to: &state1)
            r2.apply(change, to: &state2)
            
            XCTAssert(state1.value == change.newValue)
            XCTAssert(state2.value == state1.value)
            
        }
    }
    
    func testSendWithUndo() {
        
        for _ in 0..<100 {
            
            let store = Store(initialState: StructState(value: .random(in: -100...100)),
                                     erasing: Reducers.Native.bind(\StructState.value, to: IntChange.self))
            
            let change = IntChange(oldValue: store.state.value,
                                   newValue: .random(in: -100...100))
            
            let mgr = UndoManager()
            
            store.sendWithUndo(change, undoManager: mgr)
            
            XCTAssert(store.state.value == change.newValue)
            
            mgr.undo()
            
            XCTAssert(store.state.value == change.oldValue)
            
            store.sendWithUndo([change] as UndoGroup, undoManager: mgr)
            
            XCTAssert(store.state.value == change.newValue)
            
            mgr.undo()
            
            XCTAssert(store.state.value == change.oldValue)
            
        }
        
    }
    
}


fileprivate extension RedCatTests {
    
    struct IntChange : PropertyChange {
        var oldValue: Int
        var newValue: Int
    }
    
    struct StructState {
        var value : Int
    }
    
    enum EnumState : Emptyable {
        case value(Int)
        static var empty = EnumState.value(0)
        var value : Int {
            switch self {
            case .value(let result):
                return result
            }
        }
    }
    
}
