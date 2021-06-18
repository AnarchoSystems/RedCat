//
//  CoreLocation.swift
//  
//
//  Created by Markus Pfeifer on 08.06.21.
//

#if canImport(CoreLocation) && os(iOS)

import RedCat
import CoreLocation


public protocol LocationManager : NSObject {
    
    var delegate : CLLocationManagerDelegate? {get set}
    
    func startUpdatingLocation()
    func stopUpdatingLocation()
    
    func startUpdatingHeading()
    func stopUpdatingHeading()
    
    func startMonitoring(for: CLRegion)
    func stopMonitoring(for: CLRegion)
    
    func startMonitoringVisits()
    func stopMonitoringVisits()
    
    func requestAlwaysAuthorization()
    func requestWhenInUseAuthorization()
    
}

extension CLLocationManager : LocationManager {}

public enum LocationAuthorizationRequest : Equatable {
    case always
    case whenInUse
}

public struct LocationObservationConfiguration : Equatable {
    
    public var requestedAuthorization : LocationAuthorizationRequest? = nil
    public var observingLocation = false
    public var observingHeading = false
    public var observedRegions : Set<CLRegion> = []
    public var observingVisits = false
    
    public init() {}
    
}

@available(iOS 13, *)
public final class LocationService<State, Action> : DetailService<State, LocationObservationConfiguration, Action> {
    
    private let delegate : LocationManagerDelegate<State, Action>
    
    @Injected(\.native.locationManager) var locationManager
    let configure : (State) -> LocationObservationConfiguration
    
    public init(_ delegate: LocationManagerDelegate<State, Action>,
                configure: @escaping (State) -> LocationObservationConfiguration) {
        self.delegate = delegate
        self.configure = configure
    }
    
    public func extractDetail(from state: State) -> LocationObservationConfiguration {
        configure(state)
    }
    
    public func onAppInit() {
        delegate.store = store
        locationManager.delegate = delegate
    }
    
    public func onUpdate(newValue: LocationObservationConfiguration) {
        
        if
            let authRequest = newValue.requestedAuthorization,
            authRequest != oldValue.requestedAuthorization {
            switch authRequest {
            case .always:
                locationManager.requestAlwaysAuthorization()
            case .whenInUse:
                locationManager.requestWhenInUseAuthorization()
            }
        }
        
        if newValue.observingLocation != oldValue.observingLocation {
            switch newValue.observingLocation {
            case true:
                locationManager.startUpdatingLocation()
            case false:
                locationManager.stopUpdatingLocation()
            }
        }
        
        if newValue.observingHeading != oldValue.observingHeading {
            switch newValue.observingHeading {
            case true:
                locationManager.startUpdatingHeading()
            case false:
                locationManager.stopUpdatingHeading()
            }
        }
        
        if newValue.observingVisits != oldValue.observingVisits {
            switch newValue.observingVisits {
            case true:
                locationManager.startMonitoringVisits()
            case false:
                locationManager.stopMonitoringVisits()
            }
        }
        
        let removedRegions = oldValue.observedRegions.subtracting(newValue.observedRegions)
        for region in removedRegions {
            locationManager.stopMonitoring(for: region)
        }
        let addedRegions = newValue.observedRegions.subtracting(oldValue.observedRegions)
        for region in addedRegions {
            locationManager.startMonitoring(for: region)
        }
        
    }
    
}

open class LocationManagerDelegate<State, Action> : NSObject, CLLocationManagerDelegate {
    
    fileprivate(set) public final var store : StoreStub<State, Action>!
    
}

@available(iOS 13, *)
public extension Services {
    static func location<State, Action>(_ delegate: LocationManagerDelegate<State, Action>,
                                 configure: @escaping (State) -> LocationObservationConfiguration)
    -> LocationService<State, Action> {
        LocationService(delegate, configure: configure)
    }
}

#endif
