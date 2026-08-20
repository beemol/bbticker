//
//  OnboardingStoreTests.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 20/08/2026.
//

import XCTest
@testable import bbticker

@MainActor
final class OnboardingStoreTests: XCTestCase {

    private var store: OnboardingStore!
    private let storage = UserDefaultsStorage()

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: OnboardingStore.storageKey)
        store = OnboardingStore(storage: storage)
    }

    func testNeedsOnboardingOnFirstLaunch() {
        // TODO
    }

    func testCompletePersistsCompletion() {
        // TODO
    }

    func testSkipPersistsCompletion() {
        // TODO
    }

    func testPageNavigationClampsAtBounds() {
        // TODO
    }

    func testPresentIfNeededDoesNotShowWhenCompleted() {
        // TODO
    }
}
