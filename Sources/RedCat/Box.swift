//
//  Box.swift
//  
//
//  Created by Markus Pfeifer on 09.05.21.
//

import CasePaths


@dynamicMemberLookup
public class Box<T> {
    
    public var wrapped : T
    
    public init(wrapped: T) {self.wrapped = wrapped}
    
    public subscript<U>(dynamicMember keyPath: WritableKeyPath<T, U>) -> U {
        get {wrapped[keyPath: keyPath]}
        set {wrapped[keyPath: keyPath] = newValue}
    }
    
}



public prefix func /<Root, Value>(_ pattern: @escaping (Box<Value>) -> Root) -> CasePath<Root, Value> {
    // swiftlint:disable:next opening_brace
    /{pattern(Box(wrapped: $0))}
}
    