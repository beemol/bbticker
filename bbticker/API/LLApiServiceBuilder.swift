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
                     networkService: LLNetworkServiceProtocol) async throws -> LLApiService<T> {
        
        let registry = exchange.registry
        
        guard let requestBuilder = registry.requestBuilder(for: exchange, credentials: credentials) else {
            throw APIError.invalidRequest
        }
        
        guard let parser: any LLResponseParserProtocol<T> = registry.parser(for: exchange.identifier, endpointType: endpointType) else {
            throw APIError.invalidRequest
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
