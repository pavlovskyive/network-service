//
//  NetworkProvider.swift
//  
//
//  Created by Vsevolod Pavlovskyi on 19.03.2021.
//

import Foundation

public protocol NetworkProvider {
    
    /// Acceptable response status codes.
    /// Status codes which are not in specified range considered erroneous.
    var successfulStatusCodes: Range<Int> { get }

    /// Defualt HTTPHeaders which will be added in every request.
    /// Overriden by per-request headers
    var defaultHeaders: [String: String] { get }
    
    var authorization: String? { get }
    
    /// Set acceptable response status codes.
    /// Status codes which are not in specified range considered erroneous.
    /// By default its 200..<300
    ///
    /// - Parameter range: 100..<600
    func setSuccessfulStatusCodes(_ range: Range<Int>)
    
    /// Performs request with data decoding.
    ///
    /// - Parameters:
    ///   - resource: resource.
    ///   - type: expected response type.
    ///   - completion: response handler.
    func performRequest<T: Decodable>(for resource: Resource,
                                      decodingTo type: T.Type,
                                      completion: @escaping (Result<T, NetworkError>) -> ())

    
    /// Performs request without data decoding.
    ///
    /// - Parameters:
    ///   - resource: resource
    ///   - completion: response handler.
    func performRequest(for resource: Resource,
                        completion: @escaping (Result<Data, NetworkError>) -> ())
    
    func setHeader(_ value: String, forKey key: String)
    func removeHeader(forKey key: String)
    
    func setAuthorization(_ authorization: String)
    func clearAuthorization()

}


