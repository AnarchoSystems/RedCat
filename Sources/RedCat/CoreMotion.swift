//
//  CoreMotion.swift
//  
//
//  Created by Markus Pfeifer on 20.05.21.
//

#if canImport(CoreMotion)

import CoreMotion


public enum MotionManager : Dependency {
    public static var defaultValue : ResolvedMotionManager {
        #if os(iOS) || os(watchOS) || os(tvOS)
        return CMMotionManager()
        #else
        fatalError("RedCat: Default value for motionManager not available on this OS!")
        #endif
    }
}

public protocol ResolvedMotionManager : AnyObject {
    
    var accelerometerUpdateInterval : TimeInterval {get set}
    func stopAccelerometerUpdates()
    func startAccelerometerUpdates(to queue: OperationQueue, withHandler handler: @escaping CMAccelerometerHandler)
    
    var gyroUpdateInterval : TimeInterval {get set}
    func stopGyroUpdates()
    func startGyroUpdates(to queue: OperationQueue, withHandler handler: @escaping CMGyroHandler)
    
    var magnetometerUpdateInterval : TimeInterval {get set}
    func stopMagnetometerUpdates()
    func startMagnetometerUpdates(to queue: OperationQueue, withHandler handler: @escaping (CMMagnetometerData?, Error?) -> Void)
    
    var deviceMotionUpdateInterval : TimeInterval {get set}
    func stopDeviceMotionUpdates()
    func startDeviceMotionUpdates(using frame: CMAttitudeReferenceFrame,
                                  to queue: OperationQueue,
                                  withHandler handler: @escaping CMDeviceMotionHandler)
    
}

#if os(iOS) || os(watchOS) || os(tvOS)
extension CMMotionManager : ResolvedMotionManager {}
#endif

public extension Dependencies {
    var motionManager : ResolvedMotionManager {
        get {self[MotionManager.self]}
        set {self[MotionManager.self] = newValue}
    }
}

public protocol BasicSensor {
    associatedtype UpdateData
    func startUpdates(to queue: OperationQueue,
                      withHandler handler: @escaping (UpdateData?, Error?) -> Void)
    func stopUpdates()
    var updateInterval : TimeInterval {get nonmutating set}
    init(mgr: ResolvedMotionManager)
}

public struct AccelerationSensor : BasicSensor {
    
    let mgr : ResolvedMotionManager
    
    public init(mgr: ResolvedMotionManager) {self.mgr = mgr}
    
    public func startUpdates(to queue: OperationQueue,
                             withHandler handler: @escaping CMAccelerometerHandler) {
        mgr.startAccelerometerUpdates(to: queue, withHandler: handler)
    }
    
    public func stopUpdates() {
        mgr.stopAccelerometerUpdates()
    }
    
    public var updateInterval : TimeInterval {
        get {mgr.accelerometerUpdateInterval}
        nonmutating set {mgr.accelerometerUpdateInterval = newValue}
    }
    
}

public struct GyroSensor : BasicSensor {
    
    let mgr : ResolvedMotionManager
    
    public init(mgr: ResolvedMotionManager) {self.mgr = mgr}
    
    public func startUpdates(to queue: OperationQueue,
                             withHandler handler: @escaping CMGyroHandler) {
        mgr.startGyroUpdates(to: queue, withHandler: handler)
    }
    
    public func stopUpdates() {
        mgr.stopGyroUpdates()
    }
    
    public var updateInterval : TimeInterval {
        get {mgr.gyroUpdateInterval}
        nonmutating set {mgr.gyroUpdateInterval = newValue}
    }
    
}

public struct MagneticSensor : BasicSensor {
    
    let mgr : ResolvedMotionManager
    
    public init(mgr: ResolvedMotionManager) {self.mgr = mgr}
    
    public func startUpdates(to queue: OperationQueue,
                             withHandler handler: @escaping (CMMagnetometerData?, Error?) -> Void) {
        mgr.startMagnetometerUpdates(to: queue, withHandler: handler)
    }
    
    public func stopUpdates() {
        mgr.stopMagnetometerUpdates()
    }
    
    public var updateInterval : TimeInterval {
        get {mgr.magnetometerUpdateInterval}
        nonmutating set {mgr.magnetometerUpdateInterval = newValue}
    }
    
}

public protocol SensorWatchConfig : Equatable {
    associatedtype ReducerState
    associatedtype ResultAction : ActionProtocol
    associatedtype TriggerAction
    var updateInterval : TimeInterval {get}
    var initialState : ReducerState {get}
    func onUpdate(_ state: inout ReducerState, action: TriggerAction) -> ResultAction?
}

