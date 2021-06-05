//
//  DataTaskService.swift
//  
//
//  Created by Markus Pfeifer on 04.06.21.
//

import Foundation


public enum NetworkHandler : Dependency {
    public static let defaultValue : ResolvedNetworkHandler = URLSession.shared
}

public protocol ResolvedNetworkHandler {
    func dataTask(with request: URLRequest,
                  completionHandler: @escaping (Result<URLSessionResponse, Error>) -> Void) -> URLDataTask
}

public extension Dependencies {
    var networkHandler : ResolvedNetworkHandler {
        get {self[NetworkHandler.self]}
        set {self[NetworkHandler.self] = newValue}
    }
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

extension URLSession : ResolvedNetworkHandler {
    
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
    func dataTask(networkHandler: ResolvedNetworkHandler,
                  completion: @escaping (Result<URLSessionResponse, Error>) -> Void) -> URLDataTask
}

extension URLRequest : URLRequestProtocol {
    public func dataTask(networkHandler: ResolvedNetworkHandler,
                         completion: @escaping (Result<URLSessionResponse, Error>) -> Void) -> URLDataTask {
        networkHandler.dataTask(with: self, completionHandler: completion)
    }
}

public protocol APIHandler {
    
    associatedtype Request : Equatable
    associatedtype URLRequestType : URLRequestProtocol
    associatedtype Success : ActionProtocol
    associatedtype Failure : ActionProtocol
    
    func onRequest(_ request: Request) -> URLRequestType
    func onSuccess(_ response: URLSessionResponse, request: Request) -> Success
    func onFailure(_ failure: Error, request: Request) -> Failure
    
}


public final class APIService<Whole, Orchestration : APIHandler> :
    DetailService<Whole, Orchestration.Request?> {
    
    let orchestration : Orchestration
    var lastRequest : (value: Orchestration.Request, handler: URLDataTask)?
    
    public init(_ orchestration: Orchestration,
                detail: @escaping (Whole) -> Orchestration.Request) {
        self.orchestration = orchestration
        super.init(detail: detail)
    }
    
    public override func onUpdate(newValue: Orchestration.Request?,
                                  store: Store<Whole>,
                                  environment: Dependencies) {
        
        lastRequest?.handler.cancel()
        lastRequest = nil
        
        guard let request = newValue else {return}
        
        let requestHandler = orchestration.onRequest(request)
            .dataTask(networkHandler: environment.networkHandler) {
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

