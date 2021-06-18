//
//  CoreMotion.swift
//  
//
//  Created by Markus Pfeifer on 20.05.21.
//

#if canImport(CoreMotion) && os(iOS) || os(watchOS)

import CoreMotion
import RedCat


public protocol MotionManager : AnyObject {
    
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

extension CMMotionManager : MotionManager {}

public protocol BasicSensor {
    associatedtype UpdateData
    func startUpdates(to queue: OperationQueue,
                      withHandler handler: @escaping (UpdateData?, Error?) -> Void)
    func stopUpdates()
    var updateInterval : TimeInterval {get nonmutating set}
    init(mgr: MotionManager)
}

public struct AccelerationSensor : BasicSensor {
    
    let mgr : MotionManager
    
    public init(mgr: MotionManager) {self.mgr = mgr}
    
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
    
    let mgr : MotionManager
    
    public init(mgr: MotionManager) {self.mgr = mgr}
    
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
    
    let mgr : MotionManager
    
    public init(mgr: MotionManager) {self.mgr = mgr}
    
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
    associatedtype ResultAction
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

public final class Sensor<State, Config : SensorWatchConfig, Kind : BasicSensor, Action> : DetailService<State, Config?, Action> where Kind.UpdateData == Config.TriggerAction {
    
    let queue : OperationQueue
    var currentState : Config.ReducerState?
    let convert : (Result<Config.ResultAction, Error>) -> Action
    
    @Injected(\.native.motionManager) var motionManager
    let configure : (State) -> Config?
    
    public init(on queue: OperationQueue,
                configure: @escaping (State) -> Config?,
                onEvent: @escaping (Result<Config.ResultAction, Error>) -> Action) {
        self.queue = queue
        self.convert = onEvent
        self.configure = configure
    }
    
    public func extractDetail(from state: State) -> Config? {
        configure(state)
    }
    
    public func onUpdate(newValue: Config?) {
        
        let mgr = Kind(mgr: motionManager)
        mgr.stopUpdates()
        
        guard let newValue = newValue else {
            return
        }
        
        currentState = newValue.initialState
        mgr.updateInterval = newValue.updateInterval
        
        mgr.startUpdates(to: queue) {data, error in
            
            guard let data = data else {
                return DispatchQueue.main.async {
                    guard self.extractDetail(from: self.store.state) == newValue else {return}
                    self.store.send(self.convert(.failure(error ?? UnknownError())))
                }
            }
            
            guard var currentState = self.currentState else {
                return
            }
            self.currentState = nil
            
            if let update = newValue.onUpdate(&currentState, action: data) {
                DispatchQueue.main.async {
                    guard self.extractDetail(from: self.store.state) == newValue else {return}
                    self.store.send(self.convert(.success(update)))
                }
            }
            
        }
        
    }
    
}

public typealias Accelerometer<State, Config : AccelerometerWatchConfig, Action>
    = Sensor<State, Config, AccelerationSensor, Action>
public typealias Gyroscope<State, Config : GyroWatchConfig, Action>
    = Sensor<State, Config, GyroSensor, Action>
public typealias Magnetometer<State, Config : MagnetometerWatchConfig, Action>
    = Sensor<State, Config, MagneticSensor, Action>

public protocol DeviceMotionWatchConfig : SensorWatchConfig where TriggerAction == CMDeviceMotion {
    var referenceFrame : CMAttitudeReferenceFrame {get}
}

public final class DeviceMotionSensor<State, Config : DeviceMotionWatchConfig, Action> : DetailService<State, Config?, Action> {
    
    let queue : OperationQueue
    var currentState : Config.ReducerState?
    let convert : (Result<Config.ResultAction, Error>) -> Action
    
    @Injected(\.native.motionManager) var motionManager
    let configure : (State) -> Config?
    
    public init(on queue: OperationQueue,
                configure: @escaping (State) -> Config?,
                onEvent: @escaping (Result<Config.ResultAction, Error>) -> Action) {
        self.queue = queue
        self.convert = onEvent
        self.configure = configure
    }
    
    public func extractDetail(from state: State) -> Config? {
        configure(state)
    }
    
    public func onUpdate(newValue: Config?) {
        
        let mgr = motionManager
        mgr.stopDeviceMotionUpdates()
        
        guard let newValue = newValue else {
            return
        }
        
        currentState = newValue.initialState
        mgr.deviceMotionUpdateInterval = newValue.updateInterval
        
        mgr.startDeviceMotionUpdates(using: newValue.referenceFrame,
                                     to: queue) { data, error in
            
            guard let data = data else {
                return DispatchQueue.main.async {
                    guard self.extractDetail(from: self.store.state) == newValue else {return}
                    self.store.send(self.convert(.failure(error ?? UnknownError())))
                }
            }
            
            guard var currentState = self.currentState else {
                return
            }
            self.currentState = nil
            
            if let update = newValue.onUpdate(&currentState, action: data) {
                DispatchQueue.main.async {
                    guard self.extractDetail(from: self.store.state) == newValue else {return}
                    self.store.send(self.convert(.success(update)))
                }
            }
            
        }
        
    }
    
}

public extension Services {
    enum Sensors {}
}

public extension Services.Sensors {
    
    static func accelerometer<State,
                              Config : AccelerometerWatchConfig,
                              Action>(callbackQueue: OperationQueue,
                                      configure: @escaping (State) -> Config?,
                                      onEvent: @escaping (Result<Config.ResultAction, Error>) -> Action) -> Accelerometer<State, Config, Action> {
        Accelerometer(on: callbackQueue, configure: configure, onEvent: onEvent)
    }
    
    static func gyroscope<State,
                          Config : GyroWatchConfig,
                          Action>(configType: Config.Type,
                                  callbackQueue: OperationQueue,
                                  configure: @escaping (State) -> Config?,
                                  onEvent: @escaping (Result<Config.ResultAction, Error>) -> Action) -> Gyroscope<State, Config, Action> {
        Gyroscope(on: callbackQueue, configure: configure, onEvent: onEvent)
    }
    
    static func magnetometer<State,
                             Config : MagnetometerWatchConfig,
                             Action>(callbackQueue: OperationQueue,
                                     configure: @escaping (State) -> Config?,
                                     onEvent: @escaping (Result<Config.ResultAction, Error>) -> Action) -> Magnetometer<State, Config, Action> {
        Magnetometer(on: callbackQueue, configure: configure, onEvent: onEvent)
    }
    
    static func deviceMotion<State,
                             Config : DeviceMotionWatchConfig,
                             Action>(callbackQueue: OperationQueue,
                                     configure: @escaping (State) -> Config?,
                                     onEvent: @escaping (Result<Config.ResultAction, Error>) -> Action) -> DeviceMotionSensor<State, Config, Action> {
        DeviceMotionSensor(on: callbackQueue, configure: configure, onEvent: onEvent)
    }
    
}

#endif
