//
//  File.swift
//  
//
//  Created by Vsevolod Pavlovskyi on 19.03.2021.
//

import Foundation

/// Resource holds all the necessary information for performing a request.
public struct Resource {
    
    var method: HTTPMethod
    var url: URL
    var body: Data?
    var headers: [String: String]
    
    public init(method: HTTPMethod,
         url: URL,
         body: Data? = nil,
         headers: [String: String] = [:]) {
        
        if method == .get && body != nil {
            fatalError("GET method must not have a body")
        }
        
        self.method = method
        self.url = url
        self.body = body
        self.headers = headers
    }

}
