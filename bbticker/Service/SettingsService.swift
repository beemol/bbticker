import Foundation
import Combine
import LLCore

extension Exchange {
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
    func setExchange(_ exchange: Exchange)
    func setUpdateFrequency(_ frequency: Double)
    func setShowMarginLevelDot(_ enabled: Bool)
    func setBalanceNotificationsEnabled(_ enabled: Bool)
    func applyProStatus(_ unlocked: Bool)
    func credentialsChanged()
    
    // UI-facing bridge bindings
    var selectedExchangeBinding: Binding<ExchangeIdentifier> { get }
    var selectedWalletBinding: Binding<WalletType> { get }
    var selectedAPIEnvironmentBinding: Binding<APIEnvironment> { get }
    
    /// The available API environments for the currently selected exchange
    var availableExchanges: [ExchangeIdentifier] { get }
    var availableAPIEnvironments: [APIEnvironment] { get }
    var availableWalletTypes: [WalletType] { get }
    var exchangeConfiguration: ExchangeConfiguration? { get }
}

extension SettingsServiceProtocol {
    // UI helpers — Bindings that READ from state (so the view refreshes)
    var selectedExchangeBinding: Binding<ExchangeIdentifier> {
        Binding(
            get: { self.state.exchange.identifier },
            set: { [weak self] newExchangeName in
                guard let self else { return }
                let current = self.state.exchange
                self.setExchange(Exchange(newExchangeName, environment: current.environment, wallet: current.walletType))
            }
        )
    }

    var selectedWalletBinding: Binding<WalletType> {
        Binding(
            get: { self.state.exchange.walletType },
            set: { [weak self] newWalletType in
                guard let self else { return }
                let current = self.state.exchange
                self.setExchange(Exchange(current.identifier, environment: current.environment, wallet: newWalletType))
            }
        )
    }

    var selectedAPIEnvironmentBinding: Binding<APIEnvironment> {
        Binding(
            get: { self.state.exchange.environment },
            set: { [weak self] newEnvironment in
                guard let self else { return }
                let current = self.state.exchange
                self.setExchange(Exchange(current.identifier, environment: newEnvironment, wallet: current.walletType))
            }
        )
    }
}

import SwiftUI

@Observable
@MainActor
final class SettingsState {
    var updateFrequency: Double = ProFeatures.freePollingInterval
    var exchange: Exchange = Exchange(.bybit, wallet: .unified)
    var isProActive: Bool = false
    var showMarginLevelDot: Bool = true
    var balanceNotificationsEnabled: Bool = false
    
    var credentialsRevision: Int = 0
}

/// Shared service for app settings that can be observed reactively
final class SettingsService: SettingsServiceProtocol {
    enum StorageKey {
        static let isProActive: String = "iap_ispro_unlocked"
        static let selectExchange: String = "selected_exchange_type"
        static let updateFrequency: String = "update_frequency"
        static let showMarginLevelDot: String = "pro_margin_level_dot"
        static let balanceNotificationsEnabled: String = "balance_notifications_enabled"
    }
    
    let state = SettingsState()
    
    var exchangeConfiguration: ExchangeConfiguration? {
        exchangeRegistry.configuration(for: state.exchange)
    }
    
    private let storage: UserDataStorageProtocol
    private let exchangeRegistry: ExchangeRegistryProtocol
    
    var availableExchanges: [ExchangeIdentifier] {
        exchangeRegistry.availableExchanges
    }
    
    var availableAPIEnvironments: [APIEnvironment] {
        exchangeRegistry
            .capabilities(for: self.state.exchange.identifier)?
            .availableEnvironments ?? [.production]
    }
    
    var availableWalletTypes: [WalletType] {
        exchangeRegistry
            .capabilities(for: self.state.exchange.identifier)?
            .availableWalletTypes ?? [.spot]
    }
    
    init(storage: UserDataStorageProtocol = UserDefaultsStorage(), exchangeRegistry: ExchangeRegistryProtocol) {
        self.storage = storage
        self.exchangeRegistry = exchangeRegistry
        // print("[SettingsService] initialized")
        
        loadUpdateFrequency()
        loadExchange()
        loadShowMarginLevelDot()
        loadBalanceNotificationsEnabled()
        
        // Load cached IAP unlock state for fast UI reflect
        let cached = storage.value(forKey: StorageKey.isProActive) as? Bool ?? false
        state.isProActive = cached
        
        applyProStatus(state.isProActive)
    }
    
    func credentialsChanged() {
        state.credentialsRevision &+= 1
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
    
    func setExchange(_ newExchange: Exchange) {
        state.exchange = normalized(newExchange)
        save(newExchange: state.exchange)
    }
    
    /// Returns an exchange with supported wallet type and environment, falling back to safe values otherwise.
    private func normalized(_ exchange: Exchange) -> Exchange {
        var result = exchange
        
        if availableWalletTypes.contains(result.walletType) == false {
            AppLog.settings.warning("Attempted to set unsupported wallet type. Falling back to a safe one.")
            if let first = availableWalletTypes.first {
                result = Exchange(result.identifier, environment: result.environment, wallet: first)
            } else {
                result = Exchange(.bybit, environment: result.environment, wallet: .unified)
            }
        }
        
        if availableAPIEnvironments.contains(result.environment) == false {
            AppLog.settings.warning("Attempted to set unsupported environment. Falling back to a safe one.")
            if let first = availableAPIEnvironments.first {
                result = Exchange(result.identifier, environment: first, wallet: result.walletType)
            } else {
                result = Exchange(result.identifier, environment: .production, wallet: result.walletType)
            }
        }
        
        return result
    }
    
    private func save(newExchange: Exchange) {
        let serializedValue = "\(newExchange.identifier.rawValue):\(newExchange.walletType.rawValue):\(newExchange.environment.rawValue)"
        
        storage.save(key: StorageKey.selectExchange, value: serializedValue)

        Task.detached {
            await AnalyticsManager.shared.track(.settingsChange(key: "exchange_type_changed_to", newValue: newExchange.displayName))
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
    
    private func loadExchange() {
        guard let stored = storage.value(forKey: StorageKey.selectExchange) as? String else {
            state.exchange = Exchange(.bybit, wallet: .unified)
            return
        }
        
        let parts = stored.split(separator: ":").map(String.init)
        guard parts.count >= 2,
              let walletType = WalletType(rawValue: parts[1]) else {
            // Fallback for legacy values or unknown formats
            state.exchange = Exchange(.bybit, wallet: .unified)
            return
        }
        
        let identifier = ExchangeIdentifier(rawValue: parts[0])
        
        // Validate if this exchange registered
        guard exchangeRegistry.capabilities(for: identifier) != nil else {
            state.exchange = Exchange(.bybit, wallet: .unified)
            return
        }
        
        // Environment was introduced later; legacy values use a 2-part format without it.
        var environment: APIEnvironment = .production
        if parts.count >= 3, let parsed = APIEnvironment(rawValue: parts[2]) {
            environment = parsed
        }
        
        state.exchange = normalized(Exchange(identifier, environment: environment, wallet: walletType))
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
