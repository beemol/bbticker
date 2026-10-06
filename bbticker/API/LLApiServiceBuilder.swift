//
//  LLApiServiceBuilder.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 20/11/2025.
//

import Foundation
import LLApiService
import LLCore

struct LLApiServiceBuilder {
    static func make<E: Endpoint>(for exchange: ExchangeType,
                                      endpoint: E,
                                   credentials: Credentials,
                                networkService: LLNetworkServiceProtocol) throws -> LLApiService<E.Output> {
        
        let registry = exchange.registry
        
        guard let requestBuilder = registry.requestBuilder(for: exchange, credentials: credentials, endpointType: endpoint.id) else {
            throw NSError(domain: "LLApiServiceBuilder",
                                 code: 1,
                                 userInfo: [NSLocalizedDescriptionKey: "Not able to find request builder for exchange: \(exchange.identifier), endpoint: \(endpoint)"])
        }
        
        guard let parser = registry.parser(for: exchange.identifier, endpoint: endpoint) else {
            throw NSError(domain: "LLApiServiceBuilder",
                          code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Not able to find parser for exchange: \(exchange.identifier), endpoint: \(endpoint)"])
        }
        
        let errorDetector = registry.errorDetector(for: exchange.identifier)
        
        return LLApiService(
            requestBuilder: requestBuilder,
            networkService: networkService,
            errorDetector: errorDetector,
            analyticsTracker: nil,
            parser: parser
        )
    }
}
