//
//  ServiceWrapper.swift
//  
//
//  Created by Markus Pfeifer on 04.06.21.
//

import Foundation


public class ServiceWrapper<State, Base : Service<State>> : Service<State> {
    
    @inlinable
    open var base : Base {
        fatalError()
    }
    
    @inlinable
    public final override func beforeUpdate<Action>(store: Store<State>,
                                                    action: Action,
                                                    environment: Dependencies)
    where Action : ActionProtocol {
        base.beforeUpdate(store: store,
                          action: action,
                          environment: environment)
    }
    
    @inlinable
    public final override func afterUpdate<Action>(store: Store<State>,
                                                   action: Action,
                                                   environment: Dependencies)
    where Action : ActionProtocol {
        base.afterUpdate(store: store,
                         action: action,
                         environment: environment)
    }
    
}


public final class ServiceGroup<State> : Service<State> {
    
    @usableFromInline
    let services : [Service<State>]
    
    @inlinable
    public init(_ services: [Service<State>]) {
        self.services = services
    }
    
    @inlinable
    public convenience init(_ services: Service<State>...) {
        self.init(services)
    }
    
    @inlinable
    public convenience init(@ServiceBuilder _ services: () -> [Service<State>]) {
        self.init(services())
    }
    
    @inlinable
    public override func beforeUpdate<Action>(store: Store<State>,
                                              action: Action,
                                              environment: Dependencies)
    where Action : ActionProtocol {
        for service in services {
            service.beforeUpdate(store: store,
                                 action: action,
                                 environment: environment)
        }
    }
    
    @inlinable
    public override func afterUpdate<Action>(store: Store<State>,
                                             action: Action,
                                             environment: Dependencies)
    where Action : ActionProtocol {
        for service in services.reversed() {
            service.afterUpdate(store: store,
                                action: action,
                                environment: environment)
        }
    }
    
}


@resultBuilder
public struct ServiceBuilder {
    public static func buildBlock<State>(_ components: Service<State>...) -> [Service<State>] {
        components
    }
}
