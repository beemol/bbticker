import XCTest
import Combine
@testable import bbticker

// TODO: get rid of VM
@MainActor
class SettingsViewModelTests: XCTestCase {
    
    private var viewModel: SettingsViewModel!
    
    private lazy var mockSettingsService = MockSettingsService()
    private lazy var mockCredentialManager = MockCredentialManager()
    private lazy var mockSharedDataService = MockSharedDataManager()
    private lazy var mockIAP = MockIAPManager()
    
    private var cancellables: Set<AnyCancellable> = Set<AnyCancellable>()
    
    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "analytics_enabled")
    }
    
    private func makeViewModel(iap: MockIAPManager? = nil) -> SettingsViewModel {
        return SettingsViewModel(
            settingsService: mockSettingsService,
            credentialManager: mockCredentialManager,
            sharedDataService: mockSharedDataService,
            iapManager: iap ?? mockIAP
        )
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        viewModel = makeViewModel()
        //XCTAssertEqual(viewModel.saveStatus, "")
        XCTAssertFalse(viewModel.widgetEnabled)
        //XCTAssertTrue(viewModel.isSecureField)
        //XCTAssertEqual(viewModel.updateFrequency, 5.0)
        XCTAssertEqual(viewModel.widgetRefreshInterval, 5.0)
    }
    
    func testInitialization_LoadsWidgetSettings() {
        viewModel = makeViewModel()
        XCTAssertTrue(mockSharedDataService.isWidgetEnabledCalled)
        XCTAssertTrue(mockSharedDataService.getWidgetRefreshIntervalCalled)
    }
    
    // MARK: - Widget Settings Tests
    
    func testSetWidgetEnabled() {
        // When
        viewModel = makeViewModel()
        viewModel.setWidgetEnabled(true)
        
        // Then
        XCTAssertTrue(viewModel.widgetEnabled)
        XCTAssertTrue(mockSharedDataService.setWidgetEnabledCalled)
        XCTAssertEqual(mockSharedDataService.lastWidgetEnabledValue, true)
    }
    
    func testSetWidgetRefreshInterval() {
        // When
        viewModel = makeViewModel()
        viewModel.setWidgetRefreshInterval(30.0)
        
        // Then
        XCTAssertEqual(viewModel.widgetRefreshInterval, 30.0)
        XCTAssertTrue(mockSharedDataService.setWidgetRefreshIntervalCalled)
        XCTAssertEqual(mockSharedDataService.lastWidgetRefreshInterval, 30.0)
    }
    
    // MARK: - Exchange Type Settings Tests
    
