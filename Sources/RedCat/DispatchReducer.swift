//
//  DispatchReducer.swift
//  
//
//  Created by Markus Pfeifer on 12.05.21.
//

import Foundation


/// A ```DispatchReducer``` essentially lifts ```switch``` statements to the reducer level.
///
/// ```DispatchReducer```s come in handy when dealing with a state that holds multiple instances of a given partial state. Example usecase:
/// ```swift
/// protocol DispatchableAction : ActionProtocol {
///   // attach this to your actions as stored property
///   // even though the partial reducers don't care
///   var keyPath : WritableKeyPath<MyConcreteRootState, MyConcretePartialState>
/// }
///
/// struct Dispatcher : DispatchReducer {
///
///   @ReducerBuilder
///   func dispatch<Action : ActionProtocol>(_ action: Action)
///   -> IfReducer<DetailReducer<MyConcreteRootState,
///                              MyPartialStateReducer>,
///                NopReducer<MyConcreteRootState>> {
///      if let action = action as? DispatchableAction {
///         DetailReducer(action.keyPath,
///                       reducer: MyPartialStateReducer())
///      }
///   }
///
/// }
///
/// ```
///
///A more exotic usecase could be to dispatch actions according to the configuration of the reducer to ease changing the reducer hierarchy while debugging.
///
public protocol DispatchReducer : ErasedReducer {
    
    associatedtype Dispatched : ErasedReducer
    
    /// Dispatches an action to some concrete reducer.
    func dispatch<Action : ActionProtocol>(_ action: Action) -> Dispatched
    
}


public extension DispatchReducer {
    
    @inlinable
    func applyErased<Action : ActionProtocol>(_ action: Action, to state: inout Dispatched.State) {
        dispatch(action).applyErased(action, to: &state)
    }
    
    @inlinable
    func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
        dispatch(action).acceptsAction(action)
    }
    
}

/// An anonymous ```DispatchReducer``` accepting a dynamic action.
public struct ClosureDispatchReducer<Dispatched : ErasedReducer> : DispatchReducer {
    
    @usableFromInline
    let closure : (ActionProtocol) -> Dispatched
    
    @inlinable
    public init(@ReducerBuilder _ closure: @escaping (ActionProtocol) -> Dispatched) {
        self.closure = closure
    }
    
    @inlinable
    public func dispatch<Action>(_ action: Action) -> Dispatched where Action : ActionProtocol {
        closure(action)
    }
    
}

extension Optional : ErasedReducer, DispatchReducer where Wrapped : ErasedReducer {
    
    public typealias State = Dispatched.State
    
    @inlinable
    public func dispatch<Action : ActionProtocol>(_ action: Action) -> IfReducer<Wrapped, NopReducer<Wrapped.State>> {
        map(IfReducer.ifReducer) ?? .elseReducer()
    }
    
}

public extension Reducers.Native {
    
    static func dispatch<Dispatched : ErasedReducer>(@ReducerBuilder _ closure: @escaping (ActionProtocol) -> Dispatched) -> ClosureDispatchReducer<Dispatched> {
        ClosureDispatchReducer(closure)
    }
    
}
