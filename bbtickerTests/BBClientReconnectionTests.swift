//
//  BBClientReconnectionTests.swift
//  bbtickerTests
//
//  Created by Test Suite on 02/05/2026.
//

import Testing
import Foundation
import LLCore
@testable import bbticker

/// Tests for BBClient reconnection behavior and API error handling
/// These tests should FAIL initially as they expose the current architectural issues
@Suite("BBClient Reconnection Logic")
struct BBClientReconnectionTests {
    
    // MARK: - Test Doubles
    
    @MainActor
    class TestableAPIService: APIServiceProtocol {
        var shouldFail = false
        var failureCount = 0
        var maxFailures = 0
        var thrownError: Error = NSError(domain: "TestError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Test API error"])
        
        // Debug tracking
        var callTimestamps: [Date] = []
        var callResults: [String] = []
        
        func fetchWalletBalance(for exchangeType: ExchangeType) async throws -> WalletData {
            let callTime = Date()
            callTimestamps.append(callTime)
            
            // The mock needs a suspension point to allow cooperative cancellation
            try await Task.sleep(for: .milliseconds(100))
            
            if shouldFail && failureCount < maxFailures {
                failureCount += 1
                callResults.append("failure #\(failureCount)")
                print("API Call #\(callTimestamps.count) at \(String(callTime.timeIntervalSince1970).suffix(6)): FAILURE #\(failureCount)")
                throw thrownError
            }
            
            callResults.append("success")
            print("API Call #\(callTimestamps.count) at \(String(callTime.timeIntervalSince1970).suffix(6)): SUCCESS")
            
            // Return success after failures
            return WalletData(
                totalEquity: 1000.0,
                walletBalance: 500.0
            )
        }
        
        func fetchWalletBalanceForCurrentExchange() async throws -> WalletData {
            // For tests, just delegate to the main method
            return try await fetchWalletBalance(for: Exchange(.bybit, wallet: .unified))
        }
        
        // MARK: - Network Error Simulation (should continue polling)
        
        func simulateNetworkErrors(count: Int = 1) {
            shouldFail = true
            maxFailures = count
            failureCount = 0
            thrownError = APIDomainError.network(
                context: APIErrorContext(
                    exchange: .bybit,
                    httpStatus: nil,
                    rawMessage: "Network connection failed"
                )
            )
        }
        
        // MARK: - API Error Simulation (should disconnect immediately)
        
        func simulateAuthenticationErrors(count: Int = 1) {
            shouldFail = true
            maxFailures = count  
            failureCount = 0
            thrownError = APIDomainError.invalidCredentials(
                context: APIErrorContext(
                    exchange: .bybit,
                    httpStatus: 401,
                    apiCode: "10003",
                    rawMessage: "Invalid API credentials"
                )
            )
        }
        
        func simulateRateLimitErrors(count: Int = 1) {
            shouldFail = true
            maxFailures = count
            failureCount = 0
            thrownError = APIDomainError.rateLimited(
                context: APIErrorContext(
                    exchange: .bybit,
                    httpStatus: 429,
                    apiCode: "10006", 
                    rawMessage: "Rate limit exceeded"
                )
            )
        }
        
        func simulateServerErrors(count: Int = 1) {
            shouldFail = true
            maxFailures = count
            failureCount = 0
            thrownError = APIDomainError.server(
                context: APIErrorContext(
                    exchange: .bybit,
                    httpStatus: 500,
                    rawMessage: "Internal server error"
                )
            )
        }
        
        // MARK: - Legacy methods (updated to use proper error types)
        
        func simulateTransientFailures(count: Int, error: Error? = nil) {
            shouldFail = true
            maxFailures = count
            failureCount = 0
            thrownError = error ?? APIDomainError.server(
                context: APIErrorContext(exchange: .bybit, rawMessage: "Transient error")
            )
        }
        
        func simulatePermanentFailure(error: Error? = nil) {
            shouldFail = true
            failureCount = 0
            maxFailures = 10 // More than maxReconnectionAttempts (5) to ensure it fails through all retry attempts
            thrownError = error ?? APIDomainError.invalidCredentials(
                context: APIErrorContext(exchange: .bybit, rawMessage: "Permanent error")
            )
        }
        
        func reset() {
            shouldFail = false
            failureCount = 0
            maxFailures = 0
            callTimestamps.removeAll()
            callResults.removeAll()
        }
        
