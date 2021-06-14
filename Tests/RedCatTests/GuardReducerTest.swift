//
//  GuardReducerTest.swift
//  
//
//  Created by Markus Pfeifer on 14.06.21.
//

import XCTest
import RedCat
import CasePaths


extension RedCatTests {
    
    func testGuardReducer() {
        
        for _ in 0..<10 {
            
            var state1 = State(value: .random(in: -100...100), isEditable: .bool(.random()))
            var state2 = state1
            
            let list = (0..<100).map{_ in Bool.random() ? Action.toggleEditable : .incDec(.random())}
            
            RedCatTests.directReducer.applyAll(list, to: &state1)
            RedCatTests.dispatchReducer.applyAll(list, to: &state2)
            
            XCTAssertEqual(state1, state2)
            
        }
        
    }
    
}


fileprivate extension RedCatTests {
    
    static let directReducer = Reducer {(action: Action, state: inout State) in
        switch action {
        case .incDec(let incDec):
            guard state.isEditable.value else {return}
            RedCatTests.apply(incDec, to: &state.value)
        case .toggleEditable:
            RedCatTests.toggleReducer.apply((), to: &state.isEditable)
        }
    }
    
    static let dispatchReducer = DispatchReducer {(action: Action) in
        switch action {
        case .incDec(let action):
            Reducer(\State.value, where: \.isEditable.value) {incDecReducer}.send(action)
        case .toggleEditable:
            Reducer(\State.isEditable) {toggleReducer}
        }
    }
    static let incDecReducer = Reducer(RedCatTests.apply)
    static let toggleReducer = Reducer(/Editable.bool, where: {_ in true}){toggle}
    
    static let toggle = VoidReducer {(state: inout Bool) in
        state.toggle()
    }
    
    struct State : Equatable {
        var value : Int
        var isEditable : Editable
    }
    
    enum Editable : Emptyable, Equatable {
        case bool(Bool)
        static let empty = Editable.bool(true)
        var value : Bool {
            switch self {
            case .bool(let result):
                return result
            }
        }
    }
    
    enum Action {
        case incDec(IncDec)
        case toggleEditable
    }
    
}
