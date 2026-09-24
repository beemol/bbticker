import Foundation
import Combine
import LLCore

extension ExchangeType {
    /// Stable identifier for the exchange + environment pair, used as a credential account key.
    /// Format: "bybit:production", "kucoin:testnet", etc.
    var envIDString: String {
        "\(identifier.rawValue):\(environment.rawValue)"
    }
}

@MainActor
protocol SettingsServiceProtocol: ObservableObject {
    var state: SettingsState { get }
    
    // TODO: to be removed all 3 of them, but don't forget about tests
    func setExchangeType(_ exchangeType: Exchange)
    func setUpdateFrequency(_ frequency: Double)
    func setShowMarginLevelDot(_ enabled: Bool)
    func setBalanceNotificationsEnabled(_ enabled: Bool)
    func applyProStatus(_ unlocked: Bool)
    
    // UI-facing bridge bindings
    var selectedExchangeBinding: Binding<ExchangeIdentifier> { get }
    var selectedWalletBinding: Binding<WalletType> { get }
    var selectedAPIEnvironmentBinding: Binding<APIEnvironment> { get }
    
    /// The available API environments for the currently selected exchange
    var availableAPIEnvironments: [APIEnvironment] { get }
}

extension SettingsServiceProtocol {
    // UI helpers — Bindings that READ from state (so the view refreshes)
    var selectedExchangeBinding: Binding<ExchangeIdentifier> {
        Binding(
            get: { self.state.exchangeType.identifier },
            set: { [weak self] newExchangeName in
                guard let self else { return }
                let current = self.state.exchangeType
                self.setExchangeType(Exchange(newExchangeName, environment: current.environment, wallet: current.walletType))
            }
        )
    }

    var selectedWalletBinding: Binding<WalletType> {
        Binding(
            get: { self.state.exchangeType.walletType },
            set: { [weak self] newWalletType in
                guard let self else { return }
                let current = self.state.exchangeType
                self.setExchangeType(Exchange(current.identifier, environment: current.environment, wallet: newWalletType))
            }
        )
    }

    var selectedAPIEnvironmentBinding: Binding<APIEnvironment> {
        Binding(
            get: { self.state.exchangeType.environment },
            set: { [weak self] newEnvironment in
                guard let self else { return }
                let current = self.state.exchangeType
                self.setExchangeType(Exchange(current.identifier, environment: newEnvironment, wallet: current.walletType))
            }
        )
    }

    var availableAPIEnvironments: [APIEnvironment] {
        ExchangeRegistry.shared
            .capabilities(for: self.state.exchangeType.identifier)?
            .availableEnvironments ?? [.production]
    }
}

import SwiftUI

@Observable
@MainActor
final class SettingsState {
    var updateFrequency: Double = ProFeatures.freePollingInterval
    var exchangeType: Exchange = Exchange(.bybit, wallet: .unified)
    var isProActive: Bool = false
    var showMarginLevelDot: Bool = true
    var balanceNotificationsEnabled: Bool = false
}

/// Shared service for app settings that can be observed reactively
final class SettingsService: SettingsServiceProtocol {
    
    enum StorageKey {
        static let isProActive: String = "iap_ispro_unlocked"
        static let selectExchangeType: String = "selected_exchange_type"
        static let updateFrequency: String = "update_frequency"
        static let showMarginLevelDot: String = "pro_margin_level_dot"
        static let balanceNotificationsEnabled: String = "balance_notifications_enabled"
    }
    
    let state = SettingsState()
    
    private let storage: UserDataStorageProtocol
    
    init(storage: UserDataStorageProtocol = UserDefaultsStorage()) {
        self.storage = storage
        // print("[SettingsService] initialized")
        
        loadUpdateFrequency()
        loadExchangeType()
        loadShowMarginLevelDot()
        loadBalanceNotificationsEnabled()
        
        // Load cached IAP unlock state for fast UI reflect
        let cached = storage.value(forKey: StorageKey.isProActive) as? Bool ?? false
        state.isProActive = cached
        
        applyProStatus(state.isProActive)
    }
    
    func setUpdateFrequency(_ frequency: Double) {
        state.updateFrequency = frequency
        storage.save(key: StorageKey.updateFrequency, value: frequency)
    }
    
