//
//  DispatchReducer.swift
//  
//
//  Created by Markus Pfeifer on 12.05.21.
//

import Foundation


/// A ```DispatchReducerProtocol``` essentially lifts ```switch``` statements to the reducer level.
///
/// ```DispatchReducerProtocol```s come in handy when composing heterogenous reducers. Example:
/// ```swift
///
/// struct Dispatcher : DispatchReducer {
///
///   @ReducerBuilder
///   func dispatch(_ action: HighLevelAction) -> AnyReducer<MyConcreteRootState, MyAction> {
///         switch action {
///             case .module1(let module1Action):
///                 DetailReducer(\MyConcreteRootState.module1, reducer: Module1Reducer())
///             case .module2(let module2Action):
///                 DetailReducer(\MyConcreteRootState.module2, reducer: Module2Reducer())
///                 ...
///         }
///   }
///
/// }
///
/// ```
///
/// - Note: It is recommended not to use @ReducerBuilder in longer ```switch``` statements for efficiency reasons.
///
public protocol DispatchReducerProtocol : ReducerProtocol where State == Dispatched.State {
    
    associatedtype State = Dispatched.State
    associatedtype Action
    associatedtype Dispatched : ReducerProtocol
    
    /// Dispatches an action to some concrete reducer.
    func dispatch(_ action: Action) -> Dispatched
    func convert(_ action: Action) -> Dispatched.Action
    
}


public extension DispatchReducerProtocol {
    
    @inlinable
    func apply(_ action: Action, to state: inout Dispatched.State) {
        dispatch(action).apply(convert(action), to: &state)
    }
    
}

public extension DispatchReducerProtocol where Action == Dispatched.Action {
    
    @inlinable
    func convert(_ action: Action) -> Action {
        action
    }
    
}

public extension DispatchReducerProtocol where Dispatched.Action == Void {
    
    @inlinable
    func convert(_ action: Action) {}
    
}

/// An anonymous ```DispatchReducer``` accepting a dynamic action.
public struct DispatchReducer<Dispatched : ReducerProtocol> : DispatchReducerProtocol {
    
    @usableFromInline
    let closure : (Dispatched.Action) -> Dispatched
    
    @inlinable
    public init(@ReducerBuilder _ closure: @escaping (Dispatched.Action) -> Dispatched) {
        self.closure = closure
    }
    
    @inlinable
    public func dispatch(_ action: Dispatched.Action) -> Dispatched {
        closure(action)
    }
    
}

extension Optional : ReducerProtocol, DispatchReducerProtocol where Wrapped : ReducerProtocol {
    
    public typealias State = Wrapped.State
    public typealias Action = Wrapped.Action
    public typealias Dispatched = IfReducer<Wrapped, NopReducer<Wrapped.State, Wrapped.Action>> 
    
    @inlinable
    public func dispatch(_ action: Wrapped.Action) -> IfReducer<Wrapped, NopReducer<Wrapped.State, Wrapped.Action>> {
        map(IfReducer.ifReducer) ?? .elseReducer()
    }
    
}

public extension Reducers.Native {
    
    static func dispatch<Dispatched : ReducerProtocol>(@ReducerBuilder _ closure: @escaping (Dispatched.Action) -> Dispatched) -> DispatchReducer<Dispatched> {
        DispatchReducer(closure)
    }
    
}
