//
//  ReducerWrapper.swift
//  
//
//  Created by Markus Pfeifer on 06.05.21.
//

import CasePaths



/// A ```ReducerWrapper``` is a type used for indirect composition. The implementation of what should happen to the state given an ```Action``` is given via the ```body``` property. The single responsibility of ```ReducerWrapper``` is to hide complex composed body types.
public protocol ReducerWrapper : ReducerProtocol where State == Body.State, Action == Body.Action {
    
    associatedtype State = Body.State
    associatedtype Action = Body.Action
    associatedtype Body : ReducerProtocol
    
    /// The reducer to apply to the ```State```.
    var body : Body {get}
    
}


public extension ReducerWrapper {
    
    @inlinable
    func apply(_ action: Body.Action,
               to state: inout Body.State) {
        body.apply(action,
                   to: &state)
    }
    
}


/// An "anonymous" ```ReducerWrapper```. A lot of initializers are provided to make it easy to write small reducers.
public struct Reducer<Body : ReducerProtocol> : ReducerWrapper {
    
    public let body : Body
    
    @inlinable
    public init(_ body: () -> Body) {
        self.body = body()
    }
    
    @inlinable
    public init<State, Action>(_ closure: @escaping (Action, inout State) -> Void)
    where Body == ClosureReducer<State, Action> {
        self.body = ClosureReducer(closure)
    }
    
    @inlinable
    public init<State : Releasable, R : ReducerProtocol, Action>(_ aspect: CasePath<State, R.State>,
                                                                 where match: @escaping (R.Action) -> Action,
                                                                 _ body: () -> R)
    where Body == AspectReducer<State, R, Action> {
        self.body = AspectReducer(aspect, matchAction: match, reducer: body())
    }
    
    @inlinable
    public init<State : Releasable, R : ReducerProtocol>(_ aspect: CasePath<State, R.State>,
                                                                 _ body: () -> R)
    where Body == AspectReducer<State, R, R.Action> {
        self.body = AspectReducer(aspect, reducer: body())
    }
    
    @inlinable
    public init<State, R : ReducerProtocol, Action>(_ detail: WritableKeyPath<State, R.State>,
                                            where match: @escaping (R.Action) -> Action,
                                            _ body: () -> R)
    where Body == DetailReducer<State, R, Action> {
        self.body = DetailReducer(detail, matchAction: match, reducer: body())
    }
    
    @inlinable
    public init<State, R : ReducerProtocol>(_ detail: WritableKeyPath<State, R.State>,
                                            _ body: () -> R)
    where Body == DetailReducer<State, R, R.Action> {
        self.body = DetailReducer(detail, reducer: body())
    }
    
}
