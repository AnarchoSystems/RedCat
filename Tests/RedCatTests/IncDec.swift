//
//  IncDec.swift
//  
//
//  Created by Markus Pfeifer on 06.05.21.
//

import RedCat


extension RedCatTests {
    
    static func apply(_ incDec: IncDec, to number: inout Int) {
        switch incDec {
        case .inc:
            number += 1
        case .dec:
            number -= 1
        }
    }
    
}


enum IncDec : Undoable {
    
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
    
    init(_ bool: Bool) {
        self = bool ? .inc : .dec
    }
    
    static func random() -> Self {
        IncDec(.random())
    }
    
}
