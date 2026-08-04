//
//  BBAPIService.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 13/07/2025.
//

import Foundation
import CommonCrypto
import LLApiService
import LLCore

@MainActor
protocol APIServiceProtocol {
    func fetchWalletBalance(for exchangeType: ExchangeType) async throws -> WalletData
    func fetchWalletBalanceForCurrentExchange() async throws -> WalletData
    func fetchApiKeyInfo(for exchangeType: ExchangeType) async throws -> ApiKeyInfo
}

//class BBAPIService: APIServiceProtocol {
//    private let credentialManager: CredentialManagerProtocol
//    private let settingsService: any SettingsServiceProtocol
//    private let urlSession: URLSessionProtocol
//    
//    init(credentialManager: CredentialManagerProtocol, settingsService: any SettingsServiceProtocol, urlSession: URLSessionProtocol = URLSession.shared) {
//        self.credentialManager = credentialManager
//        self.settingsService = settingsService
//        self.urlSession = urlSession
//    }
//    
//    func fetchWalletBalanceForCurrentExchange() async throws -> BBWalletData {
//        let exchangeType = settingsService.state.exchangeType
//        return try await fetchWalletBalance(for: exchangeType)
//    }
//    
//    func fetchWalletBalance(for exchangeType: ExchangeType) async throws -> BBWalletData {
//        // Analytics tracking setup
//        let endpoint = "wallet-balance"
//        
//        guard let request = await APIRequestBuilderFactory.builder(for: exchangeType, creds: credentialManager)?.createWalletBalanceRequest() else {
//            AnalyticsManager.shared.track(.apiFailure(endpoint: endpoint, error: "invalid_request"))
//            throw APIError.invalidRequest
//        }
//        
//        var data: Data
//        
//        do {
//            let (responseData, response) = try await urlSession.data(for: request)
//            data = responseData
//            
//            // Debug logging for response
//            if let httpResponse = response as? HTTPURLResponse {
//                print("BBAPIService: Response status code: \(httpResponse.statusCode)")
//                // print("BBAPIService: Response headers: \(httpResponse.allHeaderFields)")
//            }
//            
//            // Check for HTTP errors and map to domain errors
//            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
//                print("BBAPIService: HTTP error - Status: \(httpResponse.statusCode)")
//                if let responseString = String(data: data, encoding: .utf8) {
//                    print("BBAPIService: Error response body: \(responseString)")
//                }
//                AnalyticsManager.shared.track(.apiFailure(endpoint: endpoint, error: "http_\(httpResponse.statusCode)"))
//                let domainError = APIErrorMapper.mapHTTPResponse(exchange: exchangeType, endpoint: endpoint, data: data, response: httpResponse)
//                throw domainError ?? APIError.invalidRequest
//            }
//            
//            // CRITICAL: Check for application-level errors in response body even with HTTP 200
//            if let responseString = String(data: data, encoding: .utf8) {
//                print("BBAPIService: Response body: \(responseString)")
//                
//                do {
//                    try AplicationErrorDetectorFactory.build(for: exchangeType)?.detectError(data: data, response: response)
//                } catch let appError as APIDomainError {
//                    print("BBAPIService: Application error detected in HTTP 200 response: \(appError)")
//                    AnalyticsManager.shared.track(.apiFailure(endpoint: endpoint, error: "app_error_\(appError.context.apiCode ?? "unknown")"))
//                    throw appError
//                } // do nothing for API error, so it can be handled later in next catch block
//            }
//        } catch {
//            print("BBAPIService: Network error: \(error.localizedDescription)")
//            
//            // If already a domain error, bubble up; otherwise map to network domain error
//            // TODO: do we really need this?
//            if let domainError = error as? APIDomainError {
//                throw domainError
//            }
//            
//            AnalyticsManager.shared.track(.apiFailure(endpoint: endpoint, error: error.localizedDescription))
//            let mapped = APIErrorMapper.mapNetworkError(error, exchange: exchangeType, endpoint: endpoint)
//            throw mapped
//        }
//        
//        // Parsing happens after successful network response and error checks
//        guard let walletData = WalletDataParserFactory.parser(for: exchangeType).parseWalletBalance(from: data) else {
//            AnalyticsManager.shared.track(.apiFailure(endpoint: endpoint, error: "parse_error"))
//            throw APIError.parseError
//        }
//        
//        AnalyticsManager.shared.track(.apiSuccess(endpoint: endpoint))
//        return walletData
//    }
//}
