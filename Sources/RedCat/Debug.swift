//
//  Debug.swift
//  
//
//  Created by Markus Pfeifer on 11.05.21.
//

import Foundation

public protocol UnknownActionLogger {
    func log<Action : ActionProtocol>(_ action: Action, debugMode: Bool)
}

struct DebugFlagKey : EnvironmentKey {
    static var defaultValue : Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}

public extension Dependencies {
    var debug : Bool {
        get {self[DebugFlagKey.self]}
        set {self[DebugFlagKey.self] = newValue}
    }
}

public class UnrecognizedActionDebugger<State, Logger : UnknownActionLogger> : Service<State> {
    
    @usableFromInline
    let logger : Logger
    
    /// Logs unrecognized actions.
    /// - Parameters:
    ///     - logger: What to do if an invalid action is received.
    @inlinable
    public init(logger: Logger) {
        self.logger = logger
        super.init()
    }
    
    public override func beforeUpdate<Action : ActionProtocol>(store: Store<State>,
                                                               action: Action,
                                                               environment: Dependencies) {
        
        if !store.acceptsAction(ofType: Action.self) {
            
            logger.log(action, debugMode: environment.debug)
            
        }
        
    }
    
}


public extension UnrecognizedActionDebugger where Logger == DefaultUnknownActionLogger {
    
    @inlinable
    convenience init(trapOnDebug: Bool) {
        self.init(logger: Logger(trapOnDebug: trapOnDebug))
    }
    
}


public struct DefaultUnknownActionLogger : UnknownActionLogger {
    
    @usableFromInline
    let trapOnDebug : Bool
    
    @inlinable
    public init(trapOnDebug: Bool) {self.trapOnDebug = trapOnDebug}
    
    @inlinable
    public func log<Action : ActionProtocol>(_ action: Action, debugMode: Bool) {
        if debugMode {
            if trapOnDebug {
                fatalError("Unrecognized action: \(action)")
            }
            else {
                NSLog("Unrecognized action: \(action)")
            }
        }
    }
    
}
