//
//  Dependencies+Native.swift
//  
//
//  Created by Markus Pfeifer on 12.06.21.
//

import Foundation


public enum NativeValues : Dependency {
    public static let defaultValue = ResolvedNativeValues()
}


public extension Dependencies {
    var nativeValues : ResolvedNativeValues {
        get {self[NativeValues.self]}
        set {self[NativeValues.self] = newValue}
    }
}


public final class ResolvedNativeValues {
    
    public private(set) lazy var debug : Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()
    
    public private(set) lazy var isSimulator : Bool = {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }()
    
}
