//
//  ViewStore.swift
//  
//
//  Created by Markus Pfeifer on 10.05.21.
//


public extension Store {
    
    func map<NewState>(_ transform: @escaping (State) -> NewState) -> MapStore<State, NewState> {
        MapStore(base: self, transform: transform)
    }
    
}


public final class MapStore<Root, State> : Store<State> {
    
    let base : Store<Root>
    let transform : (Root) -> State
    
    public override var state : State {
        transform(base.state)
    }
    
    init(base: Store<Root>,
         transform: @escaping (Root) -> State) {
        self.base = base
        self.transform = transform
        super.init()
    }
    
    public override func send<Action : ActionProtocol>(_ action: Action) {
        base.send(action)
    }
    
}


public final class ViewStore<Base, State> : Store<State> {
    
    let base : Store<Base>
    public override var state : State {
        _state
    }
    // swiftlint:disable:next identifier_name
    let _state : State
    
    init(base: Store<Base>, transform: (Base) -> State) {
        self.base = base
        self._state = transform(base.state)
        super.init()
    }
    
    public override func send<Action : ActionProtocol>(_ action: Action) {
        base.send(action)
    }
    
}


public extension Store {
    
    func withViewStore<T, U>(_ transform: (State) -> T,
                             completion: (ViewStore<State, T>) -> U) -> U {
        completion(ViewStore(base: self, transform: transform))
    }
    
}
