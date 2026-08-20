//
//  OnboardingStore.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 20/08/2026.
//

import Foundation
import Observation

/// Coordinates the first-run onboarding flow.
/// Owns presentation state (whether the tutorial is visible) and the
/// one-time "has the user completed onboarding" flag persisted in UserDefaults.
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
        guard needsOnboarding else { return }
        currentPage = 0
        isPresented = true
    }

    func dismiss() {
        isPresented = false
    }

    // MARK: - Actions

    /// Marks onboarding as done, persists it, and hides the tutorial.
    func complete() {
        hasCompleted = true
        storage.save(key: Self.storageKey, value: true)
        isPresented = false
        // TODO: track onboarding completed via AnalyticsManager
    }

    /// Same as `complete()`, used when the user bails out early so the
    /// tutorial never nags again.
    func skip() {
        hasCompleted = true
        storage.save(key: Self.storageKey, value: true)
        isPresented = false
        // TODO: track onboarding skipped via AnalyticsManager
    }

    func next() {
        guard currentPage < pageCount - 1 else { return }
        currentPage += 1
    }

    func previous() {
        guard currentPage > 0 else { return }
        currentPage -= 1
    }
}
