//
//  ReducerBuilderTests.swift
//  
//
//  Created by Markus Pfeifer on 14.06.21.
//

import XCTest
import RedCat


extension RedCatTests {
    
    func testBuilderAndDispatch() {
        
        for _ in 0..<10 {
            
            var state1 = Int.random(in: -100...100)
            var state2 = state1
            
            let list = (0..<100).map{_ in ComplexAction.random()}
            
            RedCatTests.dispatchReducer.applyAll(list, to: &state1)
            RedCatTests.directReducer.applyAll(list, to: &state2)
            
            XCTAssertEqual(state1, state2)
            
        }
        
    }
    
    func testBuildArray() {
        
        for _ in 0..<10 {
            
            var int = Int.random(in: -100...100)
            var array = Array(repeating: int, count: 100)
            
            let list = (0..<100).map{_ in Bool.random() ? Int.random(in: -10...10) : nil}
            
            Reducer {(action: Int?, state: inout Int) in
                if let action = action {state += action}
            }.applyAll(list, to: &int)
            RedCatTests.arrayIncDecReducer.applyAll(list, to: &array)
            
            XCTAssert(array.allSatisfy{$0 == int})
            
        }
        
    }
    
    func testBuildBlock() {
        
        var state1 = 0
        var state2 = 0
        RedCatTests.sixIncs.apply((), to: &state1)
        RedCatTests.sevencIncs.apply((), to: &state2)
        XCTAssert(state1 == 6)
        XCTAssert(state2 == 7)
        
    }
    
}


fileprivate extension RedCatTests {
    
    static let baseInc = VoidReducer {(state: inout Int) in state += 1}
    
    @ReducerBuilder
    static var sixIncs : ComposedReducer<ComposedReducer<ComposedReducer<ComposedReducer<ComposedReducer<VoidReducer<Int, Void>, VoidReducer<Int, Void>>, VoidReducer<Int, Void>>, VoidReducer<Int, Void>>, VoidReducer<Int, Void>>, VoidReducer<Int, Void>> {
        baseInc
        baseInc
        baseInc
        baseInc
        baseInc
        baseInc
    }
    
    @ReducerBuilder
    static var sevencIncs : VoidReducer<Int, Void> {
        baseInc
        baseInc
        baseInc
        baseInc
        baseInc
        baseInc
        baseInc
    }
    
    static let arrayIncDecReducer = Reducers.Native.dispatch{(action: Int?) in
        action.map {action in
            for idx in 0..<100 {
                DetailReducer(\[Int][idx]) {VoidReducer {(state: inout Int) in state += action}}
            }
        }
    }
    
    static let dispatchReducer = Reducers.Native.dispatch{(action: ComplexAction) in
        switch action {
        case .inc:
            inc.send(.inc).send().asVoidReducer() // just for code coverage
        case .dec:
            dec.send(.dec).bindAction(to: Int.self).send(42) // just for code coverage  
        case .inc2:
            inc.send(.inc)
            inc.send(.inc)
        case .dec2:
            dec.send(.dec)
            dec.send(.dec)
        case .zero:
            VoidReducer{(state: inout Int) in state = 0}
        }
    }
    
    static let directReducer = Reducers.Native.withClosure{(action: ComplexAction, state: inout Int) in
        switch action {
        case .inc:
            state += 1
        case .dec:
            state -= 1
        case .inc2:
            state += 2
        case .dec2:
            state -= 2
        case .zero:
            state = 0
        }
    }
    
    static let inc = Reducer {(action: ComplexAction, state: inout Int) in
        guard case .inc = action else {return}
        state += 1
    }
    
    static let dec = Reducer {(action: ComplexAction, state: inout Int) in
        guard case .dec = action else {return}
        state -= 1
    }
    
    enum ComplexAction : Int {
        case inc = 0
        case dec = 1
        case inc2 = 2
        case dec2 = 3
        case zero = 4
        static func random() -> Self {
            ComplexAction(rawValue: .random(in: 0...4))!
        }
    }
    
}


extension Optional {
    
    func map<R : ReducerProtocol>(@ReducerBuilder transform: (Wrapped) -> R) -> R? {
        if let self = self {
            return transform(self)
        }
        else {
            return nil
        }
    }
    
}
