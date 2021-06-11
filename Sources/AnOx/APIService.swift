//
//  DataTaskService.swift
//  
//
//  Created by Markus Pfeifer on 04.06.21.
//

import Foundation
import RedCat


public protocol NetworkHandler {
    func dataTask(with request: URLRequest,
                  completionHandler: @escaping (Result<URLSessionResponse, Error>) -> Void) -> URLDataTask
}

public protocol URLDataTask {
    func resume()
    func cancel()
}

public struct URLSessionResponse {
    public let status : URLResponse
    public let data : Data
}

extension URLSessionDataTask : URLDataTask {}

extension URLSession : NetworkHandler {
    
    public func dataTask(with request: URLRequest,
                         completionHandler: @escaping (Result<URLSessionResponse, Error>) -> Void) -> URLDataTask {
        dataTask(with: request){data, response, error in
            
            completionHandler(data.flatMap{data in
                response.map{URLSessionResponse(status: $0,
                                                data: data)}
                    .map(Result.success)
            } ?? .failure(error ?? UnknownError()))
            
        }
    }
    
}

public protocol URLRequestProtocol {
    func dataTask(networkHandler: NetworkHandler,
                  completion: @escaping (Result<URLSessionResponse, Error>) -> Void) -> URLDataTask
}

extension URLRequest : URLRequestProtocol {
    public func dataTask(networkHandler: NetworkHandler,
                         completion: @escaping (Result<URLSessionResponse, Error>) -> Void) -> URLDataTask {
        networkHandler.dataTask(with: self, completionHandler: completion)
    }
}

public protocol APIHandler {
    
    associatedtype Request : Equatable
    associatedtype URLRequestType : URLRequestProtocol
    associatedtype Response
    
    func onRequest(_ request: Request) -> URLRequestType
    func onSuccess(_ response: URLSessionResponse, request: Request) -> Response
    func onFailure(_ failure: Error, request: Request) -> Response
    
}


public struct MapAPIHandler<Base : APIHandler, NewResponse> : APIHandler {
    
    @usableFromInline
    let base : Base
    @usableFromInline
    let transform : (Base.Response) -> NewResponse
    
    @inlinable
    public func onRequest(_ request: Base.Request) -> Base.URLRequestType {
        base.onRequest(request)
    }
    
    @inlinable
    public func onSuccess(_ response: URLSessionResponse, request: Base.Request) -> NewResponse {
        transform(base.onSuccess(response, request: request))
    }
    
    @inlinable
    public func onFailure(_ failure: Error, request: Base.Request) -> NewResponse {
        transform(base.onFailure(failure, request: request))
    }
    
}

public extension APIHandler {
    
    func map<NewResponse>(_ transform: @escaping (Response) -> NewResponse) -> MapAPIHandler<Self, NewResponse> {
        MapAPIHandler(base: self, transform: transform)
    }
    
}


public final class APIService<Whole, Orchestration : APIHandler> :
DetailService<Whole, Orchestration.Request?, Orchestration.Response> {
    
    let orchestration : Orchestration
    var lastRequest : (value: Orchestration.Request, handler: URLDataTask)?
    
    public init(_ orchestration: Orchestration,
                detail: @escaping (Whole) -> Orchestration.Request) {
        self.orchestration = orchestration
        super.init(detail: detail)
    }
    
    public override func onUpdate(newValue: Orchestration.Request?,
                                  store: Store<Whole, Orchestration.Response>,
                                  environment: Dependencies) {
        
        lastRequest?.handler.cancel()
        lastRequest = nil
        
        guard let request = newValue else {return}
        
        let requestHandler = orchestration.onRequest(request)
            .dataTask(networkHandler: environment.native.networkHandler) {
            result in
            DispatchQueue.main.async {
                guard self.lastRequest?.value == request else {return}
                switch result {
                case .success(let response):
                    store.send(self.orchestration.onSuccess(response, request: request))
                case .failure(let error):
                    store.send(self.orchestration.onFailure(error, request: request))
                }
            }
        }
        
        lastRequest = (request, requestHandler)
        requestHandler.resume()
        
    }
    
}

