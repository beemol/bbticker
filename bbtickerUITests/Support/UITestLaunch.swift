//
//  UITestLaunch.swift
//  bbtickerUITests
//
//  Created by Aleh Fiodarau on 26/06/2026.
//

import XCTest

enum UITestLaunch {
    static let bundleIdentifier = "com.afiodarau.bbticker"
    static let uiTestingFlag = "-UITestingEnabled"
    
    @MainActor
    @discardableResult
    static func app(additionalArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication(bundleIdentifier: bundleIdentifier)
        app.launchArguments = [uiTestingFlag] + additionalArguments
        app.launch()
        return app
    }
}
