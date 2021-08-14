//
//  ResponseMapReducer.swift
//  
//
//  Created by Markus Kasperczyk on 14.08.21.
//


public extension ReducerProtocol {
    
    func mapResponse<NewResponse>(_ transform: @escaping (Response) -> NewResponse) -> ResponseMapReducer<Self, NewResponse> {
        ResponseMapReducer(self, transform)
    }
    
}


public struct ResponseMapReducer<R : ReducerProtocol, NewResponse> : ReducerProtocol {
    
    @usableFromInline
    let reducer : R
    @usableFromInline
    let transform : (R.Response) -> NewResponse
    
    @usableFromInline
    init(_ reducer: R, _ transform: @escaping (R.Response) -> NewResponse) {
        self.reducer = reducer
        self.transform = transform
    }
    
    public func apply(_ action: R.Action, to state: inout R.State) -> NewResponse {
        transform(reducer.apply(action, to: &state))
    }
    
}


public extension Reducers {
    
    static func mapResponse<Of : ReducerProtocol, NewResponse>(of: Of, _ transform: @escaping (Of.Response) -> NewResponse) -> ResponseMapReducer<Of, NewResponse> {
        of.mapResponse(transform)
    }
    
}
