//
//  NetworkService.swift
//
//
//  Created by Vsevolod Pavlovskyi on 19.03.2021.
//

import Foundation
import SwiftyBeaver

let log = SwiftyBeaver.self

public final class NetworkService: NetworkProvider {
    
    private var _defaultHeaders: [String: String]
    public var defaultHeaders: [String: String] {
        _defaultHeaders
    }
    
    private var _successfulStatusCodes = 200..<300
    public var successfulStatusCodes: Range<Int> {
        _successfulStatusCodes
    }
    
    private var _authorization: String?
    public var authorization: String? {
        _authorization
    }
    
    public var session: URLSessionProvider = URLSession.shared

    public init(defaultHeaders: [String: String] = [:]) {

        let platform = SBPlatformDestination(appID: "Gw3AJo",
                                             appSecret: "afxsclzQ9qhnltomqgiu2vxlgc0rqwoc",
                                             encryptionKey: "cWtgjh7gtqdkhplpwlKvrigmTDwraUof")

        log.addDestination(platform)

        log.verbose("Initializing Network Service")
        self._defaultHeaders = defaultHeaders
    }

}

public extension NetworkService {
    
    func setHeader(_ value: String, forKey key: String) {
        log.info("Setting header: (\(key): \(value))")
        _defaultHeaders[key] = value
    }
    
    func removeHeader(forKey key: String) {
        log.info("Removing header \(key)")
        _defaultHeaders.removeValue(forKey: key)
    }
    
    func setAuthorization(_ authorization: String) {
        log.info("Setting authorization")
        _authorization = authorization
    }
    
    func clearAuthorization() {
        log.info("Clear authorization")
        _authorization = nil
    }

    func setSuccessfulStatusCodes(_ range: Range<Int>) {

        let lowerBound = range.lowerBound >= 100 ? range.lowerBound : 100
        let upperBound = range.upperBound <= 600 ? range.upperBound : 600
        
        _successfulStatusCodes = lowerBound..<upperBound
    }
    
    func performRequest<T: Decodable>(for resource: Resource,
                           decodingTo type: T.Type,
                           completion: @escaping (Result<T, NetworkError>) -> ()) {
        
        log.verbose("Performing request for url: \(resource.url), decoding to \(T.self)")
        
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
        
        log.verbose("Performing data request for url: \(resource)")
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
        
        if let authorization = authorization {
            request.addValue(authorization,
                             forHTTPHeaderField: "Authorization")
        }

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
        
        log.verbose("Decoding data...")
        data.decode(type: T.self) { result in
            switch result {
            case .success(let object):
                completion(.success(object))
                log.verbose("Successfully decoded")
            case .failure(let error):
                completion(.failure(.decodingError(error)))
                log.error(error.localizedDescription)
            }
        }
    }

}
