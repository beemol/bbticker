//
//  ApiKeyExpirationTests.swift
//  bbtickerTests
//
//  Created by Aleh Fiodarau on 8/5/26.
//

import Testing
import Foundation
import LLCore
@testable import bbticker

@MainActor
struct ApiKeyExpirationTests {
    
    // MARK: - Mocks
    
    struct MockApiKeyInfo: ApiKeyInfo {
        var expiredAt: Date?
        var deadlineDay: Int?
        var createdAt: Date
    }
    
    class MockWalletRepository: WalletRepositoryProtocol, @unchecked Sendable {
        var apiKeyInfoToReturn: ApiKeyInfo?
        var errorToThrow: Error?
        var getApiKeyInfoCalled = false
        var lastExchangeType: ExchangeType?

        func getWalletData(for exchangeType: ExchangeType) async throws -> WalletData {
            fatalError("getWalletData not used in these tests")
        }

        func getApiKeyInfo(for exchangeType: ExchangeType) async throws -> ApiKeyInfo {
            getApiKeyInfoCalled = true
            lastExchangeType = exchangeType
            if let error = errorToThrow {
                throw error
            }
            if let info = apiKeyInfoToReturn {
                return info
            }
            return MockApiKeyInfo(createdAt: Date())
        }
    }

    // MARK: - State Tests

    @Test func testInitialState() {
        let repository = MockWalletRepository()
        let store = ApiKeyExpirationStateStore(repository: repository)
        
        #expect(store.state.loadingState == .idle)
        #expect(store.state.info == nil)
        #expect(store.state.expirationWarnings == "")
    }

    // MARK: - Reducer Tests

    @Test func testReduceCheckExpiration() {
        let repository = MockWalletRepository()
        let store = ApiKeyExpirationStateStore(repository: repository)
        let exchange = Exchange(.bybit, wallet: .unified)
        
        let newState = store.reduce(state: store.state, action: .checkExpiration(exchange))
        
        #expect(newState.loadingState == .loading)
        #expect(newState.expirationWarnings == "")
    }

    @Test func testReduceDataLoaded() {
        let repository = MockWalletRepository()
        let store = ApiKeyExpirationStateStore(repository: repository)
        let info = MockApiKeyInfo(expiredAt: nil, deadlineDay: 30, createdAt: Date())
        
        let newState = store.reduce(state: store.state, action: .dataLoaded(info))
        
        #expect(newState.loadingState == .success)
        #expect(newState.info?.deadlineDay == 30)
    }

    @Test func testReduceLoadingFailed() {
        let repository = MockWalletRepository()
        let store = ApiKeyExpirationStateStore(repository: repository)
        let error = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Some error"])
        
        let newState = store.reduce(state: store.state, action: .loadingFailed(error))
        
        #expect(newState.loadingState == .failure)
        #expect(newState.expirationWarnings == "Some error")
    }

    // MARK: - Side Effects & Dispatch Tests

    @Test func testDispatchCheckExpirationSuccess() async throws {
        let repository = MockWalletRepository()
        let store = ApiKeyExpirationStateStore(repository: repository)
        let exchange = Exchange(.bybit, wallet: .unified)
        let info = MockApiKeyInfo(expiredAt: nil, deadlineDay: 15, createdAt: Date())
        repository.apiKeyInfoToReturn = info
        
        store.dispatch(.checkExpiration(exchange))
        
        // Wait for the async task in handleSideEffects to complete
        // We use a small delay here as handleSideEffects spawns an unstructured Task
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        
        #expect(repository.getApiKeyInfoCalled)
        #expect(store.state.loadingState == .success)
        #expect(store.state.info?.deadlineDay == 15)
    }

    @Test func testDispatchCheckExpirationFailure() async throws {
        let repository = MockWalletRepository()
        let store = ApiKeyExpirationStateStore(repository: repository)
        let exchange = Exchange(.bybit, wallet: .unified)
        repository.errorToThrow = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        
        store.dispatch(.checkExpiration(exchange))
        
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        
        #expect(repository.getApiKeyInfoCalled)
        #expect(store.state.loadingState == .failure)
        #expect(store.state.expirationWarnings == "Network error")
    }
    
    // MARK: - Border Cases

    @Test func testExpirationBorderCases() {
        let repository = MockWalletRepository()
        let store = ApiKeyExpirationStateStore(repository: repository)
        
        // Case: Expired (negative deadline)
        let expiredInfo = MockApiKeyInfo(
            expiredAt: Date().addingTimeInterval(-3600), 
            deadlineDay: -5, 
            createdAt: Date().addingTimeInterval(-100000)
        )
        let stateExpired = store.reduce(state: store.state, action: .dataLoaded(expiredInfo))
        #expect(stateExpired.info?.deadlineDay == -5)
        
        // Case: Expiring today (zero deadline)
        let todayInfo = MockApiKeyInfo(
            expiredAt: Date().addingTimeInterval(3600), 
            deadlineDay: 0, 
            createdAt: Date().addingTimeInterval(-86400)
        )
        let stateToday = store.reduce(state: store.state, action: .dataLoaded(todayInfo))
        #expect(stateToday.info?.deadlineDay == 0)

        // Case: No deadline info available (nil)
        let noDeadlineInfo = MockApiKeyInfo(
            expiredAt: nil, 
            deadlineDay: nil, 
            createdAt: Date()
        )
        let stateNoDeadline = store.reduce(state: store.state, action: .dataLoaded(noDeadlineInfo))
        #expect(stateNoDeadline.info?.deadlineDay == nil)
        
        // Case: Expiring soon (deadline < 7)
        let soonInfo = MockApiKeyInfo(
            expiredAt: Date().addingTimeInterval(86400 * 3), 
            deadlineDay: 3, 
            createdAt: Date().addingTimeInterval(-86400)
        )
        let stateSoon = store.reduce(state: store.state, action: .dataLoaded(soonInfo))
        #expect(stateSoon.info?.deadlineDay == 3)
        
        // Case: Future expiration (positive deadline >= 7)
        let futureInfo = MockApiKeyInfo(
            expiredAt: Date().addingTimeInterval(86400 * 30), 
            deadlineDay: 30, 
            createdAt: Date()
        )
        let stateFuture = store.reduce(state: store.state, action: .dataLoaded(futureInfo))
        #expect(stateFuture.info?.deadlineDay == 30)
    }
}
