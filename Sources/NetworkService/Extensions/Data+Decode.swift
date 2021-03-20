//
//  File.swift
//  
//
//  Created by Vsevolod Pavlovskyi on 19.03.2021.
//

import Foundation

public extension Data {

    /// Decode data to specified type.
    ///
    /// - Parameters:
    ///   - data: Data for decoding.
    ///   - type: Specified Decodable type.
    ///   - completion: Specified type Result handler.
    func decode<T: Decodable>(type: T.Type,
                              completion: @escaping(Result<T, Error>) -> Void) {
        
        let decoder = JSONDecoder()
        
        do {
            let object = try decoder.decode(type, from: self)
            completion(.success(object))
        } catch {
            completion(.failure(error))
        }
        
    }

}
