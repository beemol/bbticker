import Foundation
import StoreKit

enum ProFeatures {
    static let freePollingInterval: Double = 15
    static let proPollingOptions: [Double] = [1, 5, 10]
    static let defaultProPollingInterval: Double = 1
}

protocol IAPManagerProtocol: Actor {
    func isProActive() async -> Bool
    func purchasePro() async throws -> Bool
    func restorePurchases() async -> Bool
    
    func startObservingTransactions(onProStatusChange: @escaping @Sendable (Bool) -> Void)
}

actor IAPManager: IAPManagerProtocol {
    static let shared = IAPManager()

    private let proSubscriptionProductId = getBundleIdentifier() + ".pro.unlock"

    private init() {}

    func isProActive() async -> Bool {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == proSubscriptionProductId {
                return true
            }
        }
        return false
    }

    func purchasePro() async throws -> Bool {
        guard let product = try await Product.products(for: [proSubscriptionProductId]).first else {
            return false
        }

        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                await transaction.finish()
                return true
            case .unverified:
                return false
            }
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }
    
    func startObservingTransactions(onProStatusChange: @escaping @Sendable (Bool) -> Void) {
        Task {
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                if transaction.productID == proSubscriptionProductId {
                    await transaction.finish()
                    let active = await isProActive()
                    onProStatusChange(active)
                }
            }
        }
    }

    func restorePurchases() async -> Bool {
        do {
            try await AppStore.sync()
            return await isProActive()
        } catch {
            return false
        }
    }
}