    func setShowMarginLevelDot(_ enabled: Bool) {
        state.showMarginLevelDot = enabled
        storage.save(key: StorageKey.showMarginLevelDot, value: enabled)
    }
    
    func setBalanceNotificationsEnabled(_ enabled: Bool) {
        state.balanceNotificationsEnabled = enabled
        storage.save(key: StorageKey.balanceNotificationsEnabled, value: enabled)
    }
    
    func setExchangeType(_ newExchangeType: Exchange) {
        state.exchangeType = normalized(newExchangeType)
        save(newExchangeType: state.exchangeType)
    }
    
    /// Returns an exchange with supported wallet type and environment, falling back to safe values otherwise.
    private func normalized(_ exchange: Exchange) -> Exchange {
        var result = exchange
        
        if result.availableWalletTypes.contains(result.walletType) == false {
            AppLog.settings.warning("Attempted to set unsupported wallet type. Falling back to a safe one.")
            if let first = result.availableWalletTypes.first {
                result = Exchange(result.identifier, environment: result.environment, wallet: first)
            } else {
                result = Exchange(.bybit, environment: result.environment, wallet: .unified)
            }
        }
        
        if result.availableEnvironments.contains(result.environment) == false {
            AppLog.settings.warning("Attempted to set unsupported environment. Falling back to a safe one.")
            if let first = result.availableEnvironments.first {
                result = Exchange(result.identifier, environment: first, wallet: result.walletType)
            } else {
                result = Exchange(result.identifier, environment: .production, wallet: result.walletType)
            }
        }
        
        return result
    }
    
    private func save(newExchangeType: ExchangeType) {
        let serializedValue = "\(newExchangeType.identifier.rawValue):\(newExchangeType.walletType.rawValue):\(newExchangeType.environment.rawValue)"
        
        storage.save(key: StorageKey.selectExchangeType, value: serializedValue)

        Task.detached {
            await AnalyticsManager.shared.track(.settingsChange(key: "exchange_type_changed_to", newValue: newExchangeType.displayName))
        }
    }
    
    private func loadUpdateFrequency() {
        let storedFrequency = storage.value(forKey: StorageKey.updateFrequency) as? Double
        state.updateFrequency = storedFrequency ?? ProFeatures.freePollingInterval
    }
    
    private func loadShowMarginLevelDot() {
        if let stored = storage.value(forKey: StorageKey.showMarginLevelDot) as? Bool {
            state.showMarginLevelDot = stored
        }
    }
    
    private func loadBalanceNotificationsEnabled() {
        if let stored = storage.value(forKey: StorageKey.balanceNotificationsEnabled) as? Bool {
            state.balanceNotificationsEnabled = stored
        }
    }
    
    private func loadExchangeType() {
        guard let stored = storage.value(forKey: StorageKey.selectExchangeType) as? String else {
            state.exchangeType = Exchange(.bybit, wallet: .unified)
            return
        }
        
        let parts = stored.split(separator: ":").map(String.init)
        guard parts.count >= 2,
              let walletType = WalletType(rawValue: parts[1]) else {
            // Fallback for legacy values or unknown formats
            state.exchangeType = Exchange(.bybit, wallet: .unified)
            return
        }
        
        let identifier = ExchangeIdentifier(rawValue: parts[0])
        
        // Validate if this exchange registered
        guard ExchangeRegistry.shared.capabilities(for: identifier) != nil else {
            state.exchangeType = Exchange(.bybit, wallet: .unified)
            return
        }
        
        // Environment was introduced later; legacy values use a 2-part format without it.
        var environment: APIEnvironment = .production
        if parts.count >= 3, let parsed = APIEnvironment(rawValue: parts[2]) {
            environment = parsed
        }
        
        state.exchangeType = normalized(Exchange(identifier, environment: environment, wallet: walletType))
    }

    // MARK: - IAP
    func applyProStatus(_ isPro: Bool) {
        state.isProActive = isPro
        storage.save(key: StorageKey.isProActive, value: isPro)
        
        if isPro {
            if state.updateFrequency > ProFeatures.proPollingOptions.max() ?? 10 {
                setUpdateFrequency(ProFeatures.defaultProPollingInterval)
            }
        } else {
            setUpdateFrequency(ProFeatures.freePollingInterval)
        }
    }
}
