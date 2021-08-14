//
//  PipedReducer.swift
//  
//
//  Created by Markus Kasperczyk on 14.08.21.
//


public protocol ExitCoding {
    
    static func ??(lhs: Self, rhs: @autoclosure () throws -> Self) rethrows -> Self
    
}


extension Optional : ExitCoding {}


extension Bool : ExitCoding {
    
    public static func ??(lhs: Self, rhs: @autoclosure () throws -> Self) rethrows -> Self {
        try lhs || rhs()
    }
    
}


// more informative version
public enum ExitCode<Success, Failure : Error> : ExitCoding {
    
    case proceed
    case success(Success)
    case failure(Failure)
    
    public static func ??(lhs: Self, rhs: @autoclosure () throws -> Self) rethrows -> Self {
        guard case .proceed = lhs else {
            return lhs
        }
        return try rhs()
    }
    
}


public extension ReducerProtocol where Response : ExitCoding {
    
    static func ??<Other : ReducerProtocol>(lhs: Self, rhs: Other) -> PipedReducer<Self, Other> {
        PipedReducer(lhs, rhs)
    }
    
}


public struct PipedReducer<R1 : ReducerProtocol, R2 : ReducerProtocol> : ReducerProtocol where R1.Response : ExitCoding, R1.Action == R2.Action, R1.State == R2.State, R1.Response == R2.Response {
    
    @usableFromInline
    let r1 : R1
    @usableFromInline
    let r2 : R2
    
    @usableFromInline
    init(_ r1: R1, _ r2: R2) {
        self.r1 = r1
        self.r2 = r2
    }
    
    public func apply(_ action: R1.Action, to state: inout R1.State) -> R1.Response {
        r1.apply(action, to: &state) ?? r2.apply(action, to: &state)
    }
    
}
