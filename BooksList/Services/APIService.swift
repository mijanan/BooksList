//
//  APIService.swift
//  BooksList
//
//  Created by Janarthanan Mirunalini on 12/08/24.
//

import Foundation
import Combine
import UIKit

enum ResponseError: Error {
    case invalidURL
    case invalidData
    case invalidResponse
    case message(_ error: Error?)
}

class APIService {
    
            
    
    func fetch<T: Decodable>(url: String, enableCache: Bool = true) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            getResponseFrom(urlString: url, enableCache: enableCache) {[weak self] response in
                
                guard let _ = self else {
                    // if `result` doesn't have the expected value, the continuation
                    // will never report completion
                    return
                }
                
                switch response {
                    case .success(let data):
                        do {
                            let books = try JSONDecoder().decode(T.self, from: data)
                            continuation.resume(with: .success(books))
                        }catch {
                            debugPrint("Books data parsing error...", error.localizedDescription)
                        }
                    
                    case .failure(let error):
                        debugPrint("Books response error...", error.localizedDescription)

                    
                }
    
            }
        }

    }
    

    
    func fetchImageFrom(url: String, enableCache: Bool = true) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            getResponseFrom(urlString: url, enableCache: enableCache) {[weak self] response in
                
                guard let _ = self else {
                    // if `result` doesn't have the expected value, the continuation
                    // will never report completion
                    return
                }
                
                switch response {
                    case .success(let data):
                    
                        if let image = UIImage(data: data) {
                            continuation.resume(with: .success(image))
                        }
                        else {
                            debugPrint("Image data building error...")

                        }
                    
                    
                    case .failure(let error):
                        debugPrint("Books response error...", error.localizedDescription)

                    
                }
            }
        }

    }

    

    
    func getResponseFrom(urlString: String, enableCache: Bool, completion: @escaping (Result<Data, Error>) -> Void) {
        
        
        let sessionConfiguration = URLSessionConfiguration.default
        let memoryCapacity = 20 * 1024 * 1024 //20 MB
        let diskCapacity = 100 * 1024 * 1024  //100 MB
        let cache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity)

        sessionConfiguration.urlCache = cache
        sessionConfiguration.requestCachePolicy = .returnCacheDataElseLoad
        
        
        let session = URLSession(configuration: sessionConfiguration)
        
        guard let url = URL(string: urlString) else {
            completion(.failure(ResponseError.invalidURL))
            return
        }
        
        // Check if there's a cached response first
        if enableCache, let cachedResponse = cache.cachedResponse(for: URLRequest(url: url)) {
            // Use the cached data
            let data = cachedResponse.data
            completion(.success(data))
            // Handle the cached response data
            // For example: parse JSON, update UI, etc.
        } else  {
            session.dataTask(with: url) { data, response, error in
                
              //  print("Response error...", error)
 
                if error != nil {
                    completion(.failure(ResponseError.message(error)))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(ResponseError.invalidData))
                    return
                }
                
                guard let response = response as? HTTPURLResponse, 200...299 ~= response.statusCode else {
                    completion(.failure(ResponseError.invalidResponse))
                    return
                }
                completion(.success(data))
                
            }.resume()
        }
    }

}

