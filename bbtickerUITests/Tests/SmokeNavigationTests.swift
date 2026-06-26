//
//  SmokeNavigationTests.swift
//  bbtickerUITests
//
//  Created by Aleh Fiodarau on 26/06/2026.
//

import XCTest

@MainActor
final class SmokeNavigationTests: XCTestCase {
    
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    func test_appLaunch_showsMenuBarItem() throws {
        let menuBar = MenuBarApp.launch()
        
        XCTAssertTrue(
            UITestUtils.waitFor(element: menuBar.menuBarStatusItem),
            "Expected menu bar status item with identifier '\(AccessibilityID.menuBarStatusItem)'"
        )
    }
    
    func test_openPopover_showsSettingsButton() throws {
        let menuBar = MenuBarApp.launch()
        
        XCTAssertTrue(
            menuBar.openPopover(),
            "Expected popover with Settings button '\(AccessibilityID.popoverSettingsButton)'"
        )
        XCTAssertTrue(menuBar.popoverSettingsButton.isHittable)
    }
    
    func test_openSettings_showsProSection() throws {
        let menuBar = MenuBarApp.launch()
        let settingsPage = SettingsPage(app: menuBar.app)
        
        XCTAssertTrue(menuBar.openPopover(), "Expected popover with Settings button '\(AccessibilityID.popoverSettingsButton)'")
        XCTAssertTrue(menuBar.openSettings(), "expect Settings view to be open")
        XCTAssertTrue(settingsPage.proSectionHeader.waitForExistence(timeout: 1.0))
    }
}
