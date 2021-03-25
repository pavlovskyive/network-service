//
//  NetworkService.swift
//
//
//  Created by Vsevolod Pavlovskyi on 19.03.2021.
//

import Foundation

public final class NetworkService: NetworkProvider {
    
    private var _defaultHeaders: [String: String]
    public var defaultHeaders: [String: String] {
        _defaultHeaders
    }
    
    private var _successfulStatusCodes = 200..<300
    public var successfulStatusCodes: Range<Int> {
        _successfulStatusCodes
    }
    
    public var session: URLSessionProvider = URLSession.shared

    public init(defaultHeaders: [String: String] = [:]) {
        self._defaultHeaders = defaultHeaders
    }

}

public extension NetworkService {
    
    func setHeader(_ value: String, forKey key: String) {
        _defaultHeaders[key] = value
    }
    
    func removeHeader(forKey key: String) {
        _defaultHeaders.removeValue(forKey: key)
    }

    func setSuccessfulStatusCodes(_ range: Range<Int>) {

        let lowerBound = range.lowerBound >= 100 ? range.lowerBound : 100
        let upperBound = range.upperBound <= 600 ? range.upperBound : 600
        
        _successfulStatusCodes = lowerBound..<upperBound
    }
    
    func performRequest<T: Decodable>(for resource: Resource,
                           decodingTo type: T.Type,
                           completion: @escaping (Result<T, NetworkError>) -> ()) {
        
        performRequest(for: resource) { [weak self] result in
            switch result {
            case .success(let data):
                self?.decode(data: data, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func performRequest(for resource: Resource,
                        completion: @escaping (Result<Data, NetworkError>) -> ()) {
        
        let request = createRequest(for: resource)
        executeRequest(request: request, completion: completion)
    }

}

internal extension NetworkService {

    /// Creates request from Resource instance
    ///
    /// - Parameter resource: Resource instance which holds the necessary information for performing a request.
    /// - Returns: Request that will be used by Resource interface for performing a network request.
    func createRequest(for resource: Resource) -> URLRequest {
        
        var request = URLRequest(url: resource.url)

        request.httpMethod = resource.method.rawValue

        let headers = defaultHeaders.merging(resource.headers,
                                             uniquingKeysWith: { (_, new) in new })
        request.allHTTPHeaderFields = headers

        request.httpBody = resource.body

        return request
    }

    /// Executes request.
    ///
    /// - Parameters:
    ///   - request: Configured URLRequest instance.
    ///   - completion: Data Result handler.
    /// - Returns: Void
    func executeRequest(request: URLRequest,
                        completion: @escaping (Result<Data, NetworkError>) -> ()) {
        
        let task = session.dataTask(with: request) { (data, response, error) in
            
            if let error = error {
                completion(.failure(.dataTaskError(error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                
                completion(.failure(.responseError))
                return
            }
            
            let statusCode = httpResponse.statusCode
            
            guard self.successfulStatusCodes.contains(statusCode) else {
                
                completion(.failure(.badStatusCode(statusCode)))
                return
            }

            guard let data = data else {

                completion(.failure(.badData))
                return
            }

            completion(.success(data))
        }

        task.resume()
    }
    
    /// Decode data to specified type.
    ///
    /// - Parameters:
    ///   - data: Data for decoding.
    ///   - completion: Specified type Result handler.
    func decode<T: Decodable>(data: Data,
                              completion: @escaping (Result<T, NetworkError>) -> ()) {
        
        data.decode(type: T.self) { result in
            switch result {
            case .success(let object):
                completion(.success(object))
            case .failure(let error):
                completion(.failure(.decodingError(error)))
            }
        }
    }

}
