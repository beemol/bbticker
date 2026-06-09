import Foundation
import StoreKit

protocol IAPManagerProtocol: Actor {
    func isUnlocked() async -> Bool
    func purchaseUnlock() async throws -> Bool
    func restorePurchases() async -> Bool
}

// make it an actor since I consider to add caching in the future
actor IAPManager: IAPManagerProtocol {
    static let shared = IAPManager()

    // Update with your App Store Connect product identifier
    private let unlockProductId = getBundleIdentifier() + ".updatefrequency.unlock"

    private init() {}

    func isUnlocked() async -> Bool {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == unlockProductId {
                return true
            }
        }
        return false
    }

    func purchaseUnlock() async throws -> Bool {
        guard let product = try await Product.products(for: [unlockProductId]).first else {
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

    func restorePurchases() async -> Bool {
        do {
            try await AppStore.sync()
            return await isUnlocked()
        } catch {
            return false
        }
    }
}


