//
//  ReducerBuilder.swift
//  
//
//  Created by Markus Pfeifer on 09.06.21.
//


@resultBuilder
public enum ReducerBuilder {
    
    public static func buildBlock<R1 : ErasedReducer>(_ r1: R1)
    -> R1 {
        r1
    }
    
    public static func buildBlock<R1 : ErasedReducer,
                                  R2 : ErasedReducer>(_ r1: R1,
                                                      _ r2: R2)
    -> ComposedReducer<R1, R2> {
        r1.compose(with: r2)
    }
    
    public static func buildBlock<R1 : ErasedReducer,
                                  R2 : ErasedReducer,
                                  R3 : ErasedReducer>(_ r1: R1,
                                                      _ r2: R2,
                                                      _ r3: R3)
    -> ComposedReducer<ComposedReducer<R1, R2>, R3> {
        r1.compose(with: r2)
            .compose(with: r3)
    }
    
    public static func buildBlock<R1 : ErasedReducer,
                                  R2 : ErasedReducer,
                                  R3 : ErasedReducer,
                                  R4 : ErasedReducer>(_ r1: R1,
                                                      _ r2: R2,
                                                      _ r3: R3,
                                                      _ r4: R4)
    -> ComposedReducer<ComposedReducer<ComposedReducer<R1, R2>, R3>, R4> {
        r1.compose(with: r2)
            .compose(with: r3)
            .compose(with: r4)
    }
    
    public static func buildBlock<R1 : ErasedReducer,
                                  R2 : ErasedReducer,
                                  R3 : ErasedReducer,
                                  R4 : ErasedReducer,
                                  R5 : ErasedReducer>(_ r1: R1,
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
    
    public static func buildBlock<R1 : ErasedReducer,
                                  R2 : ErasedReducer,
                                  R3 : ErasedReducer,
                                  R4 : ErasedReducer,
                                  R5 : ErasedReducer,
                                  R6 : ErasedReducer>(_ r1: R1,
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
    
    public static func buildEither<R1 : ErasedReducer,
                                   R2 : ErasedReducer>(first component: R1) -> IfReducer<R1, R2> {
        .ifReducer(component)
    }
    
    public static func buildEither<R1 : ErasedReducer,
                                   R2 : ErasedReducer>(second component: R2) -> IfReducer<R1, R2> {
        .elseReducer(component)
    }
    
    public static func buildOptional<R1 : ErasedReducer>(_ component: R1?) -> IfReducer<R1, NopReducer<R1.State>> {
        component.map(IfReducer.ifReducer) ?? IfReducer.elseReducer()
    }
    
    public static func buildLimitedAvailability<R : ErasedReducer>(_ component: R) -> AnyReducer<R.State> {
        AnyReducer(component)
    }
    
}
