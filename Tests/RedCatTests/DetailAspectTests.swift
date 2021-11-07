//
//  DetailAspectTests.swift
//  
//
//  Created by Markus Pfeifer on 14.06.21.
//

import XCTest
import RedCat
import CasePaths


extension RedCatTests {
    
    func testDetail() {
        
        for _ in 0..<10 {
            
            var state1 = StructState(value: .random(in: -100...100))
            var state2 = state1
            var state3 = state2
            var state4 = state3
            
            
            let list = (0..<100).map{_ in IncDec.random()}
            
            RedCatTests.explicitDetailReducer.applyAll(list, to: &state1)
            RedCatTests.implicitDetailReducer.applyAll(list, to: &state2)
            NopReducer().compose(with: RedCatTests.directReducer, property: \StructState.value).applyAll(list, to: &state3)
            RedCatTests.erasedDetailReducer.applyAll(list, to: &state4)
            
            XCTAssertEqual(state1, state2)
            XCTAssertEqual(state2, state3)
            XCTAssertEqual(state3, state4)
            
        }
        
    }
    
    func testAspect() {
        
        for _ in 0..<10 {
            
            var state1 = EnumState.value(.random(in: -100...100))
            var state2 = state1
            var state3 = state2
            var state4 = state3
            
            let list = (0..<100).map{_ in IncDec.random()}
            
            RedCatTests.explicitAspectReducer.applyAll(list, to: &state1)
            RedCatTests.implicitAspectReducer.applyAll(list, to: &state2)
            NopReducer().compose(with: RedCatTests.directReducer, aspect: /EnumState.value).applyAll(list, to: &state3)
            RedCatTests.erasedAspectReducer.applyAll(list, to: &state4)
            
            XCTAssertEqual(state1, state2)
            XCTAssertEqual(state2, state3)
            XCTAssertEqual(state3, state4)
            
        }
        
    }
    
}



fileprivate extension RedCatTests {
    
    enum EnumState : Emptyable, Equatable {
        case value(Int)
        static var empty : Self {.value(0)}
    }
    
    struct StructState : Equatable {
        var value : Int
    }
    
    static let explicitDetailReducer = DetailReducer()
    static let explicitAspectReducer = AspectReducer()
    static let implicitDetailReducer = Reducers.Native.detailReducer(\StructState.value, RedCatTests.apply)
    static let implicitAspectReducer = Reducers.Native.aspectReducer(/EnumState.value, RedCatTests.apply)
    static let erasedDetailReducer = Reducer(\StructState.value) {directReducer}
    static let erasedAspectReducer = Reducer(/EnumState.value) {directReducer}
    static let directReducer = Reducer(RedCatTests.apply)
    
    struct DetailReducer : DetailReducerProtocol {
        let keyPath = \StructState.value
        func apply(_ action: IncDec, to state: inout Int) {
            incDec(action, &state)
        }
    }
    
    struct AspectReducer : AspectReducerProtocol {
        let casePath : CasePath = /EnumState.value
        func apply(_ action: IncDec, to state: inout Int) {
            incDec(action, &state)
        }
    }
    
}

fileprivate func incDec(_ action: IncDec, _ state: inout Int) {
   RedCatTests.apply(action, to: &state)
}
