//
//  NativeObjects.swift
//  
//
//  Created by Markus Pfeifer on 08.06.21.
//

import Foundation
import RedCat
#if canImport(CoreMotion) && (os(iOS) || os(watchOS) || os(tvOS))
import CoreMotion
#endif
#if canImport(CoreLocation) && os(iOS)
import CoreLocation
#endif

public enum NativeObjects : Dependency {
    public static let defaultValue = ResolvedNativeObjects()
}

public extension Dependencies {
    /// Objects that are natively supported (although not necessarily implemented).
    var native : ResolvedNativeObjects {
        get {self[NativeObjects.self]}
        set {self[NativeObjects.self] = newValue}
    }
}

public final class ResolvedNativeObjects {
    
    /// The network handler of this app. Defaults to ```URLSession.shared```.
    public private(set) lazy var networkHandler : NetworkHandler = URLSession.shared
    
    #if canImport(CoreMotion) && (os(iOS) || os(watchOS) || os(tvOS))
    
    /// The motion manager of this app. Defaults to ```CMMotionManager()```.
    public private(set) lazy var motionManager : MotionManager = CMMotionManager()
    
    #endif
  
    
    #if canImport(CoreLocation) && os(iOS)
    /// The location manager of this app. Defaults to ```CLLocationManager()```.
    /// Currently, AnOx only supports a constant configuration when it comes to things like accuracy or the distance filter.
    /// If you want to change any of these values, you need to override the locationManager.
    public private(set) lazy var locationManager : LocationManager = CLLocationManager()
    #endif
    
}
