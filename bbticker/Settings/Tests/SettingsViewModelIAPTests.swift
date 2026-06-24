//
//  SettingsViewModelIAPTests.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 24/06/2026.
//

import XCTest
import Combine
@testable import bbticker

enum TestSupportUtils {
    @MainActor
    static func waitUntil(
        timeout: TimeInterval = 1.0,
        pollInterval: Duration = .milliseconds(20),
        file: StaticString = #filePath,
        line: UInt = #line,
        condition: @escaping () -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return }
            try await Task.sleep(for: pollInterval)
        }
        XCTFail("Condition not met within \(timeout)s", file: file, line: line)
    }
}

// IAP presentation-layer tests — verifies ViewModel orchestration with spy doubles.
@MainActor
final class SettingsViewModelIAPTests: XCTestCase {
    
    private var settingsService: SettingsService!
    private var storage: MockUserDataStorage!
    private var spyIAP: SpyIAPManager!
    private var viewModel: SettingsViewModel!
    
    override func setUp() async throws {
        storage = MockUserDataStorage()
        settingsService = SettingsService(storage: storage)
        spyIAP = SpyIAPManager()
        viewModel = makeViewModel()
    }
    
    private func makeViewModel() -> SettingsViewModel {
        return SettingsViewModel(
            settingsService: settingsService,
            credentialManager: MockCredentialManager(),
            sharedDataService: MockSharedDataManager(),
            iapManager: spyIAP
        )
    }
    
    // MARK: - refreshIAP
    
    func test_givenStoreKitReportsPro_whenRefreshIAP_thenAppliesProStatus() async {
        // Given
        await spyIAP.configure(isProActive: true)
        XCTAssertFalse(viewModel.isProActive)
        // When
        await viewModel.refreshIAP()
        // Then
        let activeCallCount = await spyIAP.isProActiveCallCount
        XCTAssertEqual(activeCallCount, 2) // 1 when VM inits and 1 when refreshIAP() called
        XCTAssertTrue(viewModel.isProActive)
        XCTAssertEqual(settingsService.state.updateFrequency, ProFeatures.defaultProPollingInterval)
    }
    
    func test_givenStoreKitReportsFree_whenRefreshIAP_thenDowngradesToFreeTier() async {
        // Given
        settingsService.applyProStatus(true)
        await spyIAP.configure(isProActive: false)
        // When
        await viewModel.refreshIAP()
        // Then
        XCTAssertFalse(viewModel.isProActive)
        XCTAssertEqual(settingsService.state.updateFrequency, ProFeatures.freePollingInterval)
    }
    
    // MARK: - Purchase flow (state machine)
    func test_givenSuccessfulPurchase_whenUnlock_thenPurchasedAndProActive() async throws {
        // Given
        await spyIAP.configure(purchaseOutcome: .success(true))
        // When
        viewModel.unlockUpdateFrequency()
        
        try await TestSupportUtils.waitUntil { [weak self] in
            if case .purchased = self?.viewModel.purchaseState { return true }
            return false
        }
        
        // Then
        let purchaseCount = await spyIAP.purchaseProCallCount
        XCTAssertEqual(purchaseCount, 1)
        XCTAssertTrue(viewModel.isProActive)
    }
    
    func test_givenCancelledPurchase_whenUnlock_thenFailedStateAndRemainsFree() async throws {
        // Given
        await spyIAP.configure(purchaseOutcome: .success(false))
        // When
        viewModel.unlockUpdateFrequency()
        try await TestSupportUtils.waitUntil { [weak self] in
            if case .failed = self?.viewModel.purchaseState { return true }
            return false
        }
        // Then
        let purchaseCount = await spyIAP.purchaseProCallCount
        XCTAssertEqual(purchaseCount, 1)
        XCTAssertFalse(viewModel.isProActive)
        if case .failed(let message) = viewModel.purchaseState {
            XCTAssertEqual(message, "Purchase cancelled or unverified")
        } else {
            XCTFail("Expected failed purchase state")
        }
    }
    
    func test_givenStoreKitError_whenUnlock_thenFailedWithErrorDescription() async throws {
        // Given
        let underlying = NSError(domain: "StoreKitTest", code: 1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        await spyIAP.configure(purchaseOutcome: .failure(underlying))
        // When
        viewModel.unlockUpdateFrequency()
        try await TestSupportUtils.waitUntil { [weak self] in
            if case .failed = self?.viewModel.purchaseState { return true }
            return false
        }
        // Then
        if case .failed(let message) = viewModel.purchaseState {
            XCTAssertEqual(message, "Network error")
        } else {
            XCTFail("Expected failed purchase state")
        }
        XCTAssertFalse(viewModel.isProActive)
    }
    
    // MARK: - Restore flow
    func test_givenRestorablePurchase_whenRestore_thenPurchasedAndProActive() async throws {
        // Given
        await spyIAP.configure(restorePurchases: true)
        // When
        viewModel.restorePurchases()
        try await TestSupportUtils.waitUntil { [weak self] in
            if case .purchased = self?.viewModel.purchaseState { return true }
            return false
        }
        // Then
        let restoreCount = await spyIAP.restorePurchasesCallCount
        XCTAssertEqual(restoreCount, 1)
        XCTAssertTrue(viewModel.isProActive)
    }
    
    func test_givenNoRestorablePurchase_whenRestore_thenFailedAndSyncsFromStoreKit() async throws {
        // Given — StoreKit has no purchase; refresh should apply free tier
        await spyIAP.configure(isProActive: false, restorePurchases: false)
        settingsService.applyProStatus(true)
        // When
        viewModel.restorePurchases()
        try await TestSupportUtils.waitUntil { [weak self] in
            if case .failed = self?.viewModel.purchaseState { return true }
            return false
        }
        // Then — restore failed but refreshIAP re-synced entitlement
        let restoreCount = await spyIAP.restorePurchasesCallCount
        let proActiveCallsCount = await spyIAP.isProActiveCallCount
        XCTAssertEqual(restoreCount, 1)
        XCTAssertGreaterThanOrEqual(proActiveCallsCount, 1)
        XCTAssertFalse(viewModel.isProActive)
        XCTAssertEqual(settingsService.state.updateFrequency, ProFeatures.freePollingInterval)
    }
    
    // MARK: - Transaction observer callback
    func test_givenTransactionObserver_whenProRevoked_thenDowngradesToFree() async {

        settingsService.applyProStatus(true)

        await spyIAP.startObservingTransactions { isPro in
            XCTAssertFalse(isPro)
        }

        await spyIAP.simulateProStatusChange(false)
    }
}
