//
//  ProEntitlementTests.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 24/06/2026.
//

import XCTest
import LLCore
@testable import bbticker

// Data-driven unit tests for Pro entitlement business rules (SettingsService.applyProStatus)
@MainActor
final class ProEntitlementTests: XCTestCase {
    // MARK: - applyProStatus matrix (parameterized / data-driven)
    func test_applyProStatus_dataDriven() {
        let cases: [(name: String, initialFrequency: Double, initialPro: Bool, isPro: Bool, expectedFrequency: Double, expectedPro: Bool)] = [
            ("free user always capped at 15s", 15, false, false, ProFeatures.freePollingInterval, false),
            ("free user with stored pro speed downgraded to 15s", 5, true, false, ProFeatures.freePollingInterval, false),
            ("pro upgrade from free default gets 1s", 15, false, true, ProFeatures.defaultProPollingInterval, true),
            ("pro upgrade from 15 gets 1s", 15, false, true, ProFeatures.defaultProPollingInterval, true),
            ("pro user keeps custom speed below 15s", 5, true, true, 5, true),
            ("pro user keeps 10s preference", 10, true, true, 10, true),
        ]
        
        for testCase in cases {
            XCTContext.runActivity(named: testCase.name) { _ in
                // Given
                let storage = MockUserDataStorage()
                
                // presave initial data
                storage.save(key: SettingsService.StorageKey.updateFrequency, value: testCase.initialFrequency)
                storage.save(key: SettingsService.StorageKey.isProActive, value: testCase.initialPro)
                
                let service = SettingsService(storage: storage)
                // When
                service.applyProStatus(testCase.isPro)
                
                // Then
                XCTAssertEqual(service.state.updateFrequency, testCase.expectedFrequency, testCase.name)
                XCTAssertEqual(service.state.isProActive, testCase.expectedPro, testCase.name)
                XCTAssertEqual(
                    storage.value(forKey: SettingsService.StorageKey.isProActive) as? Bool,
                    testCase.expectedPro,
                    testCase.name
                )
            }
        }
    }
    
    func test_givenCachedProFalseAndStoredFastFrequency_whenInit_thenClampsToFreeTier() {
        // Given
        let storage = MockUserDataStorage()
        storage.save(key: SettingsService.StorageKey.updateFrequency, value: 5.0)
        storage.save(key: SettingsService.StorageKey.isProActive, value: false)
        // When
        let service = SettingsService(storage: storage)
        // Then
        XCTAssertFalse(service.state.isProActive)
        XCTAssertEqual(service.state.updateFrequency, ProFeatures.freePollingInterval)
    }
    
    func test_givenCachedProTrueAndStored10s_whenInit_thenKeepsProFrequency() {
        // Given
        let storage = MockUserDataStorage()
        storage.save(key: SettingsService.StorageKey.updateFrequency, value: 10.0)
        storage.save(key: SettingsService.StorageKey.isProActive, value: true)
        // When
        let service = SettingsService(storage: storage)
        // Then
        XCTAssertTrue(service.state.isProActive)
        XCTAssertEqual(service.state.updateFrequency, 10.0)
    }
    
    func test_givenNoPersistedValues_whenInit_thenDefaultsToFreeTier() {
        let service = SettingsService(storage: MockUserDataStorage())
        XCTAssertFalse(service.state.isProActive)
        XCTAssertEqual(service.state.updateFrequency, ProFeatures.freePollingInterval)
    }
}
