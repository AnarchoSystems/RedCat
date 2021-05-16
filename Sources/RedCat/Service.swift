//
//  Service.swift
//  RedCat
//
//  Created by Markus Pfeifer on 13.05.21.
//

import Foundation


/// A ```Service``` wraps itself around the reducer to enable side-effects.
///
/// Before each application of the App's main reducer, each service will receive a ```beforeUpdate``` message and has the opportunity to react to the action and interact with the store and its state before the action is dispatched.
/// After each application, the services receive ```afterUpdate``` in reversed order.
/// Services cannot modify the actions already being enqueued, nor can they prevent execution. This should be done by high level reducers.
open class Service<State> {
    
    public init() {}
    
    open func beforeUpdate<Action : ActionProtocol>(store: Store<State>, action: Action, environment: Dependencies) {}
    
    open func afterUpdate<Action : ActionProtocol>(store: Store<State>, action: Action, environment: Dependencies) {}
    
}

internal extension ActionProtocol {
    
    /// Called by the store each time an action is about to be sent to the reducer.
    @usableFromInline
    func beforeUpdate<State>(service: Service<State>, store: Store<State>, environment: Dependencies) {
        service.beforeUpdate(store: store, action: self, environment: environment)
    }
    
    /// Called by the store each time an action has just been sent to the reducer.
    @usableFromInline
    func afterUpdate<State>(service: Service<State>, store: Store<State>, environment: Dependencies) {
        service.afterUpdate(store: store, action: self, environment: environment)
    }
    
}


/// A ```DetailService``` watches some part of the state for changes and if it detects one, it calls the open method ```onUpdate```.
open class DetailService<State, Detail : Equatable> : Service<State> {
    
    
    public let detail : (State) -> Detail
    
    @inlinable
    public final var oldValue : Detail? {
        _oldValue
    }
    
    @usableFromInline
    var _oldValue : Detail?
    
    public init(detail: @escaping (State) -> Detail) {self.detail = detail}
    
    
    public override func afterUpdate<Action : ActionProtocol>(store: Store<State>,
                                                              action: Action,
                                                              environment: Dependencies) {
        let detail = self.detail(store.state)
        guard detail != oldValue else {return}
        onUpdate(newValue: detail, store: store, environment: environment)
        _oldValue = detail
    }
    
    open func onUpdate(newValue: Detail, store: Store<State>, environment: Dependencies) {
        
    }
    
}
