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
    let registry: ExchangeRegistryProtocol
    
    @MainActor
    func make<E: Endpoint>(for exchange: Exchange,
                         exchangeConfiguration: ExchangeConfiguration,
                                      endpoint: E,
                                   credentials: Credentials,
                                networkService: LLNetworkServiceProtocol) throws -> LLApiService<E.Output> {
        
        guard let requestBuilder = registry.requestBuilder(for: exchange.identifier, configuration: exchangeConfiguration, credentials: credentials, endpointType: endpoint.id) else {
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
