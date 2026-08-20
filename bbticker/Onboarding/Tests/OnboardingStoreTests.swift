//
//  OnboardingStoreTests.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 20/08/2026.
//

import Testing
@testable import bbticker

@MainActor
struct OnboardingStoreTests {

    private func makeStore(storage: UserDataStorageProtocol = MockUserDataStorage()) -> OnboardingStore {
        OnboardingStore(storage: storage)
    }

    // MARK: - Initial state

    @Test func needsOnboardingIsTrueOnFirstLaunch() {
        let store = makeStore()

        #expect(store.needsOnboarding)
        #expect(!store.hasCompleted)
    }

    @Test func currentPageStartsAtZero() {
        let store = makeStore()

        #expect(store.currentPage == 0)
    }

    @Test func isNotPresentedInitially() {
        let store = makeStore()

        #expect(!store.isPresented)
    }

    @Test func pageCountMatchesOnboardingPages() {
        let store = makeStore()

        #expect(store.pageCount == OnboardingPage.allCases.count)
    }

    // MARK: - Presentation

    @Test func presentIfNeededShowsTutorialWhenNotCompleted() {
        let store = makeStore()

        store.presentIfNeeded()

        #expect(store.isPresented)
    }

    @Test func presentIfNeededStartsAtFirstPage() {
        let store = makeStore()
        store.next()
        store.next()
        #expect(store.currentPage == 2)

        store.presentIfNeeded()

        #expect(store.currentPage == 0)
        #expect(store.isPresented)
    }

    @Test func presentIfNeededDoesNothingWhenCompleted() {
        let store = makeStore()
        store.complete()

        store.presentIfNeeded()

        #expect(!store.isPresented)
    }

    @Test func dismissHidesTutorial() {
        let store = makeStore()
        store.presentIfNeeded()

        store.dismiss()

        #expect(!store.isPresented)
    }

    // MARK: - Completion & persistence

    @Test func completePersistsCompletionFlag() {
        let storage = MockUserDataStorage()
        let store = OnboardingStore(storage: storage)

        store.complete()

        #expect(store.hasCompleted)
        #expect(!store.needsOnboarding)
        #expect(!store.isPresented)

        // A fresh store over the same storage must read the persisted flag.
        let reloaded = OnboardingStore(storage: storage)
        #expect(reloaded.hasCompleted)
        #expect(!reloaded.needsOnboarding)
    }

    @Test func skipPersistsCompletionFlag() {
        let storage = MockUserDataStorage()
        let store = OnboardingStore(storage: storage)

        store.skip()

        #expect(store.hasCompleted)
        #expect(!store.needsOnboarding)
        #expect(!store.isPresented)

        let reloaded = OnboardingStore(storage: storage)
        #expect(reloaded.hasCompleted)
        #expect(!reloaded.needsOnboarding)
    }

    @Test func storeLoadedWithPersistedCompletionDoesNotNeedOnboarding() {
        let storage = MockUserDataStorage()
        storage.save(key: OnboardingStore.storageKey, value: true)

        let store = OnboardingStore(storage: storage)

        #expect(store.hasCompleted)
        #expect(!store.needsOnboarding)
        #expect(!store.isPresented)
    }

    // MARK: - Navigation

    @Test func nextAdvancesCurrentPage() {
        let store = makeStore()

        store.next()
        #expect(store.currentPage == 1)

        store.next()
        #expect(store.currentPage == 2)
    }

    @Test func nextClampsAtLastPage() {
        let store = makeStore()

        for _ in 0..<(OnboardingPage.allCases.count + 5) {
            store.next()
        }

        #expect(store.currentPage == store.pageCount - 1)
    }

    @Test func previousGoesBack() {
        let store = makeStore()
        store.next()
        store.next()

        store.previous()

        #expect(store.currentPage == 1)
    }

    @Test func previousClampsAtFirstPage() {
        let store = makeStore()

        store.previous()

        #expect(store.currentPage == 0)
    }
}
