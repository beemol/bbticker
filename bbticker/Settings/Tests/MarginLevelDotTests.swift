//
//  MarginLevelDotTests.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 25/06/2026.
//

import XCTest
@testable import bbticker

@MainActor
final class MarginLevelDotTests: XCTestCase {
    
    // MARK: - SettingsService
    
    func test_givenNoStoredValue_whenInit_thenMarginDotDefaultsToTrue() {
        let service = SettingsService(storage: MockUserDataStorage())
        XCTAssertTrue(service.state.showMarginLevelDot)
    }
    
    func test_givenStoredMarginDotPreference_whenInit_thenLoadsFromStorage() {
        let storage = MockUserDataStorage()
        storage.save(key: SettingsService.StorageKey.showMarginLevelDot, value: false)
        
        let service = SettingsService(storage: storage)
        
        XCTAssertFalse(service.state.showMarginLevelDot)
    }
    
    func test_setShowMarginLevelDot_persistsToStorage() {
        let storage = MockUserDataStorage()
        let service = SettingsService(storage: storage)
        
        service.setShowMarginLevelDot(false)
        
        XCTAssertFalse(service.state.showMarginLevelDot)
        XCTAssertEqual(
            storage.value(forKey: SettingsService.StorageKey.showMarginLevelDot) as? Bool,
            false
        )
    }
    
    func test_givenDotEnabled_whenDowngradeToFree_thenMarginDotPreferenceUnchanged() {
        let storage = MockUserDataStorage()
        storage.save(key: SettingsService.StorageKey.showMarginLevelDot, value: true)
        storage.save(key: SettingsService.StorageKey.isProActive, value: true)
        
        let service = SettingsService(storage: storage)
        service.applyProStatus(false)
        
        XCTAssertFalse(service.state.isProActive)
        XCTAssertTrue(service.state.showMarginLevelDot)
    }
    
    // MARK: - Menu bar visibility rule
    
    func test_menuBarShowsMarginDot_dataDriven() {
        let cases: [(name: String, isPro: Bool, dotEnabled: Bool, expected: Bool)] = [
            ("free user with dot on — hidden", false, true, false),
            ("free user with dot off — hidden", false, false, false),
            ("pro user with dot on — visible", true, true, true),
            ("pro user with dot off — hidden", true, false, false),
        ]
        
        for testCase in cases {
            XCTContext.runActivity(named: testCase.name) { _ in
                let storage = MockUserDataStorage()
                storage.save(key: SettingsService.StorageKey.isProActive, value: testCase.isPro)
                storage.save(key: SettingsService.StorageKey.showMarginLevelDot, value: testCase.dotEnabled)
                
                let service = SettingsService(storage: storage)
                
                XCTAssertEqual(
                    menuBarShowsMarginDot(service),
                    testCase.expected,
                    testCase.name
                )
            }
        }
    }
    
    // MARK: - ViewModel binding
    
    func test_showMarginLevelDotBinding_reflectsAndUpdatesService() {
        let storage = MockUserDataStorage()
        let settingsService = SettingsService(storage: storage)
        settingsService.applyProStatus(true)
        
        let viewModel = SettingsViewModel(
            settingsService: settingsService,
            credentialManager: MockCredentialManager(),
            sharedDataService: MockSharedDataManager(),
            iapManager: SpyIAPManager()
        )
        
        XCTAssertTrue(viewModel.showMarginLevelDotBinding.wrappedValue)
        
        viewModel.showMarginLevelDotBinding.wrappedValue = false
        
        XCTAssertFalse(settingsService.state.showMarginLevelDot)
        XCTAssertEqual(
            storage.value(forKey: SettingsService.StorageKey.showMarginLevelDot) as? Bool,
            false
        )
    }
    
    // Mirrors `MenuBarLabelView.showsMarginLevelDot`.
    private func menuBarShowsMarginDot(_ settingsService: SettingsService) -> Bool {
        settingsService.state.isProActive && settingsService.state.showMarginLevelDot
    }
}
