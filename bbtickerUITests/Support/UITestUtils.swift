//
//  UITestUtils.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 26/06/2026.
//

import XCTest

enum UITestUtils {

    @MainActor
    @discardableResult
    static func waitFor(element: XCUIElement, timeout: TimeInterval = 15) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if element.exists { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        return element.exists
    }
}