//    func testSetExchangeType() {
//        // When
//        viewModel.setExchangeType(.binance(walletType: .futures))
//        
//        // Then
//        XCTAssertTrue(mockSettingsService.setExchangeTypeCalled)
//        XCTAssertEqual(mockSettingsService.lastExchangeType?.displayName, ExchangeType.binance(walletType: .futures).displayName)
//    }
//    
//    func testSelectedExchangeBinding_UpdatesExchangeType() {
//        // Given
//        let binding = viewModel.selectedExchangeNameBinding
//        
//        // When
//        binding.wrappedValue = .kucoin
//        
//        // Then
//        XCTAssertTrue(mockSettingsService.setExchangeTypeCalled)
//        XCTAssertEqual(mockSettingsService.lastExchangeType?.exchangeName, .kucoin)
//    }
//    
//    func testSelectedWalletTypeBinding_UpdatesExchangeType() {
//        // Given
//        let binding = viewModel.selectedWalletTypeBinding
//        
//        // When
//        binding.wrappedValue = .futures
//        
//        // Then
//        XCTAssertTrue(mockSettingsService.setExchangeTypeCalled)
//        XCTAssertEqual(mockSettingsService.lastExchangeType?.walletType, .futures)
//    }
//    
//    func testInitialWalletTypeBinding_IsValid() {
//        // Given
//        let binding = viewModel.selectedWalletTypeBinding
//        
//        // Then
//        XCTAssertTrue(WalletType.allCases.contains(binding.wrappedValue))
//    }
    
    // MARK: - Update Frequency Settings Tests
    
    func testSetUpdateFrequency() {
        // When
        viewModel = makeViewModel()
        viewModel.setUpdateFrequency(10.0)
        
        // Then
        XCTAssertTrue(mockSettingsService.setUpdateFrequencyCalled)
        XCTAssertEqual(mockSettingsService.lastUpdateFrequency, 10.0)
    }
    
    func testUpdateFrequencyBinding() {
        // Given
        viewModel = makeViewModel()
        let binding = viewModel.updateFrequencyBinding
        
        // When
        binding.wrappedValue = 15.0
        
        // Then
        XCTAssertTrue(mockSettingsService.setUpdateFrequencyCalled)
        XCTAssertEqual(mockSettingsService.lastUpdateFrequency, 15.0)
    }
    
    func testWidgetEnabledBinding() {
        // Given
        viewModel = makeViewModel()
        let binding = viewModel.widgetEnabledBinding
        
        // When
        binding.wrappedValue = true
        
        // Then
        XCTAssertTrue(viewModel.widgetEnabled)
        XCTAssertTrue(mockSharedDataService.setWidgetEnabledCalled)
    }
    
    func testWidgetRefreshIntervalBinding() {
        // Given
        viewModel = makeViewModel()
        let binding = viewModel.widgetRefreshIntervalBinding
        
        // When
        binding.wrappedValue = 25.0
        
        // Then
        XCTAssertEqual(viewModel.widgetRefreshInterval, 25.0)
        XCTAssertTrue(mockSharedDataService.setWidgetRefreshIntervalCalled)
    }
    
    // MARK: - Analytics Settings Tests
    
    func testAnalyticsDefaultsToFalse() {
        viewModel = makeViewModel()
        XCTAssertFalse(viewModel.analyticsEnabled)
    }
    
    func testSetAnalyticsEnabled_True() {
        // Given
        viewModel = makeViewModel()
        
        // When
        viewModel.setAnalyticsEnabled(true)
        
        // Then
        XCTAssertTrue(viewModel.analyticsEnabled)
    }
    
    func testSetAnalyticsEnabled_ThenDisabled() {
        // Given
        viewModel = makeViewModel()
        viewModel.setAnalyticsEnabled(true)
        XCTAssertTrue(viewModel.analyticsEnabled)
        
        // When
        viewModel.setAnalyticsEnabled(false)
        
        // Then
        XCTAssertFalse(viewModel.analyticsEnabled)
    }
    
    func testAnalyticsEnabledBinding() {
        // Given
        viewModel = makeViewModel()
        let binding = viewModel.analyticsEnabledBinding
        XCTAssertFalse(binding.wrappedValue)
        
        // When
        binding.wrappedValue = true
        
        // Then
        XCTAssertTrue(viewModel.analyticsEnabled)
    }

    // MARK: - Exchange Type Reactive Tests
    
//    func testExchangeTypeChange_ReloadsCredentials() async {
//        // Given
//        viewModel = makeViewModel()
//        let expectation = XCTestExpectation(description: "Credentials reloaded")
//        mockCredentialManager.credentialsToReturn = Credentials(
//            apiKey: "new-key",
//            apiSecret: "new-secret",
//            passphrase: "new-passphrase"
//        )
//        
//        // Reset call tracking
//        mockCredentialManager.reset()
//        
//        // When
//        mockSettingsService.exchangeType = .binance(walletType: .futures)
//        
//        // Wait for the reactive binding to trigger
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//            expectation.fulfill()
//        }
//        
//        await fulfillment(of: [expectation], timeout: 1.0)
//        
//        // Then
//        XCTAssertTrue(mockCredentialManager.getCredentialsCalled)
//        XCTAssertEqual(mockCredentialManager.lastAccountRequested, ExchangeType.binance(walletType: .futures).displayName)
//    }

    // MARK: - Unlock/IAP Binding and Flows
