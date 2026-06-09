//
//  LLAPIServiceWrapper.swift
//  bbticker
//
//  Wrapper around LLApiService that provides analytics tracking and error handling.
//  This replaces BBAPIService with a cleaner, flatter error handling approach.
//

import Foundation
import LLApiService
import LLCore

@MainActor
class LLAPIServiceWrapper: APIServiceProtocol {
    private let credentialManager: CredentialManagerProtocol
    private let settingsService: any SettingsServiceProtocol
    private let urlSession: URLSessionProtocol
    
    init(credentialManager: CredentialManagerProtocol, settingsService: any SettingsServiceProtocol, urlSession: URLSessionProtocol) {
        self.credentialManager = credentialManager
        self.settingsService = settingsService
        self.urlSession = urlSession
    }
    
    func fetchWalletBalanceForCurrentExchange() async throws -> WalletData {
        let exchangeType = settingsService.state.exchangeType
        return try await fetchWalletBalance(for: exchangeType)
    }
    
    func fetchWalletBalance(for exchangeType: ExchangeType) async throws -> WalletData {
        let endpoint = "wallet-balance"
        
        do {
            // LLApiService handles the entire error detection pipeline:
            // 1. Network request (via LLNetworkService)
            // 2. HTTP status check (via HTTPStatusErrorDetector)
            // 3. Application-level error detection (via BybitErrorDetector, etc.)
            // 4. Parsing (via WalletDataParserFactory)
            
            let endpointType = EndpointType.wallet(exchangeType.walletType)
            let service = try await LLApiServiceBuilder<WalletData>.make(for: exchangeType, endpointType: endpointType, credentials: credentialManager.getCredentials(forAccount: exchangeType.displayName), networkService: LLNetworkService(urlSession: urlSession))
            let walletData = try await service.execute()
            
            // Track success, but do not block result
            Task.detached {
                await AnalyticsManager.shared.track(.apiSuccess(endpoint: endpoint))
            }
            return walletData
            
        } catch let domainError as APIDomainError {
            // Domain error from error detector (HTTP or application-level)
            print("LLAPIServiceWrapper: Domain error: \(domainError.userMessage)")
            await AnalyticsManager.shared.track(.apiFailure(
                endpoint: endpoint,
                error: "domain_\(domainError.context.apiCode ?? "unknown")"
            ))
            throw domainError
            
        } catch let apiError as APIError {
            // Simple API error (parse error, invalid request, etc.)
            print("LLAPIServiceWrapper: API error: \(apiError.localizedDescription)")
            await AnalyticsManager.shared.track(.apiFailure(
                endpoint: endpoint,
                error: "api_\(apiError.localizedDescription)"
            ))
            throw apiError
            
        } catch {
            // Network or unknown error - map to domain error
            print("LLAPIServiceWrapper: Network error: \(error.localizedDescription)")
            await AnalyticsManager.shared.track(.apiFailure(
                endpoint: endpoint,
                error: error.localizedDescription
            ))
            
            let mapped = APIErrorMapper.mapNetworkError(
                error,
                exchange: exchangeType.identifier,
                endpoint: endpoint
            )
            throw mapped
        }
    }
}

