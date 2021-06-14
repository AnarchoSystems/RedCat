//
//  ReducerBuilder.swift
//  
//
//  Created by Markus Pfeifer on 09.06.21.
//


@resultBuilder
public enum ReducerBuilder {
    
    public static func buildBlock<R1 : ReducerProtocol>(_ r1: R1)
    -> R1 {
        r1
    }
    
    public static func buildBlock<R1 : ReducerProtocol,
                                  R2 : ReducerProtocol>(_ r1: R1,
                                                      _ r2: R2)
    -> ComposedReducer<R1, R2> {
        r1.compose(with: r2)
    }
    
    public static func buildBlock<R1 : ReducerProtocol,
                                  R2 : ReducerProtocol,
                                  R3 : ReducerProtocol>(_ r1: R1,
                                                      _ r2: R2,
                                                      _ r3: R3)
    -> ComposedReducer<ComposedReducer<R1, R2>, R3> {
        r1.compose(with: r2)
            .compose(with: r3)
    }
    
    public static func buildBlock<R1 : ReducerProtocol,
                                  R2 : ReducerProtocol,
                                  R3 : ReducerProtocol,
                                  R4 : ReducerProtocol>(_ r1: R1,
                                                      _ r2: R2,
                                                      _ r3: R3,
                                                      _ r4: R4)
    -> ComposedReducer<ComposedReducer<ComposedReducer<R1, R2>, R3>, R4> {
        r1.compose(with: r2)
            .compose(with: r3)
            .compose(with: r4)
    }
    
    public static func buildBlock<R1 : ReducerProtocol,
                                  R2 : ReducerProtocol,
                                  R3 : ReducerProtocol,
                                  R4 : ReducerProtocol,
                                  R5 : ReducerProtocol>(_ r1: R1,
                                                      _ r2: R2,
                                                      _ r3: R3,
                                                      _ r4: R4,
                                                      _ r5: R5)
    -> ComposedReducer<ComposedReducer<ComposedReducer<ComposedReducer<R1, R2>, R3>, R4>, R5> {
        r1.compose(with: r2)
            .compose(with: r3)
            .compose(with: r4)
            .compose(with: r5)
    }
    
    public static func buildBlock<R1 : ReducerProtocol,
                                  R2 : ReducerProtocol,
                                  R3 : ReducerProtocol,
                                  R4 : ReducerProtocol,
                                  R5 : ReducerProtocol,
                                  R6 : ReducerProtocol>(_ r1: R1,
                                                      _ r2: R2,
                                                      _ r3: R3,
                                                      _ r4: R4,
                                                      _ r5: R5,
                                                      _ r6: R6)
    -> ComposedReducer<ComposedReducer<ComposedReducer<ComposedReducer<ComposedReducer<R1, R2>, R3>, R4>, R5>, R6> {
        r1.compose(with: r2)
            .compose(with: r3)
            .compose(with: r4)
            .compose(with: r5)
            .compose(with: r6)
    }
    
    public static func buildBlock<State>(_ r1: VoidReducer<State>,
                                         _ r2: VoidReducer<State>,
                                         _ r3: VoidReducer<State>,
                                         _ r4: VoidReducer<State>,
                                         _ r5: VoidReducer<State>,
                                         _ r6: VoidReducer<State>,
                                         components: VoidReducer<State>...) -> VoidReducer<State> {
        VoidReducer{for component in [r1, r2, r3, r4, r5, r6] + components {component.apply((), to: &$0)}}
    }
    
    public static func buildArray<R : ReducerProtocol>(_ components: [R]) -> ReducersChain<R> {
        ReducersChain(components)
    }
    
    public static func buildEither<R1 : ReducerProtocol>(first component: R1) -> AnyReducer<R1.State, R1.Action> {
        component.erased()
    }
    
    public static func buildEither<R2 : ReducerProtocol>(second component: R2) -> AnyReducer<R2.State, R2.Action> {
        Reducers.Native.anyReducer(component)
    }
    
    public static func buildLimitedAvailability<R : ReducerProtocol>(_ component: R) -> AnyReducer<R.State, R.Action> {
        AnyReducer(component)
    }
    
}


public struct ReducersChain<R : ReducerProtocol> : ReducerProtocol {
    
    @usableFromInline
    let array : [R]
    
    public init(_ array: [R]){self.array = array}
    
    @inlinable
    public func apply(_ action: R.Action, to state: inout R.State) {
        for r in array {
            r.apply(action, to: &state)
        }
    }
    
}