//    func testUnlockBinding_ReflectsServiceState() {
//        XCTAssertFalse(viewModel.isUpdateFrequencyUnlocked)
//        mockSettingsService.setUpdateFrequencyUnlocked(true)
//        XCTAssertTrue(viewModel.isUpdateFrequencyUnlocked)
//    }
    
    func testRefreshIAP_UpdatesUnlockState_WhenUnlocked() async {
        await mockIAP.setIsUnlockedToReturn(true)
        viewModel = SettingsViewModel(
            settingsService: mockSettingsService,
            credentialManager: mockCredentialManager,
            sharedDataService: mockSharedDataService,
            iapManager: mockIAP
        )
        await viewModel.refreshIAP()
        XCTAssertTrue(mockSettingsService.isUpdateFrequencyUnlocked)
        XCTAssertTrue(viewModel.isProActive)
    }
    
    func testUnlockUpdateFrequency_PurchaseSuccess() async {
        await mockIAP.setIsUnlockedToReturn(true)
        viewModel = SettingsViewModel(
            settingsService: mockSettingsService,
            credentialManager: mockCredentialManager,
            sharedDataService: mockSharedDataService,
            iapManager: mockIAP
        )
        
        let expectation = XCTestExpectation(description: "Purchase flow completed")
        viewModel.unlockUpdateFrequency()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)
        
        switch viewModel.purchaseState {
        case .purchased:
            XCTAssertTrue(mockSettingsService.isUpdateFrequencyUnlocked)
        default:
            XCTFail("Expected purchased state")
        }
    }
    
    func testRestorePurchases_Success() async {
        let mockIAP = MockIAPManager()
        await mockIAP.setRestorePurchasesToReturn(true)
        await mockIAP.setIsUnlockedToReturn(true)
        viewModel = SettingsViewModel(
            settingsService: mockSettingsService,
            credentialManager: mockCredentialManager,
            sharedDataService: mockSharedDataService,
            iapManager: mockIAP
        )
        
        let expectation = XCTestExpectation(description: "Restore flow completed")
        viewModel.restorePurchases()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)
        
        switch viewModel.purchaseState {
        case .purchased:
            XCTAssertTrue(mockSettingsService.isUpdateFrequencyUnlocked)
        default:
            XCTFail("Expected purchased state after restore")
        }
    }
}

// MARK: - Enhanced Mock Objects

class MockSettingsService: SettingsServiceProtocol {
    // Use real SettingsService with mock storage for proper isolation
    private let realService: SettingsService
    private let mockStorage: MockUserDataStorage
    
    // Call tracking for assertions
    var setUpdateFrequencyCalled = false
    var setExchangeTypeCalled = false
    var setUpdateFrequencyUnlockedCalled = false
    var setAPIEnvironmentCalled = false
    var lastUpdateFrequency: Double?
    var lastExchangeType: ExchangeType?
    var lastAPIEnvironment: APIEnvironment?
    
    var state: SettingsState {
        realService.state
    }
    
    // Convenience accessors used in tests
    var exchangeType: Exchange {
        get { state.exchangeType }
        set { setExchangeType(newValue) }
    }
    var updateFrequency: Double { state.updateFrequency }
    var isUpdateFrequencyUnlocked: Bool { state.isProActive }

    init() {
        mockStorage = MockUserDataStorage()
        realService = SettingsService(storage: mockStorage)
        
        // Override defaults for tests to match previous behavior
        realService.setExchangeType(Exchange(.bybit, wallet: .spot))
    }

    func applyProStatus(_ unlocked: Bool) {
        setUpdateFrequencyUnlockedCalled = true
        realService.applyProStatus(unlocked)
    }

    func setUpdateFrequency(_ frequency: Double) {
        setUpdateFrequencyCalled = true
        lastUpdateFrequency = frequency
        realService.setUpdateFrequency(frequency)
    }

    func setExchangeType(_ exchangeType: Exchange) {
        setExchangeTypeCalled = true
        lastExchangeType = exchangeType
        realService.setExchangeType(exchangeType)
    }
    
    func setShowMarginLevelDot(_ enabled: Bool) {
        realService.setShowMarginLevelDot(enabled)
    }

