//
//  InternalFlags.swift
//  
//
//  Created by Markus Pfeifer on 08.06.21.
//

import Foundation


public enum InternalFlags : Dependency {
    public static let defaultValue = ResolvedInternalFlags()
}


public extension Dependencies {
    /// Flags that RedCat uses internally, but can be overridden.
    var internalFlags : ResolvedInternalFlags {
        get {self[InternalFlags.self]}
        set {self[InternalFlags.self] = newValue}
    }
}


public struct ResolvedInternalFlags {
    
    /// If true, a warning will be printed, if the ```AppInit``` is somehow sent more than once.
    public var appInitCheck = true
    
    ///If true, a warning will be printed, if an inefficiency is detected with how the store notifies observers.
    public var warnInefficientObservers = true
    
}
