//
//  WalletRepositoryProtocol.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 28/05/2026.
//

import Foundation
import LLCore

protocol WalletRepositoryProtocol: Sendable {
    func getWalletData(for exchangeType: ExchangeType) async throws -> WalletData
    func getApiKeyInfo(for exchangeType: ExchangeType) async throws -> ApiKeyInfo
}

@MainActor
final class WalletRepository: WalletRepositoryProtocol {
    
    private let credentialManager: CredentialManagerProtocol
    private let apiService: APIServiceProtocol
    
    init(credentialManager: CredentialManagerProtocol,
         apiService: APIServiceProtocol) {
        self.credentialManager = credentialManager
        self.apiService = apiService
    }
    
    func getWalletData(for exchangeType: ExchangeType) async throws -> WalletData {
        let credentials = try await credentialManager.getCredentials(forAccount: exchangeType.envIDString)
        
        if credentials.apiKey.isEmpty || credentials.apiSecret.isEmpty {
            throw APIDomainError.missingOrInvalidParams(context: APIErrorContext(exchange: exchangeType.identifier))
        }
        
        return try await apiService.fetchWalletBalance(for: exchangeType)
    }
    
    func getApiKeyInfo(for exchangeType: ExchangeType) async throws -> ApiKeyInfo {
        let credentials = try await credentialManager.getCredentials(forAccount: exchangeType.envIDString)
        
        if credentials.apiKey.isEmpty || credentials.apiSecret.isEmpty {
            throw APIDomainError.missingOrInvalidParams(context: APIErrorContext(exchange: exchangeType.identifier))
        }
        
        let data = try await apiService.fetchApiKeyInfo(for: exchangeType)
        return data
    }
}
