//
//  URLSessionProvider.swift
//  
//
//  Created by Vsevolod Pavlovskyi on 19.03.2021.
//

import Foundation

public protocol URLSessionProvider {

    typealias DataTaskResult = (Data?,
                                URLResponse?,
                                Error?) -> Void
    
    func dataTask(with request: URLRequest,
                  completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProvider

}

public protocol URLSessionDataTaskProvider {

    func resume()

}

extension URLSession: URLSessionProvider {

    public func dataTask(with request: URLRequest,
                         completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProvider {
        
        return dataTask(with: request, completionHandler: completionHandler) as URLSessionDataTask
    }

}

extension URLSessionDataTask: URLSessionDataTaskProvider {}
