//
//  InternetReachabilityService.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 04/07/2026.
//

import Foundation

protocol InternetReachabilityServiceProtocol {
    func runProbe(urlString: String) async throws -> Bool
}

final class InternetReachabilityService: InternetReachabilityServiceProtocol {
    private let urlSession: URLSession = URLSession.shared
    
    func runProbe(urlString: String = "https://www.google.com") async throws -> Bool {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let data = try await urlSession.data(from: url)
        
        return data.0.isEmpty == false
    }
}
