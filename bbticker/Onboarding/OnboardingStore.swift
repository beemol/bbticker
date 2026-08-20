//
//  OnboardingStore.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 20/08/2026.
//

import Foundation
import Observation

/// Coordinates the first-run onboarding flow.
/// Owns presentation state (whether the tutorial is visible) and the one-time "has the user completed onboarding" flag persisted in UserDefaults.
@MainActor
@Observable
final class OnboardingStore {

    static let storageKey = "onboarding_completed"

    private let storage: UserDataStorageProtocol

    /// Whether the tutorial UI is currently presented.
    var isPresented = false

    /// Zero-based index of the page currently shown.
    var currentPage = 0

    /// Number of pages in the flow.
    var pageCount: Int { OnboardingPage.allCases.count }

    private(set) var hasCompleted: Bool

    init(storage: UserDataStorageProtocol = UserDefaultsStorage()) {
        self.storage = storage
        self.hasCompleted = storage.value(forKey: Self.storageKey) as? Bool ?? false
    }

    var needsOnboarding: Bool {
        !hasCompleted
    }

    // MARK: - Presentation

    func presentIfNeeded() {
        // TODO: guard needsOnboarding, then set isPresented = true
    }

    func dismiss() {
        // TODO: set isPresented = false
    }

    // MARK: - Actions

    func complete() {
        // TODO: persist hasCompleted, dismiss
        // TODO: track onboarding completed via AnalyticsManager
    }

    func skip() {
        // TODO: persist hasCompleted, dismiss
        // TODO: track onboarding skipped via AnalyticsManager
    }

    func next() {
        // TODO: advance currentPage, clamped to pageCount
    }

    func previous() {
        // TODO: go back one page, clamped to 0
    }
}
