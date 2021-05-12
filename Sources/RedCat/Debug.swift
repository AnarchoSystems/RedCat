//
//  Debug.swift
//  
//
//  Created by Markus Pfeifer on 11.05.21.
//

import Foundation

public protocol UnknownActionLogger {
    func log<Action : ActionProtocol>(_ action: Action)
}

fileprivate struct Debug : Dependency {
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
        get {self[Debug.self]}
        set {self[Debug.self] = newValue}
    }
}

public class UnrecognizedActionDebugger<State, Logger : UnknownActionLogger> : Service<State> {
    
    @usableFromInline
    let logger : Logger
    
    /// Logs unrecognized actions in debug mode.
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
         
        if var action = action as? ActionGroup {
            action.unroll()
            for action in action.values {
                check(action, store: store)
            }
        }
        
        else if var action = action as? UndoGroup {
            action.unroll()
            for action in action.values {
                check(action, store: store)
            }
        }
        
        else if !(action is AppInit) && !(action is AppDeinit) {
            check(action, store: store)
        }
        
    }
    
    func check(_ action: ActionProtocol, store: Store<State>) {
        if !action.isAccepted(by: store) {
            action.log(using: logger)
        }
    }
    
}

extension ActionProtocol {
    
    func isAccepted<State>(by store: Store<State>) -> Bool {
        store.acceptsAction(self)
    }

    func log<Logger : UnknownActionLogger>(using logger: Logger) {
        logger.log(self)
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
    public func log<Action : ActionProtocol>(_ action: Action) {
        if trapOnDebug {
                fatalError("Unrecognized action: \(action)")
            }
            else {
                NSLog("Unrecognized action: \(action)")
            }
    }
    
}
