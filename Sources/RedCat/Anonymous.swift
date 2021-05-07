//
//  Anonymous.swift
//  
//
//  Created by Markus Pfeifer on 07.05.21.
//

import CasePaths



@_functionBuilder
public enum Anonymous {
    
    
    public static func buildBlock<R : DependentReducer>(_ reducer: R) -> Reducer<R> {
        Reducer{
            reducer
        }
    }
    
    
    public static func buildBlock<State, Action : ActionProtocol>(_ apply: @escaping (Action, inout State, Environment) -> Void) -> Reducer<ClosureReducer<State, Action>>{
        Reducer(apply)
    }
    
    
    public static func buildBlock<State, Action : ActionProtocol>(_ apply: @escaping (Action, inout State) -> Void) -> Reducer<ClosureReducer<State, Action>>{
        Reducer(apply)
    }
    
    
    public static func buildBlock<State : AnyObject, Action: ActionProtocol>(_ apply: @escaping (Action, State, Environment) -> Void) -> RefReducer<State, Action> {
        RefReducer(apply)
    }
    
    
    public static func buildBlock<State : AnyObject, Action: ActionProtocol>(_ apply: @escaping (Action, State) -> Void) -> RefReducer<State, Action> {
        RefReducer(apply)
    }
    
    
    public static func buildBlock<State, R : DependentClassReducer>(_ aspect: CasePath<State, R.State>, _ reducer: R) -> Reducer<ClassPrismReducer<State, R>> {
        Reducer(aspect){
            reducer
        }
    }
    
    
    public static func buildBlock<State : Emptyable, R : DependentReducer>(_ aspect: CasePath<State, R.State>, _ reducer: R) -> Reducer<PrismReducer<State, R>> {
        Reducer(aspect){
            reducer
        }
    }
    
    
    public static func buildBlock<State, R : DependentReducer>(_ keyPath: WritableKeyPath<State, R.State>, _ reducer: R) -> Reducer<LensReducer<State, R>> {
        Reducer(keyPath){
            reducer
        }
    }
    
}
