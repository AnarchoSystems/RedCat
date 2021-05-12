//
//  Service.swift
//  RedCat
//
//  Created by Markus Pfeifer on 13.05.21.
//

import Foundation


open class Service<State> {
    
    public init() {}
    
    open func beforeUpdate<Action : ActionProtocol>(store: Store<State>, action: Action, environment: Dependencies) {}
    
    open func afterUpdate<Action : ActionProtocol>(store: Store<State>, action: Action, environment: Dependencies) {}
    
}

internal extension ActionProtocol {
    
    @usableFromInline
    func beforeUpdate<State>(service: Service<State>, store: Store<State>, environment: Dependencies) {
        service.beforeUpdate(store: store, action: self, environment: environment)
    }
    
    @usableFromInline
    func afterUpdate<State>(service: Service<State>, store: Store<State>, environment: Dependencies) {
        service.afterUpdate(store: store, action: self, environment: environment)
    }
    
}

open class DetailService<State, Detail : Equatable> : Service<State> {
    
    @usableFromInline
    let detail : (State) -> Detail
    @usableFromInline
    var oldValue : Detail?
    
    public init(detail: @escaping (State) -> Detail) {self.detail = detail}
    
    @inlinable
    public override func afterUpdate<Action : ActionProtocol>(store: Store<State>,
                                                              action: Action,
                                                              environment: Dependencies) {
        let detail = self.detail(store.state)
        guard detail != oldValue else {return}
        oldValue = detail
        onUpdate(newValue: detail, store: store, environment: environment)
    }
    
    open func onUpdate(newValue: Detail, store: Store<State>, environment: Dependencies) {
        
    }
    
}
