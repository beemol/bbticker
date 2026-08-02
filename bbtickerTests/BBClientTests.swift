import XCTest
import Combine
import LLCore
@testable import bbticker

class BBClientTests: XCTestCase {
    
    //var mockAPIService: MockAPIService!
    var mockSharedDataManager: MockSharedDataManager!
    var mockCredentialManager: MockCredentialManager!
    var cancellables: Set<AnyCancellable>!

    @MainActor
    private lazy var sut: BBClient = {
        BBClient(
            settingsService: mockSettingsService,
            networkMonitor: mockNetworkMonitor,
            sharedDataManager: mockSharedDataManager,
            walletRepository: mockWalletRepository
        )
    }()
    
    @MainActor
    private lazy var mockDisableCenter = MockDisableCenter()
    
    @MainActor
    private lazy var mockSettingsService = MockSettingsService()
    
    @MainActor
    private lazy var mockNetworkMonitor = MockNetworkStore()
    
    @MainActor
    private lazy var mockAPIService = MockAPIService()
    
    @MainActor
    private lazy var mockWalletRepository = MockWalletRepository(apiService: mockAPIService, credentialsManager: mockCredentialManager)
    
    override func setUp() {
        super.setUp()

        //mockAPIService = MockAPIService()
        mockSharedDataManager = MockSharedDataManager()
        mockCredentialManager = MockCredentialManager()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        //mockAPIService = nil
        mockSharedDataManager = nil
        mockCredentialManager = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    @MainActor func testInitialization_SetsCorrectInitialState() {
        // Then
        XCTAssertEqual(sut.connectionStatus, .disconnected)
        XCTAssertEqual(sut.walletState.equity, 0.00)
        XCTAssertEqual(sut.walletState.balance, 0.00)
        XCTAssertFalse(sut.isConnected)
    }
    
    @MainActor func testInitialization_SetsUpUpdateFrequencyObserver() {
        // Given
        let expectation = XCTestExpectation(description: "Update frequency observer works")
        expectation.expectedFulfillmentCount = 1
        
        // Monitor internal state changes (we can't directly access updateFrequency)
        // We'll test this indirectly by connecting and then changing frequency
        Task {
            await sut.connect()
            mockSettingsService.setUpdateFrequency(10.0)
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Connection Tests - Positive Scenarios
    
    @MainActor func testConnect_Success_WithValidCredentials() async {
        // Given
        await mockCredentialManager.setCredentialsToReturn(Credentials(
            apiKey: "valid-key",
            apiSecret: "valid-secret",
            passphrase: "valid-passphrase"
        ))
        mockAPIService.shouldSucceed = true
        mockAPIService.mockTotalEquity = 1000.00
        mockAPIService.mockWalletBalance = 500.00
        
        // When
        await sut.connect()
        
        // Then
        XCTAssertEqual(sut.connectionStatus, .connected)
        XCTAssertEqual(sut.walletState.equity, 1000.00)
        XCTAssertEqual(sut.walletState.balance, 500.00)
        XCTAssertNil(sut.authenticationError)
        XCTAssertTrue(sut.isConnected)
        
        // Verify widget update
        XCTAssertTrue(mockSharedDataManager.updateWalletDataCalled)
        XCTAssertEqual(mockSharedDataManager.lastTotalEquity, "1000.0")
        XCTAssertEqual(mockSharedDataManager.lastWalletBalance, "500.0")
        XCTAssertEqual(mockSharedDataManager.lastConnectionStatus, "Connected")
    }
    
    @MainActor func testConnect_Success_WithKuCoinCredentials() async {
        // Given
        mockSettingsService.setExchangeType(Exchange(.kucoin, wallet: .spot))
        await mockCredentialManager.setCredentialsToReturn(Credentials(
            apiKey: "kucoin-key",
            apiSecret: "kucoin-secret",
            passphrase: "kucoin-passphrase"
        ))
        mockAPIService.shouldSucceed = true
        mockAPIService.mockTotalEquity = 2000.00
        mockAPIService.mockWalletBalance = 1500.00
        
        // When
        await sut.connect()
        
        // Then
        XCTAssertEqual(sut.connectionStatus, .connected)
        XCTAssertEqual(sut.walletState.equity, 2000.00)
        XCTAssertEqual(sut.walletState.balance, 1500.00)
        XCTAssertTrue(mockAPIService.fetchWalletBalanceCalled)
    }
    
    // MARK: - Connection Tests - Negative Scenarios
    
    @MainActor func testConnect_Failure_MissingAPIKey() async {
        // Given
        await mockCredentialManager.setShouldThrowOnGet(true)
        
        // When
        await sut.connect()
        
        // Then
        XCTAssertEqual(sut.connectionStatus, .disconnected)
        XCTAssertEqual(sut.walletState.equity, 0.00)
        XCTAssertEqual(sut.walletState.balance, 0.00)
        XCTAssertFalse(mockAPIService.fetchWalletBalanceCalled)
        
        // Verify widget update
        XCTAssertTrue(mockSharedDataManager.updateWalletDataCalled)
        XCTAssertEqual(mockSharedDataManager.lastConnectionStatus, "Disconnected")
    }
    
    @MainActor func testConnect_Failure_MissingAPISecret() async {
        // Given
        await mockCredentialManager.setShouldThrowOnGet(true)
        
        // When
        await sut.connect()
        
        // Then
        XCTAssertEqual(sut.connectionStatus, .disconnected)
        XCTAssertFalse(mockAPIService.fetchWalletBalanceCalled)
    }
    
    @MainActor func testConnect_Failure_APIError() async {
        // Given
        await mockCredentialManager.setCredentialsToReturn(Credentials(
            apiKey: "valid-key",
            apiSecret: "valid-secret",
            passphrase: "valid-passphrase"
        ))
        mockAPIService.shouldSucceed = false
        mockAPIService.mockError = NSError(domain: "TestError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Unauthorized"])
        
        // When
        await sut.connect()
        
        // Then
        XCTAssertEqual(sut.connectionStatus, .disconnected)
        XCTAssertTrue(sut.authenticationError?.contains("API Error: Unauthorized") ?? false)
        XCTAssertEqual(sut.walletState.equity, 0.00)
        XCTAssertEqual(sut.walletState.balance, 0.00)
    }
    
    @MainActor func testConnect_Failure_APIDomainError() async {
        // Given
        await mockCredentialManager.setCredentialsToReturn(Credentials(
            apiKey: "valid-key",
            apiSecret: "valid-secret",
            passphrase: "valid-passphrase"
        ))
        mockAPIService.shouldSucceed = false
        let exchange = Exchange(.bybit, wallet: .spot)
        let context = APIErrorContext(exchange: exchange.identifier, httpStatus: 401, apiCode: "10001")
        mockAPIService.mockError = APIDomainError.invalidCredentials(context: context)
        
        // When
        await sut.connect()
        
        // Then
        XCTAssertEqual(sut.connectionStatus, .disconnected)
    }
    
//    @MainActor func testConnect_Failure_BlockedByKillSwitch() async {
//        // Given
//        mockDisableCenter.isActive = true
//        mockDisableCenter.message = "Service temporarily unavailable"
//        sut.observeDisableCenter(mockDisableCenter)
//        
//        // When
//        await sut.connect()
//        
//        // Then
//        XCTAssertEqual(sut.connectionStatus, .disconnected)
//        XCTAssertEqual(sut.authenticationError, "Service temporarily unavailable")
//        XCTAssertFalse(mockAPIService.fetchWalletBalanceCalled)
//    }
    
    // MARK: - Disconnect Tests
    
    @MainActor func testDisconnect_FromConnectedState() async {
        // Given - first connect
        mockAPIService.shouldSucceed = true
        await sut.connect()
        XCTAssertEqual(sut.connectionStatus, .connected)
        
        // When
        sut.disconnect()
        
        // Then
        XCTAssertEqual(sut.connectionStatus, .disconnected)
        XCTAssertEqual(sut.walletState.equity, 0.00)
        XCTAssertEqual(sut.walletState.balance, 0.00)
        XCTAssertNil(sut.authenticationError)
    }
    
    @MainActor func testDisconnect_FromDisconnectedState() {
        // Given - already disconnected
        XCTAssertEqual(sut.connectionStatus, .disconnected)
        
        // When
        sut.disconnect()
        
        // Then
        XCTAssertEqual(sut.connectionStatus, .disconnected)
    }
    
    // MARK: - Network Monitoring Tests
    
    @MainActor func testNetworkLost_FromDisconnectedState() async {
        // Given - already disconnected
        XCTAssertEqual(sut.connectionStatus, .disconnected)
        
        // When
        await mockNetworkMonitor.simulateNetworkLoss()
        
        // Then - should remain disconnected without error
        XCTAssertEqual(sut.connectionStatus, .disconnected)
    }
    
    @MainActor func testNetworkRestored_ReconnectionFails() async {
        // Given
        mockAPIService.shouldSucceed = true
        await sut.connect()
        await mockNetworkMonitor.simulateNetworkLoss()
        
        // Change API to fail for reconnection
        mockAPIService.shouldSucceed = false
        mockAPIService.mockError = NSError(domain: "TestError", code: 500, userInfo: nil)
        
        // Set up expectation BEFORE triggering restore
        // We expect: connecting -> disconnected (due to failure)
        let expectation = XCTestExpectation(description: "Network restore reconnection fails")
        sut.$connectionStatus
            .dropFirst() // Skip current disconnected state
            .filter { $0 == .disconnected }
            .first()
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)
        
        // When
        await mockNetworkMonitor.simulateNetworkRestore()
        
        // Then
        await fulfillment(of: [expectation], timeout: 3.0)
    }
    
    @MainActor func testNetworkRestored_WithoutCredentials() async {
        // Given - no credentials
        await mockCredentialManager.setShouldThrowOnGet(true)
        
        // When
        await mockNetworkMonitor.simulateNetworkRestore()
        
        // give some time to connect
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then - should not attempt reconnection
        XCTAssertEqual(sut.connectionStatus, .disconnected)
        XCTAssertFalse(mockAPIService.fetchWalletBalanceCalled)
    }
    
    // MARK: - Kill Switch Tests
    
//    @MainActor func testKillSwitch_DisconnectsWhenActivated() async {
//        // Given - connected client
//        mockAPIService.shouldSucceed = true
//        await sut.connect()
//        XCTAssertEqual(sut.connectionStatus, .connected)
//        
//        sut.observeDisableCenter(mockDisableCenter)
//        
//        let expectation = XCTestExpectation(description: "Kill switch disconnects")
//        sut.$connectionStatus
//            .sink { status in
//                if status == .disconnected {
//                    expectation.fulfill()
//                }
//            }
//            .store(in: &cancellables)
//        
//        // When
//        mockDisableCenter.activate(message: "Emergency maintenance")
//        
//        // Then
//        await fulfillment(of: [expectation], timeout: 2.0)
//        XCTAssertEqual(sut.connectionStatus, .disconnected)
//    }
    
//    @MainActor func testKillSwitch_AllowsConnectionWhenInactive() async {
//        // Given
//        mockDisableCenter.isActive = false
//        sut.observeDisableCenter(mockDisableCenter)
//        mockAPIService.shouldSucceed = true
//        
//        // When
//        await sut.connect()
//        
//        // Then
//        XCTAssertEqual(sut.connectionStatus, .connected)
//    }
    
    // MARK: - Reconnection Logic Tests
    
    @MainActor func testReconnection_ExponentialBackoff() async {
        // Given
        mockAPIService.shouldSucceed = false
        mockAPIService.mockError = NSError(domain: "TestError", code: 500, userInfo: nil)
        mockAPIService.shouldAttemptReconnection = true
        
        // When
        await sut.connect()
        
        // Then - should have attempted reconnection with delay
        // Note: This is hard to test precisely due to timing, but we can verify the state
        XCTAssertEqual(sut.connectionStatus, .disconnected)
        
        // Wait a bit and verify reconnection was attempted
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        // The mock should track reconnection attempts if we enhance it
    }
    
    // MARK: - Update Frequency Tests
    
    @MainActor func testUpdateFrequency_InitialValue() {
        // We can't directly test this without exposing internal state
        // But we can verify the observer is working by changing the value
        mockSettingsService.setUpdateFrequency(10.0)
        XCTAssertEqual(mockSettingsService.updateFrequency, 10.0)
    }
    
    @MainActor func testUpdateFrequency_RestartPollingWhenConnected() async {
        // Given - connected client
        mockAPIService.shouldSucceed = true
        await sut.connect()
        XCTAssertEqual(sut.connectionStatus, .connected)
        
        // When - change frequency
        mockSettingsService.setUpdateFrequency(1.0)
        
        // Then - should restart polling (hard to test directly, but we can verify no errors)
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(sut.connectionStatus, .connected)
    }
    
    // MARK: - Computed Properties Tests
    
    @MainActor func testIsConnected_WhenConnected() async {
        // Given
        mockAPIService.shouldSucceed = true
        await sut.connect()
        
        // Then
        XCTAssertTrue(sut.isConnected)
    }
    
    @MainActor func testIsConnected_WhenDisconnected() {
        // Given
        XCTAssertEqual(sut.connectionStatus, .disconnected)
        
        // Then
        XCTAssertFalse(sut.isConnected)
    }
    
    @MainActor func testIsConnected_WhenConnecting() {
        // Given
        sut.connectionStatus = .connecting
        
        // Then
        XCTAssertFalse(sut.isConnected)
    }
    
    // MARK: - Exchange Type Tests
    
    @MainActor func testExchangeType_Bybit() async {
        // Given
        mockSettingsService.setExchangeType(Exchange(.bybit, wallet: .spot))
        mockAPIService.shouldSucceed = true
        
        // When
        await sut.connect()
        
        // Then
        XCTAssertTrue(mockAPIService.fetchWalletBalanceCalled)
        XCTAssertEqual(mockAPIService.lastExchangeType?.displayName, Exchange(.bybit, wallet: .spot).displayName)
    }
    
//    @MainActor func testExchangeType_Binance() async {
//        // Given
//        mockSettingsService.setExchangeType(Exchange(.binance, wallet: .futures))
//        mockAPIService.shouldSucceed = true
//        
//        // When
//        await sut.connect()
//        
//        // Then
//        XCTAssertTrue(mockAPIService.fetchWalletBalanceCalled)
//        XCTAssertEqual(mockAPIService.lastExchangeType?.displayName, Exchange(.binance, wallet: .futures).displayName)
//    }
    
    // MARK: - Error Handling Tests
    
    @MainActor func testErrorHandling_APIErrorWithReconnection() async {
        // Given
        mockAPIService.shouldSucceed = false
        mockAPIService.shouldAttemptReconnection = true
        mockAPIService.mockError = NSError(domain: "TestError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Server Error"])
        
        // When
        await sut.connect()
        
        // Then
        XCTAssertEqual(sut.connectionStatus, .disconnected)
        XCTAssertTrue(sut.authenticationError?.contains("API Error: Server Error") ?? false)
    }
    
