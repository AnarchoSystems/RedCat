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
         
        if !(action is Actions.AppInit) && !(action is Actions.AppDeinit) {
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
    convenience init(trapOnDebug: Bool = true) {
        self.init(logger: Logger(trapOnDebug: trapOnDebug))
    }
    
}

public extension Services {
    
    enum Debug {
        public static func unrecognizedActions<State>(_ stateType: State.Type = State.self) -> UnrecognizedActionDebugger<State, DefaultUnknownActionLogger> {
            UnrecognizedActionDebugger()
        }
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
                fatalError("RedCat: Unrecognized action: \(action)")
            }
            else {
                print("RedCat: Unrecognized action: \(action)")
            }
    }
    
}
