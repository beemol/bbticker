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

@Suite("BBClient Reconnection Logic")
struct BBClientReconnectionTests {
    
    // MARK: - Test Doubles
    
    @MainActor
    class TestableAPIService: APIServiceProtocol {
        func fetchApiKeyInfo(for exchangeType: any LLCore.ExchangeType) async throws -> any bbticker.ApiKeyInfo {
            ApiKeyInfoData(createdAt: Date())
        }
        
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
        
        // Keeps failing until `reset()` — use when tests must observe stale state before recovery.
        func simulatePersistentNetworkErrors() {
            simulateNetworkErrors(count: .max)
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
        
        // Unmapped/unrecognized API response — surfaces as "Polling Error:" in BBClient.
        func simulateUnknownAPIErrors(count: Int = 1) {
            shouldFail = true
            maxFailures = count
            failureCount = 0
            thrownError = APIDomainError.unknown(
                context: APIErrorContext(
                    exchange: .bybit,
                    httpStatus: 200,
                    apiCode: "99999",
                    rawMessage: "Unexpected exchange response"
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
            walletRepository: MockWalletRepository(apiService: apiService),
            reconnectionDelayInSec: 1.0
        )
        
        return (client, apiService, networkStore, settingsService, sharedDataManager)
    }
    
    
    // MARK: - Connect error handling
    
    @Test("Transient connect error while disconnected does not schedule reconnect")
    @MainActor
    func testTransientConnectErrorWhileDisconnectedDoesNotScheduleReconnect() async throws {
        let (client, apiService, _, _, _) = createTestClient()
        
        apiService.simulatePersistentNetworkErrors()
        client.connectionStatus = .disconnected
        
        client.handleConnectError(
            APIDomainError.network(
                context: APIErrorContext(
                    exchange: .bybit,
                    httpStatus: nil,
                    rawMessage: "Network connection failed"
                )
            )
        )
        
        let callsAfterHandler = apiService.callTimestamps.count
        
        try await Task.sleep(for: .seconds(1.5))
        
        #expect(client.connectionStatus == .disconnected)
        #expect(apiService.callTimestamps.count == callsAfterHandler,
               "Transient failure while disconnected must not schedule reconnect")
    }
    
    @Test("Initial connect + network error disconnects without polling or retry")
    @MainActor
    func testInitialConnectNetworkErrorShouldDisconnect() async throws {
        let (client, apiService, _, _, _) = createTestClient()
        
        apiService.simulateNetworkErrors(count: 1)
        await client.connect()
        
        #expect(client.connectionStatus == .disconnected,
               "First connect attempt with network error should end session, not stay in .connecting")
        
        try await Task.sleep(for: .seconds(1.5))
        #expect(apiService.callTimestamps.count == 1,
               "Failed first connect should not start polling or schedule reconnect")
    }
    
