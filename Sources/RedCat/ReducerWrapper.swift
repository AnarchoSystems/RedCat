//
//  ReducerWrapper.swift
//  
//
//  Created by Markus Pfeifer on 06.05.21.
//

import CasePaths



/// A ```ReducerWrapper``` is a type used for indirect composition. The implementation of what should happen to the state given an ```Action``` is given via the ```body``` property. The single responsibility of ```ReducerWrapper``` is to hide complex composed body types in the absence of opaque return types with accessible associatedtype.
public protocol ReducerWrapper : ErasedReducer {
    
    associatedtype Body : ErasedReducer
    
    /// The reducer to apply to the ```State```.
    var body : Body {get}
    
}


public extension ReducerWrapper {
    
    @inlinable
    func applyErased<Action : ActionProtocol>(_ action: Action,
                                              to state: inout Body.State) {
        body.applyErased(action,
                         to: &state)
    }
    
    @inlinable
    func acceptsAction<Action : ActionProtocol>(_ action: Action) -> Bool {
        body.acceptsAction(action)
    }
    
}


/// An "anonymous" ```ReducerWrapper```. A lot of initializers are provided to make it easy to write small reducers.
public struct Reducer<Body : ErasedReducer> : ReducerWrapper {
    
    public let body : Body
    
    @inlinable
    public init(_ body: () -> Body) {
        self.body = body()
    }
    
    @inlinable
    public init<State, Action : ActionProtocol>(_ closure: @escaping (Action, inout State) -> Void)
    where Body == ClosureReducer<State, Action> {
        self.body = ClosureReducer(closure)
    }
    
    @inlinable
    public init<State : Releasable, R : ErasedReducer>(_ aspect: CasePath<State, R.State>, _ body: () -> R)
    where Body == AspectReducer<State, R> {
        self.body = AspectReducer(aspect, reducer: body())
    }
    
    @inlinable
    public init<State, R : ErasedReducer>(_ detail: WritableKeyPath<State, R.State>, _ body: () -> R)
    where Body == DetailReducer<State, R> {
        self.body = DetailReducer(detail, reducer: body())
    }
    
}