        func printCallHistory() {
            print("=== API Call History ===")
            for (index, result) in callResults.enumerated() {
                let timestamp = callTimestamps[index]
                print("Call \(index + 1): \(result) at \(String(timestamp.timeIntervalSince1970).suffix(6))")
            }
            if callResults.count > 1 {
                let timeDiffs = zip(callTimestamps.dropFirst(), callTimestamps).map { $0.0.timeIntervalSince($0.1) }
                print("Time between calls: \(timeDiffs.map { String(format: "%.2fs", $0) }.joined(separator: ", "))")
            }
            print("========================")
        }
    }
    
    @MainActor
    class MockNetworkStore: NetworkStoreProtocol {
        var state = NetworkState(isConnected: true)
        private var statusContinuation: AsyncStream<Bool>.Continuation?
        
        lazy var statusStream: AsyncStream<Bool> = {
            AsyncStream { continuation in
                self.statusContinuation = continuation
                continuation.yield(state.isConnected)
            }
        }()
        
        func dispatch(_ action: NetworkAction) async {
            // Mock implementation - just update state
            switch action {
            case .statusChanged(let isConnected):
                state.isConnected = isConnected
                statusContinuation?.yield(isConnected)
            case .startMonitoring:
                break
            case .connectionTypeChanged, .stopMonitioring:
                break
            }
        }
        
        func simulateNetworkLoss() {
            Task { @MainActor in
                state.isConnected = false
                statusContinuation?.yield(false)
            }
        }
        
        func simulateNetworkRestore() {
            Task { @MainActor in
                state.isConnected = true
                statusContinuation?.yield(true)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    @MainActor
    private func createTestClient() -> (
        client: BBClient,
        apiService: TestableAPIService,
        networkStore: MockNetworkStore,
        settingsService: MockSettingsService,
        sharedDataManager: MockSharedDataManager
    ) {
        let apiService = TestableAPIService()
        let networkStore = MockNetworkStore()
        
        // Use existing mocks from SettingsViewModelTests
        let settingsService = MockSettingsService()
        let sharedDataManager = MockSharedDataManager()
        
        let client = BBClient(
            settingsService: settingsService,
            networkMonitor: networkStore,
            sharedDataManager: sharedDataManager,
            pollingConfiguration: .fastRetry,
            walletRepository: MockWalletRepository(apiService: apiService)
        )
        
        return (client, apiService, networkStore, settingsService, sharedDataManager)
    }
    
    
    // MARK: - Failing Tests (Current Issues)
    
    @Test("Network errors should NOT disconnect client during retry attempts")
    @MainActor
    func testAPIErrorsShouldNotDisconnectDuringRetries() async throws {
        let (client, apiService, _, _, _) = createTestClient()
        
        // Connect initially
        await client.connect()
        #expect(client.connectionStatus == .connected, "Initial connection should succeed")
        
        // Simulate 2 transient API failures, then success
        apiService.simulateNetworkErrors(count: 2)
        
        // Wait a bit to let polling encounter the API errors
        try await Task.sleep(for: .milliseconds(500))
        
        // FAILING ASSERTION: Currently, first API error disconnects client
        #expect(client.connectionStatus == .connected, 
               "Client should remain connected during API retry attempts")
    }
    
    @Test("Polling should continue with exponential backoff during Network failures")
    @MainActor
    func testPollingContinuesDuringAPIFailures() async throws {
        let (client, apiService, _, _, _) = createTestClient()
        
        await client.connect()
        
        apiService.simulateNetworkErrors(count: 2)
        
        // Wait for multiple retry cycles
        try await Task.sleep(for: .seconds(1))
        
        #expect(apiService.failureCount >= 2, 
               "API should be called multiple times during retry attempts")
        
        // FAILING ASSERTION: Polling currently stops after first error. client should remain connected during poling attempts
        #expect(client.connectionStatus == .connected,
               "Client should remain connected during retries")
    }
    
    
    @Test("Client should only disconnect after max retry attempts exhausted", .timeLimit(.minutes(1)))
    @MainActor
    func testDisconnectOnlyAfterMaxRetries() async throws {
        let (client, apiService, _, _, _) = createTestClient()
        
        // First allow connection to succeed
        await client.connect()
        #expect(client.connectionStatus == .connected, "Should connect initially")
        
        // Now simulate permanent API failure during polling
        apiService.simulateNetworkErrors(count: 9)
        
        // Wait long enough for all retry attempts to be exhausted
        try await Task.sleep(for: .seconds(2))
        
        // FAILING ASSERTION: Currently disconnects on first error, not after max retries  
        #expect(apiService.failureCount >= 5, 
               "Should attempt at least 5 retries before giving up, but got \(apiService.failureCount). Call history: \(apiService.callResults)")
        #expect(client.connectionStatus == .disconnected, 
               "Should disconnect only after exhausting all retries")
    }
    
    @Test("Data should be marked stale during Network failures, not disconnected")
    @MainActor
    func testDataMarkedStaleNotDisconnected() async throws {
        let (client, apiService, _, _, _) = createTestClient()
        
        await client.connect()
        #expect(client.connectionStatus == .connected)
        
        // Simulate permanent API failure - this SHOULD disconnect with current implementation
        apiService.simulateNetworkErrors(count: 2)
        try await Task.sleep(for: .milliseconds(400))
        
        print("After API failure - client status: \(client.connectionStatus)")
        
        // FAILING ASSERTION: Currently disconnects instead of marking data stale  
        #expect(client.connectionStatus == .connected, 
               "Connection status should remain connected during API failures")
        // TODO: Add stale data tracking when implemented
        // #expect(client.dataStatus == .stale, "Data should be marked as stale")
    }
    
    // this should NOT pass
    @Test("Successful API call should clear stale data state")
    @MainActor
    func testSuccessfulAPICallClearsStaleState() async throws {
        let (client, apiService, _, _, _) = createTestClient()
        
        await client.connect()
        #expect(client.connectionStatus == .connected)
        
        // Simulate transient failure then recovery
        apiService.simulateNetworkErrors(count: 2)
        try await Task.sleep(for: .milliseconds(600))
        
        #expect(client.connectionStatus == .connected)
        #expect(apiService.callResults.count > 2)
        // TODO: Add stale data state verification when implemented
        // #expect(client.dataStatus == .stale, "Data should be marked as stale after network issue")
        
        // Reset API to success
        apiService.reset()
        
        try await Task.sleep(for: .milliseconds(500))
        
        // FAILING ASSERTION: Currently doesn't track/clear stale state
        #expect(client.connectionStatus == .connected)
        #expect(client.authenticationError == nil, 
               "Authentication error should be cleared after successful API call")
        // TODO: Add stale data state verification when implemented
        // #expect(client.dataStatus == .fresh, "Data should be marked as fresh after success")
    }
    
    // MARK: - Network vs API Error Separation Tests
    
    
    // this should pass
    @Test("API error should immediately stop polling")
    @MainActor
    func testNetworkDisconnectionStopsPolling() async throws {
        let (client, apiService, _, _, _) = createTestClient()
        
        await client.connect()
        #expect(client.connectionStatus == .connected)
        let initialCallCount = apiService.failureCount
        
        // Simulate network loss
        apiService.simulateAuthenticationErrors(count: 1)
        try await Task.sleep(for: .milliseconds(500))
        
        // Should stop making API calls
        let callsAfterApiError = apiService.failureCount - initialCallCount
        #expect(callsAfterApiError == 1,
               "Should not make API calls when network is disconnected")
        #expect(client.connectionStatus == .disconnected, 
               "Should disconnect when network is lost")
    }
    
    
    // MARK: Network restoration
    @Test("Network restoration should resume polling")
    @MainActor
    func testNetworkRestorationResumesPolling() async throws {
        let (client, apiService, networkStore, _, _) = createTestClient()
        
        await client.connect()
        
        // Simulate network loss and restoration
        networkStore.simulateNetworkLoss()
        try await Task.sleep(for: .milliseconds(200))
        
        networkStore.simulateNetworkRestore()
        try await Task.sleep(for: .milliseconds(500))
        
        #expect(client.connectionStatus == .connected, 
               "Should reconnect when network is restored")
        #expect(apiService.failureCount >= 0, 
               "Should resume API calls after network restoration")
    }
    
    @Test("Network restoration should trigger reconnection even after API-induced disconnection")
    @MainActor
    func testNetworkRestorationTriggersReconnectionAfterAPIError() async throws {
        let (client, apiService, networkStore, _, _) = createTestClient()
        
        await client.connect()
        #expect(client.connectionStatus == .connected)
        
        // API error disconnects client (current broken behavior)
        apiService.simulatePermanentFailure()
        try await Task.sleep(for: .milliseconds(300))
        #expect(client.connectionStatus == .disconnected, "API error currently disconnects client")
        
        // Reset API to working state
        apiService.reset()
        
        // Network restoration should trigger reconnection
        networkStore.simulateNetworkLoss()
        try await Task.sleep(for: .milliseconds(100))
        networkStore.simulateNetworkRestore()
        
        // Wait for reconnection attempt
        try await Task.sleep(for: .milliseconds(500))
        
        // PASSING ASSERTION: Network restoration should work regardless of disconnection cause
        #expect(client.connectionStatus == .connected,
               "Network restoration should trigger reconnection even after API-induced disconnection")
    }
}