    func setAPIEnvironment(_ environment: APIEnvironment) {
        setAPIEnvironmentCalled = true
        lastAPIEnvironment = environment
        realService.setAPIEnvironment(environment)
    }

    func reset() {
        setUpdateFrequencyCalled = false
        setExchangeTypeCalled = false
        setUpdateFrequencyUnlockedCalled = false
        setAPIEnvironmentCalled = false
        lastUpdateFrequency = nil
        lastExchangeType = nil
        lastAPIEnvironment = nil
        
        // Reset storage and reinitialize to defaults
        mockStorage.reset()
        realService.setUpdateFrequency(5.0)
        realService.setExchangeType(Exchange(.bybit, wallet: .spot))
        realService.applyProStatus(false)
    }
}

import LLCore

actor MockCredentialManager: CredentialManagerProtocol {
    var credentialsToReturn: Credentials = Credentials(apiKey: "test-key", apiSecret: "test-secret", passphrase: "test-passphrase")
    var saveResult: OSStatus = errSecSuccess
    var deleteResult: OSStatus = errSecSuccess
    var shouldThrowOnGet: Bool = false
    
    private let fallbackOnMissing: Bool
    private var store: [String: Credentials] = [:]
    
    var getCredentialsCalled = false
    var saveCredentialsCalled = false
    var deleteCredentialsCalled = false
    var invalidateCacheCalled = false
    var invalidateAllCalled = false
    
    var lastAccountRequested: String?
    var lastSavedKey: String?
    var lastSavedSecret: String?
    var lastSavedPassphrase: String?
    var lastSavedAccount: String?
    var lastDeletedAccount: String?
    
    init(fallbackOnMissing: Bool = true) {
        self.fallbackOnMissing = fallbackOnMissing
    }
    
    func getCredentials(forAccount account: String) async throws -> Credentials {
        getCredentialsCalled = true
        lastAccountRequested = account
        
        // Check shouldThrowOnGet first (for explicit test control)
        if shouldThrowOnGet {
            throw NSError(domain: "MockCredentialManager", code: 1)
        }
        
        // Return saved credentials if they exist
        if let saved = store[account] {
            return saved
        }
        
        // If no saved credentials and fallback disabled, throw
        if !fallbackOnMissing {
            throw NSError(domain: "MockCredentialManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "No credentials for account \(account)"])
        }
        
        // Otherwise return fallback
        return credentialsToReturn
    }
    
    @discardableResult
    func saveCredentials(key: String, secret: String, passphrase: String, forAccount account: String) async -> OSStatus {
        saveCredentialsCalled = true
        lastSavedKey = key
        lastSavedSecret = secret
        lastSavedPassphrase = passphrase
        lastSavedAccount = account
        store[account] = Credentials(apiKey: key, apiSecret: secret, passphrase: passphrase.isEmpty ? nil : passphrase)
        return saveResult
    }
    
    @discardableResult
    func deleteCredentials(forAccount account: String) async -> OSStatus {
        deleteCredentialsCalled = true
        lastDeletedAccount = account
        store.removeValue(forKey: account)
        return deleteResult
    }
    
    func invalidateCache(forAccount account: String) async {
        invalidateCacheCalled = true
    }
    
    func invalidateAll() async {
        invalidateAllCalled = true
    }
    
    func reset() {
        getCredentialsCalled = false
        saveCredentialsCalled = false
        deleteCredentialsCalled = false
        invalidateCacheCalled = false
        invalidateAllCalled = false
        lastAccountRequested = nil
        lastSavedKey = nil
        lastSavedSecret = nil
        lastSavedPassphrase = nil
        lastSavedAccount = nil
        lastDeletedAccount = nil
        store.removeAll()
    }
    
    // MARK: - Test Helper Methods for Actor-Isolated Property Access
    
    func wasGetCredentialsCalled() -> Bool {
        return getCredentialsCalled
    }
    
    func wasSaveCredentialsCalled() -> Bool {
        return saveCredentialsCalled
    }
    
    func wasDeleteCredentialsCalled() -> Bool {
        return deleteCredentialsCalled
    }
    
    func getLastAccountRequested() -> String? {
        return lastAccountRequested
    }
    
    func getLastSavedKey() -> String? {
        return lastSavedKey
    }
    
    func getLastSavedSecret() -> String? {
        return lastSavedSecret
    }
    
    func getLastSavedPassphrase() -> String? {
        return lastSavedPassphrase
    }
    
    func getLastSavedAccount() -> String? {
        return lastSavedAccount
    }
    
    func getLastDeletedAccount() -> String? {
        return lastDeletedAccount
    }
    
    func setSaveResult(_ result: OSStatus) {
        saveResult = result
    }
    
    func setDeleteResult(_ result: OSStatus) {
        deleteResult = result
    }
    
    func setCredentialsToReturn(_ credentials: Credentials) {
        credentialsToReturn = credentials
    }
    
    func setShouldThrowOnGet(_ shouldThrow: Bool) {
        shouldThrowOnGet = shouldThrow
    }
}

actor MockIAPManager: IAPManagerProtocol {
    func startObservingTransactions(onProStatusChange: @escaping @Sendable (Bool) -> Void) {}

    private var isUnlockedToReturn: Bool = false
    private var purchaseUnlockToReturn: Bool = true
    private var restorePurchasesToReturn: Bool = true
    
    func setIsUnlockedToReturn(_ value: Bool) {
        isUnlockedToReturn = value
    }
    
    func setPurchaseUnlockToReturn(_ value: Bool) {
        purchaseUnlockToReturn = value
    }
    
    func setRestorePurchasesToReturn(_ value: Bool) {
        restorePurchasesToReturn = value
    }
    
    func isProActive() async -> Bool {
        isUnlockedToReturn
    }
    
    func purchasePro() async throws -> Bool {
        purchaseUnlockToReturn
    }
    
    func restorePurchases() async -> Bool {
        restorePurchasesToReturn
    }
}


class MockSharedDataManager: SharedDataManagerProtocol {
    var updateWalletDataCalled = false
    var lastTotalEquity: String?
    var lastWalletBalance: String?
    var lastConnectionStatus: String?
    var updateCount = 0
    
    var isWidgetEnabledCalled = false
    var getWidgetRefreshIntervalCalled = false
    var setWidgetEnabledCalled = false
    var setWidgetRefreshIntervalCalled = false
    
    var widgetEnabledToReturn = false
    var widgetRefreshIntervalToReturn = 5.0
    var lastWidgetEnabledValue: Bool?
    var lastWidgetRefreshInterval: Double?
    
    func isWidgetEnabled() -> Bool {
        isWidgetEnabledCalled = true
        return widgetEnabledToReturn
    }
    
    func getWidgetRefreshInterval() -> Double {
        getWidgetRefreshIntervalCalled = true
        return widgetRefreshIntervalToReturn
    }
    
    func setWidgetEnabled(_ enabled: Bool) {
        setWidgetEnabledCalled = true
        lastWidgetEnabledValue = enabled
        widgetEnabledToReturn = enabled
    }
    
    func setWidgetRefreshInterval(_ interval: Double) {
        setWidgetRefreshIntervalCalled = true
        lastWidgetRefreshInterval = interval
        widgetRefreshIntervalToReturn = interval
    }
    
    func reset() {
        isWidgetEnabledCalled = false
        getWidgetRefreshIntervalCalled = false
        setWidgetEnabledCalled = false
        setWidgetRefreshIntervalCalled = false
        lastWidgetEnabledValue = nil
        lastWidgetRefreshInterval = nil
        
        updateWalletDataCalled = false
        lastTotalEquity = nil
        lastWalletBalance = nil
        lastConnectionStatus = nil
        updateCount = 0
    }
    
    func updateWidgetData(totalEquity: String, walletBalance: String, connectionStatus: String) {
        updateWalletDataCalled = true
        lastTotalEquity = totalEquity
        lastWalletBalance = walletBalance
        lastConnectionStatus = connectionStatus
        updateCount += 1
    }
}
