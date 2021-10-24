//
//  MaybeStore.swift
//  
//
//  Created by Markus Kasperczyk on 24.10.21.
//

import CasePaths


public extension StoreProtocol {
    
    static func ??<T>(_ lhs: Self, rhs: @escaping @autoclosure () -> T) -> MapStore<Self, T, Action> where State == T? {
        lhs.map({$0 ?? rhs()})
    }
    
}


public extension MapStore {
    
    static func ??<T>(_ lhs: MapStore, rhs: @escaping @autoclosure () -> T) -> MapStore<Wrapped, T, Action> where State == T? {
        let trafo = lhs.transform
        let onAction = lhs.embed
        return lhs.wrapped.map({trafo($0) ?? rhs()},
                               onAction: onAction)
    }
    
}


public protocol Perspective {
    
    associatedtype WholeState
    
    static var casePath : CasePath<WholeState, Self> {get}
    
}


public extension StoreModule {
    
    func project<T : Perspective>(_ wholeState: T.WholeState) -> T? where State == T? {
        T.casePath.extract(from: wholeState)
    }
    
}
