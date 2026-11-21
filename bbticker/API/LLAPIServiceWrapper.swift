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
    init(registry: ExchangeRegistryProtocol, credentialManager: CredentialManagerProtocol, settingsService: any SettingsServiceProtocol, urlSession: URLSessionProtocol) {
        self.credentialManager = credentialManager
        self.settingsService = settingsService
        self.urlSession = urlSession
        self.registry = registry
    }
    
    let registry: ExchangeRegistryProtocol
    
    private let credentialManager: CredentialManagerProtocol
    private let settingsService: any SettingsServiceProtocol
    private let urlSession: URLSessionProtocol
    
    private func getService<E: Endpoint>(for exchange: Exchange,
                            endpoint: E,
                            credentials: Credentials) throws -> LLApiService<E.Output> {

        guard let configuration = registry.configuration(for: exchange) else { throw APIError.invalidRequest }
        
        return try LLApiServiceBuilder(registry: registry).make(
            for: exchange,
            exchangeConfiguration: configuration,
            endpoint: endpoint,
            credentials: credentials,
            networkService: LLNetworkService(urlSession: urlSession))
    }
    
    func fetchApiKeyInfo(for exchange: LLCore.Exchange) async throws -> any ApiKeyInfo {
        let endpointString = "api-key-info"
        
        do {
            let endpoint = APIKeyInfoEndpoint()
            let account = exchange.envIDString
            let credentials = try await credentialManager.getCredentials(forAccount: account)
            
            let service = try getService(for: exchange, endpoint: endpoint, credentials: credentials)
            let apiKeyInfo = try await service.execute()
            
            // Track success, but do not block result
            Task.detached {
                await AnalyticsManager.shared.track(.apiSuccess(endpoint: endpointString))
            }
            return apiKeyInfo
            
        } catch let domainError as APIDomainError {
            // Domain error from error detector (HTTP or application-level)
            AppLog.api.error("Domain error: \(domainError.userMessage)")
            await AnalyticsManager.shared.track(.apiFailure(
                endpoint: endpointString,
                error: "domain_\(domainError.context.apiCode ?? "unknown")"
            ))
            throw domainError
            
        } catch let apiError as APIError {
            // Simple API error (parse error, invalid request, etc.)
            AppLog.api.error("API error: \(apiError.localizedDescription)")
            await AnalyticsManager.shared.track(.apiFailure(
                endpoint: endpointString,
                error: "api_\(apiError.localizedDescription)"
            ))
            throw apiError
            
        } catch {
            // Network or unknown error - map to domain error
            AppLog.api.error("Network error: \(error.localizedDescription)")
            await AnalyticsManager.shared.track(.apiFailure(
                endpoint: endpointString,
                error: error.localizedDescription
            ))
            
            let mapped = APIErrorMapper.mapNetworkError(
                error,
                exchange: exchange.identifier,
                endpoint: endpointString
            )
            throw mapped
        }
    }
    
    func fetchWalletBalanceForCurrentExchange() async throws -> WalletData {
        let exchange = settingsService.state.exchange
        return try await fetchWalletBalance(for: exchange)
    }
    
    func fetchWalletBalance(for exchange: Exchange) async throws -> WalletData {
        let endpointString = "wallet-balance"
        
        do {
            let endpoint = WalletEndpoint(exchange.walletType)
            let account = exchange.envIDString
            let credentials = try await credentialManager.getCredentials(forAccount: account)
            
            let service = try getService(for: exchange, endpoint: endpoint, credentials: credentials)
            //let service = try LLApiServiceBuilder.make(for: Exchange, exchangeConfiguration: configuration, endpoint: endpoint, credentials: credentials, networkService: LLNetworkService(urlSession: urlSession))
            let walletData = try await service.execute()
            
            // Track success, but do not block result
            Task.detached {
                await AnalyticsManager.shared.track(.apiSuccess(endpoint: endpointString))
            }
            return walletData
            
        } catch let domainError as APIDomainError {
            // Domain error from error detector (HTTP or application-level)
            AppLog.api.error("Domain error: \(domainError.userMessage)")
            await AnalyticsManager.shared.track(.apiFailure(
                endpoint: endpointString,
                error: "domain_\(domainError.context.apiCode ?? "unknown")"
            ))
            throw domainError
            
        } catch let apiError as APIError {
            // Simple API error (parse error, invalid request, etc.)
            AppLog.api.error("API error: \(apiError.localizedDescription)")
            await AnalyticsManager.shared.track(.apiFailure(
                endpoint: endpointString,
                error: "api_\(apiError.localizedDescription)"
            ))
            throw apiError
            
        } catch {
            // Network or unknown error - map to domain error
            AppLog.api.error("Network error: \(error.localizedDescription)")
            await AnalyticsManager.shared.track(.apiFailure(
                endpoint: endpointString,
                error: error.localizedDescription
            ))
            
            let mapped = APIErrorMapper.mapNetworkError(
                error,
                exchange: exchange.identifier,
                endpoint: endpointString
            )
            throw mapped
        }
    }
}

