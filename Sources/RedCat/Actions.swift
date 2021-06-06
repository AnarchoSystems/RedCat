//
//  Actions.swift
//  
//
//  Created by Markus Pfeifer on 17.05.21.
//

import Foundation


public enum Actions {}


public extension Actions {
    
    
    /// ```AppInit``` is dispatched exactly once right after the initialization of an```ObservableStore```.
    struct AppInit : ActionProtocol {
        @usableFromInline
        init() {}
    }
 
    
    /// ```AppDeinit``` is dispatched, when ```shotDown()``` is called on a ```Store```. After the dispatch has finished (including actions synchronously dispatched by ```Service```s during ```AppDeinit```), the store becomes invalid.
    struct AppDeinit : ActionProtocol {}

    
}