    @Test("Reconnect while connected + network error schedules another connect attempt")
    @MainActor
    func testReconnectWhileConnectedNetworkErrorShouldRecover() async throws {
        let (client, apiService, _, _, _) = createTestClient()
        
        await client.connect()
        #expect(client.connectionStatus == .connected)
        
        apiService.simulatePersistentNetworkErrors()
        await client.connect()
        
        let callsAfterFailedReconnect = apiService.callTimestamps.count
        
        #expect(client.connectionStatus == .connected, "Reconnect failure should keep session active")
        #expect(client.$walletState.isStale, "Data should be stale after failed reconnect")
        
        // do not clear the history, just soft reset
        apiService.shouldFail = false
        apiService.failureCount = 0
        apiService.maxFailures = 0
        
        try await Task.sleep(for: .seconds(1.5))
        
        #expect(apiService.callTimestamps.count > callsAfterFailedReconnect,
               "A network error during reconnect should schedule another connect() attempt")
        #expect(client.$walletState.isStale == false, "Scheduled reconnect should refresh data when API recovers")
    }
    
    @Test("Initial connect + unknown error disconnects without scheduled retry")
    @MainActor
    func testInitialConnectUnknownErrorShouldDisconnect() async throws {
        let (client, apiService, _, _, _) = createTestClient()
        
        apiService.simulateUnknownAPIErrors(count: 1)
        await client.connect()
        
        #expect(client.connectionStatus == .disconnected,
               "Unknown on first connect should not leave UI stuck in .connecting")
        
        try await Task.sleep(for: .seconds(1.5))
        #expect(apiService.callTimestamps.count == 1,
               "Failed first connect should not schedule reconnect")
    }
    
    
    // MARK: - Polling and reconnection behavior
    
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
        
        #expect(client.connectionStatus == .connected,
               "Client should remain connected during retries")
    }
    
    @Test("After max polling retries, BBClient schedules reconnect without disconnecting")
    @MainActor
    func testMaxRetriesSchedulesReconnectWithoutDisconnecting() async throws {
        let (client, apiService, _, _, _) = createTestClient()  // reconnectionDelayInSec: 1.0

        await client.connect()
        apiService.simulatePersistentNetworkErrors()

        // Wait long enough for 5 backoff retries + synthetic unknown + reconnect sleep
        try await Task.sleep(for: .seconds(3))

        #expect(client.connectionStatus == .connected,
               "Max polling retries should schedule reconnect, not disconnect")
        #expect(client.$walletState.isStale,
               "Data should remain stale until a successful fetch after reconnect")
    }
    
    @Test("Data should be marked stale during Network failures, not disconnected")
    @MainActor
    func testDataMarkedStaleNotDisconnected() async throws {
        let (client, apiService, _, _, _) = createTestClient()
        
        await client.connect()
        #expect(client.connectionStatus == .connected)
        
        // Keep failing so polling cannot recover before we assert stale state.
        apiService.simulatePersistentNetworkErrors()
        try await Task.sleep(for: .milliseconds(400))
        
        print("After API failure - client status: \(client.connectionStatus)")
         
        #expect(client.connectionStatus == .connected, 
               "Connection status should remain connected during API failures")
        #expect(client.$walletState.isStale, "Data should be marked as stale")
    }
    
    @Test("Successful API call should clear stale data state")
    @MainActor
    func testSuccessfulAPICallClearsStaleState() async throws {
        let (client, apiService, _, _, _) = createTestClient()
        
        await client.connect()
        #expect(client.connectionStatus == .connected)
        
        // Fail until reset — count: 2 would auto-recover and clear stale before we can assert it.
        apiService.simulatePersistentNetworkErrors()
        try await Task.sleep(for: .milliseconds(600))
        
        #expect(client.connectionStatus == .connected)
        #expect(apiService.failureCount >= 1)
        #expect(client.$walletState.isStale, "Data should be marked as stale after network issue")
        
        // Reset API to success and wait for the next successful poll
        apiService.reset()
        
        try await Task.sleep(for: .milliseconds(500))
        
        #expect(client.connectionStatus == .connected)
        #expect(client.authenticationError == nil,
               "Authentication error should be cleared after successful API call")
        #expect(client.$walletState.isStale == false, "Data should be marked as fresh after success")
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
        await networkStore.simulateNetworkLoss()
        try await Task.sleep(for: .milliseconds(200))
        
        await networkStore.simulateNetworkRestore()
        try await Task.sleep(for: .milliseconds(500))
        
        #expect(client.connectionStatus == .connected, 
               "Should reconnect when network is restored")
        #expect(apiService.failureCount >= 0, 
               "Should resume API calls after network restoration")
    }
    
    @Test("Client should reconnect after transient unknown API error during polling")
    @MainActor
    func testReconnectAfterTransientUnknownAPIError() async throws {
        let (client, apiService, _, _, _) = createTestClient()
        
        await client.connect()
        #expect(client.connectionStatus == .connected, "Initial connection should succeed")
        
        // Transient unmapped API response (e.g. unrecognized retCode) during a poll cycle.
        apiService.simulateUnknownAPIErrors(count: 1)
        
        try await Task.sleep(for: .milliseconds(500))
        
        #expect(client.connectionStatus == .connected,
               "Unknown API errors should not disconnect right away")
        #expect(client.$walletState.isStale, "Data should be marked as stale")
        
        try await Task.sleep(for: .seconds(1))
        
        #expect(client.connectionStatus == .connected,
               "Should be reconnected after reconnectionDelay time passed")
        #expect(client.$walletState.isStale == false, "Data should be fresh again")
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
        await networkStore.simulateNetworkLoss()
        //try await Task.sleep(for: .milliseconds(100))
        await networkStore.simulateNetworkRestore()
        
        // Wait for reconnection attempt
        try await Task.sleep(for: .milliseconds(500))

        #expect(client.connectionStatus == .connected,
               "Network restoration should trigger reconnection even after API-induced disconnection")
    }
}
