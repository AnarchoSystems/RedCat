//
//  Actions.swift
//  
//
//  Created by Markus Pfeifer on 17.05.21.
//

import Foundation


public enum Actions {}


public extension Actions {
    
    
    /// ```AppInit``` is dispatched exactly once right after the initialization of a ```CombineStore``` or a ```ObservableStore```.
    struct AppInit : ActionProtocol {}
 
    
    /// ```AppDeinit``` is dispatched, when ```shotDown()``` is called on a ```Store```. After the dispatch has finished (including actions synchronously dispatched by ```Service```s during ```AppDeinit```), the store becomes invalid.
    struct AppDeinit : ActionProtocol {}

    
}
