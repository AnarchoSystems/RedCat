//
//  CasePath.swift
//  
//
//  Created by Markus Pfeifer on 05.05.21.
//

import CasePaths


/// A ```Releasable``` enum type provides some mechanism to release the current stored associated counted references.
public protocol Releasable {
    
    /// Releases any associated memory that is reference counted. For instance, an ```Array?``` could change its value to nil.
    mutating func releaseCopy()
    
}


/// An ```Emptyable``` enum type has at least one enum case that can be considered "empty".
public protocol Emptyable : Releasable {
    
    /// An enum case that can be created without significant effort.
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
        (/Optional.some).mutate(&self, default: defaultValue,
                                closure: closure)
    }
    
}


public extension CasePath where Root : Releasable {
    
    func mutate<T>(_ whole: inout Root, closure: (inout Value) -> T) -> T? {
        mutate(&whole, optionalDefault: nil, closure: closure)
    }
    
    func mutate(_ whole: inout Root, default fallback: Root, closure: (inout Value) -> Void) {
        mutate(&whole, optionalDefault: fallback, closure: closure)
    }
    
}


extension CasePath where Root : Releasable {
    
    @inlinable
    func mutate<T>(_ whole: inout Root, optionalDefault fallback: Root?, closure: (inout Value) -> T) -> T? {
        
        guard var part = extract(from: whole) else {
            if let fallback = fallback {
                whole = fallback
            }
            return nil
        }
        
        whole.releaseCopy()
        let result = closure(&part)
        whole = embed(part)
        return result 
        
    }
    
}
