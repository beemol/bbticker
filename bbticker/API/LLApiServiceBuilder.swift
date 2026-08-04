//
//  LLApiServiceBuilder.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 20/11/2025.
//

import Foundation
import LLApiService
import LLCore

struct LLApiServiceBuilder<T> {
    static func make(for exchange: ExchangeType,
                     endpointType: EndpointType,
                     credentials: Credentials,
                     networkService: LLNetworkServiceProtocol) throws -> LLApiService<T> {
        
        let registry = exchange.registry
        
        guard let requestBuilder = registry.requestBuilder(for: exchange, credentials: credentials, endpointType: endpointType) else {
            throw NSError(domain: "LLApiServiceBuilder",
                                 code: 1,
                                 userInfo: [NSLocalizedDescriptionKey: "Not able to find request builder for exchange: \(exchange.identifier), endpoint: \(endpointType)"])
        }
        
        guard let parser: any LLResponseParserProtocol<T> = registry.parser(for: exchange.identifier, endpointType: endpointType) else {
            throw NSError(domain: "LLApiServiceBuilder",
                          code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Not able to find parser for exchange: \(exchange.identifier), endpoint: \(endpointType)"])
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
