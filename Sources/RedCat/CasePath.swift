//
//  CasePath.swift
//  
//
//  Created by Markus Pfeifer on 05.05.21.
//

import CasePaths



public protocol Releasable {
    
    mutating func releaseCopy()
    
}


public protocol Emptyable : Releasable {
    
    static var empty : Self {get}
    
}

public extension Emptyable {
    
    @inlinable
    mutating func releaseCopy() {
        self = .empty
    }
    
}

extension Optional : Emptyable {
    
    @inlinable
    public static var empty : Wrapped? {
        nil
    }
    
}


public extension Optional {
    
    @inlinable
    mutating func modify(default defaultValue: Wrapped? = nil,
                         _ closure: @escaping (inout Wrapped) -> Void) {
        (/Optional.some).mutate(&self, default: defaultValue, closure: closure)
    }
    
}


public extension CasePath where Root : Releasable {
    
    func mutate(_ whole: inout Root, closure: (inout Value) -> Void) {
        mutate(&whole, optionalDefault: nil, closure: closure)
    }
    
    func mutate(_ whole: inout Root, default fallback: Root, closure: (inout Value) -> Void) {
        mutate(&whole, optionalDefault: fallback, closure: closure)
    }
    
}


extension CasePath where Root : Releasable {
    
    @inlinable
    func mutate(_ whole: inout Root, optionalDefault fallback: Root?, closure: (inout Value) -> Void) {
        
        guard var part = extract(from: whole) else {
            if let fallback = fallback {
                whole = fallback
            }
            return
        }
        
        whole.releaseCopy()
        closure(&part)
        whole = embed(part)
        
    }
    
}
