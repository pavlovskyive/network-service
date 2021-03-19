//
//  NetworkError.swift
//  
//
//  Created by Vsevolod Pavlovskyi on 19.03.2021.
//

import Foundation

public enum NetworkError: Error {
    
    case dataTaskError(Error)
    case responseError
    case badData
    
    case invalidStatusCodeRange
    case badStatusCode(Int)
    case decodingError(Error)
}