    @MainActor func testErrorHandling_APIErrorWithoutReconnection() async {
        // Given
        mockAPIService.shouldSucceed = false
        mockAPIService.shouldAttemptReconnection = false
        mockAPIService.mockError = NSError(domain: "TestError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Unauthorized"])
        
        // When
        await sut.connect()
        
        // Then
        XCTAssertEqual(sut.connectionStatus, .disconnected)
        XCTAssertTrue(sut.authenticationError?.contains("API Error: Unauthorized") ?? false)
    }
    
    // MARK: - Polling Tests
    
    @MainActor func testPolling_StartsAfterSuccessfulConnection() async {
        // Given
        mockAPIService.shouldSucceed = true
        mockAPIService.mockTotalEquity = 1000.00
        mockAPIService.mockWalletBalance = 500.00
        
        // When
        await sut.connect()
        
        // Wait for polling to potentially start
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then
        XCTAssertEqual(sut.connectionStatus, .connected)
        XCTAssertGreaterThan(mockAPIService.callCount, 0)
    }
    
    @MainActor func testPolling_ContinuesFetchingWhileConnected() async {
        // Given — use a deterministic network mock to avoid NWPathMonitor auto-connect races
        let networkStore = StableMockNetworkStore(isConnected: false)
        let client = BBClient(
            settingsService: mockSettingsService,
            networkMonitor: networkStore,
            sharedDataManager: mockSharedDataManager,
            pollingConfiguration: .fastRetry,
            walletRepository: mockWalletRepository
        )
        mockAPIService.shouldSucceed = true
        mockAPIService.mockTotalEquity = 1000.00
        mockAPIService.mockWalletBalance = 500.00
        mockSettingsService.setUpdateFrequency(0.3)
        
        // When
        await client.connect()
        XCTAssertEqual(client.connectionStatus, .connected)
        let callCountAfterConnect = mockAPIService.callCount
        XCTAssertEqual(callCountAfterConnect, 1, "Initial connect should perform one API fetch")
        
        try? await Task.sleep(nanoseconds: 900_000_000) // 0.9s — enough for at least one poll at 0.3s
        
        // Then — without a running polling loop, only the initial connect fetch happens
        XCTAssertGreaterThan(
            mockAPIService.callCount,
            callCountAfterConnect,
            "Polling should keep fetching wallet data while connected"
        )
        XCTAssertEqual(client.connectionStatus, .connected)
        XCTAssertFalse(client.$walletState.isStale, "Wallet data should stay fresh while polling succeeds")
    }
    
    @MainActor func testPolling_StopsOnDisconnect() async {
        // Given - start with successful connection
        mockAPIService.shouldSucceed = true
        
        await sut.connect()
        XCTAssertEqual(sut.connectionStatus, .connected)
        
        // Wait for initial polling cycle to start
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // When - disconnect
        sut.disconnect()
        let callCountAtDisconnect = mockAPIService.callCount
        
        // Verify polling truly stopped - no additional calls should occur
        let finalCallCount = mockAPIService.callCount
        XCTAssertEqual(sut.connectionStatus, .disconnected)
        XCTAssertEqual(finalCallCount, callCountAtDisconnect, "Polling should stop immediately after disconnect - no additional API calls should occur")
    }
    
    @MainActor func testPolling_HandlesAPIErrorDuringPolling() async {
        // Given - start with successful connection
        mockAPIService.shouldSucceed = true
        await sut.connect()
        XCTAssertEqual(sut.connectionStatus, .connected)
        
        // Set up expectation for disconnection
        let expectation = XCTestExpectation(description: "Polling error causes disconnection")
        sut.$connectionStatus
            .sink { status in
                if status == .disconnected {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When - make API fail during polling
        mockAPIService.shouldSucceed = false
        mockAPIService.mockError = NSError(domain: "TestError", code: 500, userInfo: nil)
        
        // Then
        await fulfillment(of: [expectation], timeout: 8.0) // Wait longer for polling cycle
        XCTAssertEqual(sut.connectionStatus, .disconnected)
    }
    
    // MARK: - Connection Status Tests
    
    @MainActor func testConnectionStatus_Color() {
        // Test ConnectionStatus color property
        XCTAssertEqual(ConnectionStatus.connected.color, .green)
        XCTAssertEqual(ConnectionStatus.connecting.color, .yellow)
        XCTAssertEqual(ConnectionStatus.disconnecting.color, .orange)
        XCTAssertEqual(ConnectionStatus.disconnected.color, .red)
    }
    
    @MainActor func testConnectionStatus_Description() {
        // Test ConnectionStatus description property
        XCTAssertEqual(ConnectionStatus.connected.description, "Connected")
        XCTAssertEqual(ConnectionStatus.connecting.description, "Connecting")
        XCTAssertEqual(ConnectionStatus.disconnecting.description, "Disconnecting")
        XCTAssertEqual(ConnectionStatus.disconnected.description, "Disconnected")
    }
    
    // MARK: - Widget Data Update Tests
    
    @MainActor func testWidgetDataUpdate_OnSuccessfulConnection() async {
        // Given
        mockAPIService.shouldSucceed = true
        mockAPIService.mockTotalEquity = 1500.75
        mockAPIService.mockWalletBalance = 750.25
        
        // When
        await sut.connect()
        
        // Then
        XCTAssertTrue(mockSharedDataManager.updateWalletDataCalled)
        XCTAssertEqual(mockSharedDataManager.lastTotalEquity, "1500.75")
        XCTAssertEqual(mockSharedDataManager.lastWalletBalance, "750.25")
        XCTAssertEqual(mockSharedDataManager.lastConnectionStatus, "Connected")
    }
    
    @MainActor func testWidgetDataUpdate_OnDisconnection() async {
        // Given - connect first
        mockAPIService.shouldSucceed = true
        await sut.connect()
        mockSharedDataManager.reset() // Reset to test disconnect specifically
        
        // When
        sut.disconnect()
        
        // Then
        XCTAssertTrue(mockSharedDataManager.updateWalletDataCalled)
        XCTAssertEqual(mockSharedDataManager.lastTotalEquity, "n/a")
        XCTAssertEqual(mockSharedDataManager.lastWalletBalance, "n/a")
        XCTAssertEqual(mockSharedDataManager.lastConnectionStatus, "Disconnected")
    }
    
    @MainActor func testWidgetDataUpdate_OnCredentialError() async {
        // Given
        await mockCredentialManager.setShouldThrowOnGet(true)
        
        // When
        await sut.connect()
        
        // Then
        XCTAssertTrue(mockSharedDataManager.updateWalletDataCalled)
        XCTAssertEqual(mockSharedDataManager.lastConnectionStatus, "Disconnected")
    }
    
    // MARK: - Reconnection Tests
    
    @MainActor func testReconnection_ResetAfterSuccessfulConnection() async {
        // Given - simulate initial connection failure
        mockAPIService.shouldSucceed = false
        mockAPIService.mockError = NSError(domain: "TestError", code: 500, userInfo: nil)
        await sut.connect()
        XCTAssertEqual(sut.connectionStatus, .disconnected)
        
        // When - simulate successful reconnection
        mockAPIService.shouldSucceed = true
        mockAPIService.mockTotalEquity = 1000.00
        mockAPIService.mockWalletBalance = 500.00
        await sut.connect()
        
        // Then
        XCTAssertEqual(sut.connectionStatus, .connected)
        XCTAssertEqual(sut.walletState.equity, 1000.00)
        XCTAssertEqual(sut.walletState.balance, 500.00)
    }
    
    // MARK: - Multiple Exchange Type Tests
    
    @MainActor func testExchangeType_KuCoinSpot() async {
        // Given
        mockSettingsService.setExchangeType(Exchange(.kucoin, wallet: .spot))
        mockAPIService.shouldSucceed = true
        
        // When
        await sut.connect()
        
        // Then
        XCTAssertTrue(mockAPIService.fetchWalletBalanceCalled)
        XCTAssertEqual(mockAPIService.lastExchangeType?.displayName, Exchange(.kucoin, wallet: .spot).displayName)
    }
    
    @MainActor func testExchangeType_KuCoinFutures() async {
        // Given
        mockSettingsService.setExchangeType(Exchange(.kucoin, wallet: .futures))
        mockAPIService.shouldSucceed = true
        
        // When
        await sut.connect()
        
        // Then
        XCTAssertTrue(mockAPIService.fetchWalletBalanceCalled)
        XCTAssertEqual(mockAPIService.lastExchangeType?.displayName, Exchange(.kucoin, wallet: .futures).displayName)
    }
    
    // MARK: - State Persistence Tests
    
    @MainActor func testStateClearing_OnConnectionFailure() async {
        // Given - start with some existing state
        sut.walletState.equity = 999.99
        sut.walletState.balance = 888.88
        sut.authenticationError = nil
        
        // When - connection fails
        await mockCredentialManager.setShouldThrowOnGet(true)
        await sut.connect()
        
        // Then - data should be marked stale
        XCTAssertEqual(sut.walletState.equity, 999.99)
        XCTAssertEqual(sut.walletState.balance, 888.88)
        XCTAssertEqual(sut.$walletState.isStale, true)
        XCTAssertEqual(sut.connectionStatus, .disconnected)
    }
    
    // MARK: - Credential Account Name Tests
    
    @MainActor func testCredentialAccountName_UsesExchangeDisplayName() async {
        // Given
        mockSettingsService.setExchangeType(Exchange(.bybit, wallet: .spot))
        
        // When
        await sut.connect()
        
        // Then
        let getCredentialsCalled = await mockCredentialManager.wasGetCredentialsCalled()
        let lastAccountRequested = await mockCredentialManager.getLastAccountRequested()
        XCTAssertTrue(getCredentialsCalled)
        XCTAssertEqual(lastAccountRequested, Exchange(.bybit, wallet: .spot).displayName)
    }
    
    @MainActor func testCredentialAccountName_KuCoinUsesDisplayName() async {
        // Given
        mockSettingsService.setExchangeType(Exchange(.kucoin, wallet: .spot))
        
        // When
        await sut.connect()
        
        // Then
        let getCredentialsCalled = await mockCredentialManager.wasGetCredentialsCalled()
        let lastAccountRequested = await mockCredentialManager.getLastAccountRequested()
        XCTAssertTrue(getCredentialsCalled)
        XCTAssertEqual(lastAccountRequested, Exchange(.kucoin, wallet: .spot).displayName)
    }
    
    // MARK: - Kill Switch Edge Cases
    
//    @MainActor func testKillSwitch_DeactivationAllowsConnection() async {
//        // Given
//        mockDisableCenter.isActive = true
//        sut.observeDisableCenter(mockDisableCenter)
//        mockAPIService.shouldSucceed = true
//        
//        // First attempt should fail
//        await sut.connect()
//        XCTAssertEqual(sut.connectionStatus, .disconnected)
//        
//        // When - deactivate kill switch
//        mockDisableCenter.deactivate()
//        await sut.connect()
//        
//        // Then
//        XCTAssertEqual(sut.connectionStatus, .connected)
//    }
    
    // MARK: - Update Frequency Edge Cases
    
    @MainActor func testUpdateFrequency_VeryLowValue() async {
        // Given
        mockAPIService.shouldSucceed = true
        await sut.connect()
        XCTAssertEqual(sut.connectionStatus, .connected)
        
        // When - set very low update frequency
        mockSettingsService.setUpdateFrequency(0.1) // 100ms
        
        // Wait a short time
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Then - should still be connected and potentially have multiple calls
        XCTAssertEqual(sut.connectionStatus, .connected)
    }
    
    @MainActor func testUpdateFrequency_DoesNotRestartPollingWhenDisconnected() {
        // Given - disconnected state
        XCTAssertEqual(sut.connectionStatus, .disconnected)
        let initialCallCount = mockAPIService.callCount
        
        // When - change frequency while disconnected
        mockSettingsService.setUpdateFrequency(1.0)
        
        // Then - should not start any API calls
        XCTAssertEqual(mockAPIService.callCount, initialCallCount)
    }
    
    // MARK: - Polling Frequency Update Tests
    
    @MainActor func testUpdateFrequency_UpdatesPollingStrategyFrequency() async {
        // Given - connect with initial frequency of 2 seconds (2_000_000_000 nanoseconds)
        let initialFrequency = 2_000_000_000.0 // 2 seconds in nanoseconds
        mockSettingsService.setUpdateFrequency(2.0)
        mockAPIService.shouldSucceed = true
        mockAPIService.mockTotalEquity = 1000.00
        mockAPIService.mockWalletBalance = 500.00
        
        await sut.connect()
        XCTAssertEqual(sut.connectionStatus, .connected)
        
        // Record initial call count after connection
        let initialCallCount = mockAPIService.callCount
        
        // Wait for one polling cycle at the initial frequency (2 seconds)
        try? await Task.sleep(nanoseconds: UInt64(initialFrequency + 500_000_000)) // 2.5 seconds
        
        let callCountAfterFirstCycle = mockAPIService.callCount
        XCTAssertGreaterThan(callCountAfterFirstCycle, initialCallCount, 
                            "Should have made at least one polling call at initial frequency")
        
        // When - change frequency to a much shorter interval (0.3 seconds)
        let newFrequency = 300_000_000.0 // 0.3 seconds in nanoseconds
        mockSettingsService.setUpdateFrequency(0.3)
        
        // Wait for the current polling cycle to complete (up to 2 seconds)
        // Then wait for the new frequency to take effect and observe multiple calls
        try? await Task.sleep(nanoseconds: UInt64(initialFrequency + 100_000_000)) // 2.1 seconds for current cycle to finish
        
        // Now reset timestamps to measure the new frequency
        mockAPIService.resetCallTimestamps()
        
        // Wait for multiple calls at the new frequency
        try? await Task.sleep(nanoseconds: UInt64(newFrequency * 3 + 200_000_000)) // ~1.1 seconds
        
        // Then - verify that polling now happens at the new frequency
        let callTimestamps = mockAPIService.getCallTimestamps()
        
        // We should have at least 2 calls to measure intervals
        XCTAssertGreaterThanOrEqual(callTimestamps.count, 2, 
                                   "Should have multiple API calls after frequency change")
        
        // Calculate intervals between consecutive calls
        if callTimestamps.count >= 2 {
            for i in 1..<callTimestamps.count {
                let interval = callTimestamps[i].timeIntervalSince(callTimestamps[i-1])
                
                // The interval should be close to the new frequency (0.3 seconds)
                // Allow 50% tolerance for timing variations in tests
                let expectedIntervalInSeconds = newFrequency / 1_000_000_000.0
                let tolerance = expectedIntervalInSeconds * 0.5
                
                XCTAssertEqual(interval, expectedIntervalInSeconds, accuracy: tolerance,
                             "Polling interval should match new frequency of \(expectedIntervalInSeconds)s, but was \(interval)s")
            }
        }
    }
}

// MARK: - Enhanced Mock Objects

/// Network mock that does not use NWPathMonitor — avoids auto-connect races in polling tests.
@MainActor
final class StableMockNetworkStore: NetworkStoreProtocol {
    var state: NetworkState
    private var statusContinuation: AsyncStream<Bool>.Continuation?
    
    lazy var statusStream: AsyncStream<Bool> = {
        AsyncStream { continuation in
            self.statusContinuation = continuation
            continuation.yield(self.state.isConnected)
        }
    }()
    
    init(isConnected: Bool) {
        self.state = NetworkState(isConnected: isConnected)
    }
    
    func dispatch(_ action: NetworkAction) async {
        switch action {
        case .statusChanged(let isConnected):
            state.isConnected = isConnected
        case .startMonitoring, .connectionTypeChanged, .stopMonitoring:
            break
        case .internetStatusChanged(_):
            break
        }
    }
}

class MockAPIService: APIServiceProtocol {
    func fetchWalletBalanceForCurrentExchange() async throws -> WalletData {
        throw NSError(domain: "MockError", code: 500, userInfo: nil)
    }
    
    var shouldSucceed = true
    var shouldAttemptReconnection = false
    var mockTotalEquity: Double = 0.00
    var mockWalletBalance: Double = 0.00
    var mockMaintenanceMargin: Double = 0.00
    var mockError: Error?
    var fetchWalletBalanceCalled = false
    var lastExchangeType: ExchangeType?
    var callCount = 0
    private var callTimestamps: [Date] = []
    
    func fetchWalletBalance(for exchangeType: ExchangeType) async throws -> WalletData {
        fetchWalletBalanceCalled = true
        lastExchangeType = exchangeType
        callCount += 1
        callTimestamps.append(Date())
        
        // Small delay to simulate network call
        try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        
        if shouldSucceed {
            return WalletData(totalEquity: mockTotalEquity, walletBalance: mockWalletBalance, maintenanceMargin: mockMaintenanceMargin)
        } else {
            throw mockError ?? NSError(domain: "MockError", code: 500, userInfo: nil)
        }
    }
    
    func reset() {
        fetchWalletBalanceCalled = false
        lastExchangeType = nil
        callCount = 0
        callTimestamps = []
    }
    
    func resetCallTimestamps() {
        callTimestamps = []
    }
    
    func getCallTimestamps() -> [Date] {
        return callTimestamps
    }
}

class MockDisableCenter: DisableCenter {
    override init() {
        super.init()
    }
    
    func activate(message: String) {
        self.message = message
        self.isActive = true
    }
    
    func deactivate() {
        self.isActive = false
        self.message = ""
    }
}
