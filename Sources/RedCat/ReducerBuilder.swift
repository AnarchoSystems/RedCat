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
    
    public static func buildEither<R1 : ReducerProtocol,
                                   R2 : ReducerProtocol>(first component: R1) -> IfReducer<R1, R2> {
        .ifReducer(component)
    }
    
    public static func buildEither<R1 : ReducerProtocol,
                                   R2 : ReducerProtocol>(second component: R2) -> IfReducer<R1, R2> {
        .elseReducer(component)
    }
    
    public static func buildOptional<R1 : ReducerProtocol>(_ component: R1?) -> IfReducer<R1, NopReducer<R1.State, R1.Action>> {
        component.map(IfReducer.ifReducer) ?? IfReducer.elseReducer()
    }
    
    public static func buildLimitedAvailability<R : ReducerProtocol>(_ component: R) -> AnyReducer<R.State, R.Action> {
        AnyReducer(component)
    }
    
    #if swift(<999) // to be removed when associated types of opaque return types can be specified
    
    public static func buildFinalResult<R : ReducerProtocol>(_ component: R) -> AnyReducer<R.State, R.Action> {
        AnyReducer(component)
    }
    
    #endif
    
}
