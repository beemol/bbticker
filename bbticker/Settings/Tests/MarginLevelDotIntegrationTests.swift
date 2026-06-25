//
//  MarginLevelDotIntegrationTests.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 25/06/2026.
//

import XCTest
@testable import bbticker

// Integration test for the margin dot preference: Settings binding → persistence → menu bar rule.
@MainActor
final class MarginLevelDotIntegrationTests: XCTestCase {
    
    func test_givenProUser_whenToggleMarginDotViaSettingsBinding_thenPersistsAndControlsMenuBarDot() {
        // Given — Pro user with default dot enabled
        let storage = MockUserDataStorage()
        let settingsService = SettingsService(storage: storage)
        settingsService.applyProStatus(true)
        
        let viewModel = SettingsViewModel(
            settingsService: settingsService,
            credentialManager: MockCredentialManager(),
            sharedDataService: MockSharedDataManager(),
            iapManager: SpyIAPManager()
        )
        
        XCTAssertTrue(viewModel.isProActive)
        XCTAssertTrue(settingsService.state.showMarginLevelDot)
        XCTAssertTrue(menuBarShowsMarginDot(settingsService))
        
        // When — user disables the dot via Settings toggle binding
        viewModel.showMarginLevelDotBinding.wrappedValue = false
        
        // Then — state, storage, and menu bar visibility
        XCTAssertFalse(settingsService.state.showMarginLevelDot)
        XCTAssertEqual(storage.value(forKey: SettingsService.StorageKey.showMarginLevelDot) as? Bool, false)
        XCTAssertFalse(menuBarShowsMarginDot(settingsService))
        
        // When — simulate app relaunch from persisted storage
        let reloaded = SettingsService(storage: storage)
        
        // Then — preference survives relaunch; dot stays hidden
        XCTAssertTrue(reloaded.state.isProActive)
        XCTAssertFalse(reloaded.state.showMarginLevelDot)
        XCTAssertFalse(menuBarShowsMarginDot(reloaded))
        
        // When — user re-enables the dot
        viewModel.showMarginLevelDotBinding.wrappedValue = true
        
        // Then — persisted and visible again after reload
        let relaunched = SettingsService(storage: storage)
        XCTAssertTrue(relaunched.state.showMarginLevelDot)
        XCTAssertTrue(menuBarShowsMarginDot(relaunched))
    }
    
    /// Mirrors `MenuBarLabelView.showsMarginLevelDot`.
    private func menuBarShowsMarginDot(_ settingsService: SettingsService) -> Bool {
        settingsService.state.isProActive && settingsService.state.showMarginLevelDot
    }
}
