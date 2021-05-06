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
    
    struct IncReducer<State> : Reducer {
        
        func apply(_ action: Inc<State>, to state: inout State) {
            state[keyPath: action.value] += 1
        }
        
    }
    
    struct DecReducer<State> : Reducer {
        
        func apply(_ action: Dec<State>, to state: inout State) {
            state[keyPath: action.value] -= 1
        }
        
    }
    
}


struct Inc<State> : ActionProtocol{
    let value : WritableKeyPath<State, Int>
}
struct Dec<State> : ActionProtocol{
    let value : WritableKeyPath<State, Int>
}