public protocol AccelerometerWatchConfig : SensorWatchConfig where
    TriggerAction == CMAccelerometerData {}
public protocol GyroWatchConfig : SensorWatchConfig where
    TriggerAction == CMGyroData {}
public protocol MagnetometerWatchConfig : SensorWatchConfig where
    TriggerAction == CMMagnetometerData {}

public class Sensor<State, Config : SensorWatchConfig, Kind : BasicSensor> : DetailService<State, Config?> where Kind.UpdateData == Config.TriggerAction {
    
    let queue : OperationQueue
    var currentState : Config.ReducerState?
    
    public init(on queue: OperationQueue,
                detail: @escaping (State) -> Config?) {
        self.queue = queue
        super.init(detail: detail)
    }
    
    public override func onUpdate(newValue: Config?,
                                  store: Store<State>,
                                  environment: Dependencies) {
        
        let mgr = Kind(mgr: environment.motionManager)
        mgr.stopUpdates()
        
        guard let newValue = newValue else {
            return
        }
        
        currentState = newValue.initialState
        mgr.updateInterval = newValue.updateInterval
        
        mgr.startUpdates(to: queue) {[weak store] data, error in
            guard let store = store else {return mgr.stopUpdates()}
            
            guard let data = data else {
                return DispatchQueue.main.async {
                    guard self.detail(store.state) == newValue else {return}
                    store.send(Actions.MotionManager.Failure(error: error ?? UnknownError()))
                }
            }
            
            guard var currentState = self.currentState else {
                return
            }
            self.currentState = nil
            
            if let update = newValue.onUpdate(&currentState, action: data) {
                DispatchQueue.main.async {
                    guard self.detail(store.state) == newValue else {return}
                    store.send(update)
                }
            }
            
        }
        
    }
    
}

public typealias Accelerometer<State, Config : AccelerometerWatchConfig>
    = Sensor<State, Config, AccelerationSensor>
public typealias Gyroscope<State, Config : GyroWatchConfig>
    = Sensor<State, Config, GyroSensor>
public typealias Magnetometer<State, Config : MagnetometerWatchConfig>
    = Sensor<State, Config, MagneticSensor>

public protocol DeviceMotionWatchConfig : SensorWatchConfig where TriggerAction == CMDeviceMotion {
    var referenceFrame : CMAttitudeReferenceFrame {get}
}

public final class DeviceMotionSensor<State, Config : DeviceMotionWatchConfig> : DetailService<State, Config?> {
    
    let queue : OperationQueue
    var currentState : Config.ReducerState?
    
    public init(on queue: OperationQueue,
                detail: @escaping (State) -> Config?) {
        self.queue = queue
        super.init(detail: detail)
    }
    
    public override func onUpdate(newValue: Config?,
                                  store: Store<State>,
                                  environment: Dependencies) {
        
        let mgr = environment.motionManager
        mgr.stopDeviceMotionUpdates()
        
        guard let newValue = newValue else {
            return
        }
        
        currentState = newValue.initialState
        mgr.deviceMotionUpdateInterval = newValue.updateInterval
        
        mgr.startDeviceMotionUpdates(using: newValue.referenceFrame,
                                     to: queue) {[weak store] data, error in
            guard let store = store else {return mgr.stopDeviceMotionUpdates()}
            
            guard let data = data else {
                return DispatchQueue.main.async {
                    guard self.detail(store.state) == newValue else {return}
                    store.send(Actions.MotionManager.Failure(error: error ?? UnknownError()))
                }
            }
            
            guard var currentState = self.currentState else {
                return
            }
            self.currentState = nil
            
            if let update = newValue.onUpdate(&currentState, action: data) {
                DispatchQueue.main.async {
                    guard self.detail(store.state) == newValue else {return}
                    store.send(update)
                }
            }
            
        }
        
    }
    
}

public extension Actions {
    
    enum MotionManager {
        
        public struct Acceleration : ActionProtocol {
            public let data : CMAccelerometerData
        }
        
        public struct RotationRate : ActionProtocol {
            public let data : CMGyroData
        }
        
        public struct MagneticField : ActionProtocol {
            public let data : CMMagnetometerData
        }
        
        public struct MotionData : ActionProtocol {
            public let data : CMDeviceMotion
        }
        
        public struct Failure : ActionProtocol {
            public let error : Error
        }
        
    }
    
}


#endif
