//
//  RouterTests.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 10/1/26.
//

import Testing
@testable import bbticker

struct RouterTests {
    @MainActor
    @Test func test_bybitCompletion_presentsSettings() {
        let router = IOSRouter()

        router.navigate(to: .settings(section: nil))

        #expect(router.presentedSheet == .settings(section: nil))
    }
}
