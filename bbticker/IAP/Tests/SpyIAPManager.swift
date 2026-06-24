//
//  SpyIAPManager.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 24/06/2026.
//

import Foundation
@testable import bbticker

// Spy test double for IAPManagerProtocol
actor SpyIAPManager: IAPManagerProtocol {
    enum PurchaseOutcome: Sendable {
        case success(Bool)
        case failure(Error)
    }
    private(set) var isProActiveCallCount = 0
    private(set) var purchaseProCallCount = 0
    private(set) var restorePurchasesCallCount = 0
    private(set) var startObservingCallCount = 0
    
    var isProActiveResult = false
    var purchaseOutcome: PurchaseOutcome = .success(true)
    var restorePurchasesResult = false
    
    private var proStatusObserver: (@Sendable (Bool) -> Void)?
    
    func reset() {
        isProActiveCallCount = 0
        purchaseProCallCount = 0
        restorePurchasesCallCount = 0
        startObservingCallCount = 0
        isProActiveResult = false
        purchaseOutcome = .success(true)
        restorePurchasesResult = false
        proStatusObserver = nil
    }
    
    func configure(
        isProActive: Bool? = nil,
        purchaseOutcome: PurchaseOutcome? = nil,
        restorePurchases: Bool? = nil
    ) {
        if let isProActive { isProActiveResult = isProActive }
        if let purchaseOutcome { self.purchaseOutcome = purchaseOutcome }
        if let restorePurchases { restorePurchasesResult = restorePurchases }
    }
    
    // Simulates StoreKit Transaction.updates delivering a new entitlement state
    func simulateProStatusChange(_ isPro: Bool) {
        proStatusObserver?(isPro)
    }
    
    // MARK: - IAPManagerProtocol
    func isProActive() async -> Bool {
        isProActiveCallCount += 1
        return isProActiveResult
    }
    func purchasePro() async throws -> Bool {
        purchaseProCallCount += 1
        switch purchaseOutcome {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
    
    func restorePurchases() async -> Bool {
        restorePurchasesCallCount += 1
        return restorePurchasesResult
    }
    
    func startObservingTransactions(onProStatusChange: @escaping @Sendable (Bool) -> Void) {
        startObservingCallCount += 1
        proStatusObserver = onProStatusChange
    }
}

