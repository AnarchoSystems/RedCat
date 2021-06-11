//
//  TestReducers.swift
//  
//
//  Created by Markus Pfeifer on 06.05.21.
//

import RedCat



enum TestReducers {
    
    static func inc<State>(type: State.Type = State.self) -> IncReducer<State> {
        IncReducer()
    }
    
    static func dec<State>(type: State.Type = State.self) -> DecReducer<State> {
        DecReducer()
    }
    
    struct IncReducer<State> : ReducerProtocol {
        
        func apply(_ action: IncDec<State>, to state: inout State) {
            guard case .inc = action.kind else {return}
            state[keyPath: action.value] += 1
        }
        
    }
    
    struct DecReducer<State> : ReducerProtocol {
        
        func apply(_ action: IncDec<State>, to state: inout State) {
            guard case .dec = action.kind else {return}
            state[keyPath: action.value] -= 1
        }
        
    }
    
}


struct IncDec<State> : Undoable {
    
    let value : WritableKeyPath<State, Int>
    var kind : Kind
    
    static func inc(value: WritableKeyPath<State, Int>) -> Self {
        IncDec(value: value, kind: .inc)
    }
    
    static func dec(value: WritableKeyPath<State, Int>) -> Self {
        IncDec(value: value, kind: .dec)
    }
    
    mutating func invert() {
        kind.invert()
    }
    
    enum Kind {
        case inc
        case dec
        mutating func invert() {
            switch self {
            case .inc:
                self = .dec
            case .dec:
                self = .inc
            }
        }
    }
}
