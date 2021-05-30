//
//  ViewStore.swift
//  
//
//  Created by Markus Pfeifer on 10.05.21.
//


public extension StoreProtocol {
    
    func map<NewState>(_ transform: @escaping (State) -> NewState) -> MapStore<Self, NewState> {
        MapStore(base: self, transform: transform)
    }
	
		subscript<NewState>(dynamicMember keyPath: KeyPath<State, NewState>) -> MapStore<Self, NewState> {
				MapStore(base: self, transform: { $0[keyPath: keyPath] })
		}
}


public final class MapStore<Base: StoreProtocol, State>: Store<State> {
    
    let base : Base
		let transform : (Base.State) -> State
    
    public override var state : State {
        transform(base.state)
    }
    
    init(base: Base,
         transform: @escaping (Base.State) -> State) {
        self.base = base
        self.transform = transform
        super.init()
    }
    
		public override func send<Action: ActionProtocol>(_ action: Action) {
			base.send(action)
    }
    
		public override func acceptsAction<Action>(_ action: Action) -> Bool where Action : ActionProtocol {
				base.acceptsAction(action)
		}
}

extension MapStore: ObservableStoreProtocol where Base: ObservableStoreProtocol {
	
	public func addObserver<S>(_ observer: S) -> StoreUnsubscriber where S : StoreDelegate, State == S.State {
		base.addObserver(observer.map(transform))
	}
}

#if os(iOS) || os(macOS)
#if canImport(Combine)

import Combine

@available(OSX 10.15, *)
@available(iOS 13.0, *)
extension MapStore: ObservableObject where Base: ObservableObject {
	public typealias ObjectWillChangePublisher = Base.ObjectWillChangePublisher
	public var objectWillChange: Base.ObjectWillChangePublisher { base.objectWillChange }
}
#endif
#endif

public final class ViewStore<Base, State> : Store<State> {
    
    let base : Store<Base>
    public override var state : State {
        _state
    }
    let _state : State
    
    init(base: Store<Base>, transform: (Base) -> State) {
        self.base = base
        self._state = transform(base.state)
        super.init()
    }
    
		public override func send<Action: ActionProtocol>(_ action: Action) {
        base.send(action)
    }
    
}


public extension Store {
    
    func withViewStore<T, U>(_ transform: (State) -> T,
                             completion: (ViewStore<State, T>) -> U) -> U {
        completion(ViewStore(base: self, transform: transform))
    }
    
}
