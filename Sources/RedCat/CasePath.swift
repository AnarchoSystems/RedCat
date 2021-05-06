//
//  CasePath.swift
//  
//
//  Created by Markus Pfeifer on 05.05.21.
//

import CasePaths



public protocol Emptyable {
    
    static var empty : Self{get}
    
}


extension Optional : Emptyable{
    
    @inlinable
    public static var empty : Wrapped? {
        nil
    }
    
}


public extension CasePath where Root : Emptyable {
    
    func mutate(_ whole: inout Root, closure: (inout Value) -> Void) {
        mutate(&whole, optionalDefault: nil, closure: closure)
    }
    
    func mutate(_ whole: inout Root, default fallback: Root, closure: (inout Value) -> Void) {
        mutate(&whole, optionalDefault: fallback, closure: closure)
    }
    
}


extension CasePath where Root : Emptyable {
    
    @usableFromInline
    func mutate(_ whole: inout Root, optionalDefault fallback: Root?, closure: (inout Value) -> Void) {
        
        guard var part = extract(from: whole) else {
            if let fallback = fallback{
                whole = fallback
            }
            return
        }
        
        whole = .empty
        closure(&part)
        whole = embed(part)
        
    }
    
}


public extension CasePath where Value : AnyObject {
    
    func mutate(_ whole: Root, closure: (Value) -> Void) {
        
        guard let part = extract(from: whole) else {
            return
        }
        
        closure(part)
        
    }
    
    func mutate(_ whole: inout Root, default fallback: Root, closure: (Value) -> Void) {
        
        guard let part = extract(from: whole) else {
            whole = fallback
            return
        }
        
        closure(part)
        
    }
    
}
