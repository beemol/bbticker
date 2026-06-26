//
//  MenuBarApp.swift
//  bbtickerUITests
//
//  Created by Aleh Fiodarau on 26/06/2026.
//

import XCTest

// Page object for the menu bar extra and its popover entry points.
@MainActor
struct MenuBarApp {
    let app: XCUIApplication
    
    init(app: XCUIApplication) {
        self.app = app
    }
    
    static func launch(additionalArguments: [String] = []) -> MenuBarApp {
        MenuBarApp(app: UITestLaunch.app(additionalArguments: additionalArguments))
    }
    
    // try identifier, then label, then balance text
    var menuBarStatusItem: XCUIElement {
        let identifier = AccessibilityID.menuBarStatusItem
        let candidates: [XCUIElement] = [
            app.descendants(matching: .any)
                .matching(NSPredicate(format: "identifier == %@", identifier))
                .firstMatch,
            app.menuBars.buttons[identifier],
            app.menuBars.buttons["BBTicker balance"],
            app.menuBars.images[identifier],
            // Fresh launch with no connection shows "0.0" in the menu bar label.
            app.menuBars.staticTexts["0.0"],
        ]
        
        for candidate in candidates where candidate.exists {
            return candidate
        }
        
        return candidates[0]
    }
    
    @discardableResult
    func openPopover() -> Bool {
        guard UITestUtils.waitFor(element: menuBarStatusItem) else { return false }
        menuBarStatusItem.click()
        return popoverSettingsButton.waitForExistence(timeout: 5)
    }
    
    var popoverSettingsButton: XCUIElement {
        app.buttons[AccessibilityID.popoverSettingsButton]
    }
    
    func openSettings() -> Bool {
        guard UITestUtils.waitFor(element: popoverSettingsButton) else { return false }
        popoverSettingsButton.click()
        return app.windows["Settings"].waitForExistence(timeout: 5) || app.staticTexts["Settings"].waitForExistence(timeout: 5)
    }
}
