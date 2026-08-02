//
//  WalletRepositoryTests.swift
//  bbtickerTests
//
//  Created by Aleh Fiodarau on 29/05/2026.
//

import Testing
import LLCore
@testable import bbticker

@MainActor
struct WalletRepositoryTests {
    
    let walletRepository = MockWalletRepository()
    
    lazy var bbClient = BBClient(settingsService: MockSettingsService(),
                          networkMonitor: MockNetworkStore(),
                          sharedDataManager: MockSharedDataManager(),
                          walletRepository: walletRepository)

//    @Test mutating func testBBClientHandlesAllRepositoryErrors() async throws {
//        for repositoryError in WalletRepositoryError.allCases {
//            
//            walletRepository.errorToThrow = repositoryError
//            
//            await bbClient.connect()
//            
//            // Verify BBClient handles each error appropriately
//            switch repositoryError {
//            case .noCredentials:
//                #expect(bbClient.connectionStatus == .disconnected)
//                //#expect(bbClient.authenticationError == "Missing API credentials")
//            case .noData:
//                #expect(bbClient.connectionStatus == .disconnected)
//                //#expect(bbClient.authenticationError == "API key has expired")
//            }
//        }
//    }
}

class MockWalletRepository: WalletRepositoryProtocol, @unchecked Sendable {
    var errorToThrow: Error? = nil
    
    private let apiService: APIServiceProtocol?
    private let credentialsManager: CredentialManagerProtocol?
    
    init(apiService: APIServiceProtocol? = nil, credentialsManager: CredentialManagerProtocol? = nil) {
        self.apiService = apiService
        self.credentialsManager = credentialsManager
    }
    
    func getWalletData(for exchangeType: any LLCore.ExchangeType) async throws -> LLCore.WalletData {
        if let credentialsManager = credentialsManager {
            do {
                _ = try await credentialsManager.getCredentials(forAccount: exchangeType.displayName)
            } catch {
                throw error
            }
        }
        
        if let error = errorToThrow {
            throw error
        } else if let api = apiService {
            return try await api.fetchWalletBalance(for: exchangeType)
        }
        
        return WalletData(totalEquity: 123.45, walletBalance: 54.321)
    }
}
