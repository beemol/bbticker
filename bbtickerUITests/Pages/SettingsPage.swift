//
//  SettingsPage.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 26/06/2026.
//

import XCTest

@MainActor
struct SettingsPage {
    let app: XCUIApplication
    
    var proSectionHeader: XCUIElement { app.staticTexts["BBTicker Pro"] }
}
