import Foundation
import Combine
import LLCore

@MainActor
protocol SettingsServiceProtocol: ObservableObject {
    var state: SettingsState { get }
    
    // TODO: to be removed all 3 of them, but don't forget about tests
    func setExchangeType(_ exchangeType: Exchange)
    func setUpdateFrequency(_ frequency: Double)
    func setShowMarginLevelDot(_ enabled: Bool)
    func applyProStatus(_ unlocked: Bool)
    
    // UI-facing bridge bindings
    var selectedExchangeBinding: Binding<ExchangeIdentifier> { get }
    var selectedWalletBinding: Binding<WalletType> { get }
}

extension SettingsServiceProtocol {
    // UI helpers — Bindings that READ from state (so the view refreshes)
    var selectedExchangeBinding: Binding<ExchangeIdentifier> {
        Binding(
            get: { self.state.exchangeType.identifier },
            set: { [weak self] newExchangeName in
                // use current wallet type. if doesn't match, service will fallback to available or default option
                let wallet = self?.state.exchangeType.walletType ?? .unified
                self?.setExchangeType(Exchange(newExchangeName, wallet: wallet))
            }
        )
    }

    var selectedWalletBinding: Binding<WalletType> {
        Binding(
            get: { self.state.exchangeType.walletType },
            set: { [weak self] newWalletType in
                let exchangeName = self?.state.exchangeType.identifier ?? .bybit
                self?.setExchangeType(Exchange(exchangeName, wallet: newWalletType))
            }
        )
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
}

/// Shared service for app settings that can be observed reactively
final class SettingsService: SettingsServiceProtocol {
    
    enum StorageKey {
        static let isProActive: String = "iap_ispro_unlocked"
        static let selectExchangeType: String = "selected_exchange_type"
        static let updateFrequency: String = "update_frequency"
        static let showMarginLevelDot: String = "pro_margin_level_dot"
    }
    
    let state = SettingsState()
    
    private let storage: UserDataStorageProtocol
    
    init(storage: UserDataStorageProtocol = UserDefaultsStorage()) {
        self.storage = storage
        // print("[SettingsService] initialized")
        
        loadUpdateFrequency()
        loadExchangeType()
        loadShowMarginLevelDot()
        
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
    
    func setExchangeType(_ newExchangeType: Exchange) {
        if newExchangeType.availableWalletTypes.contains(newExchangeType.walletType) == false {
            AppLog.settings.warning("Attempted to set unsupported exchange type: \(self.state.exchangeType.displayName). Falling back to a safe one.")
            
            // Attempted to set unsupported exchange type or wallet type, fallback to first avaialble option
            if let first = newExchangeType.availableWalletTypes.first {
                state.exchangeType = Exchange(newExchangeType.identifier, wallet: first)
            } else {
                state.exchangeType = Exchange(.bybit, wallet: .unified)
            }
            
            save(newExchangeType: state.exchangeType)
            
            return
        }
        
        state.exchangeType = newExchangeType
        
        save(newExchangeType: state.exchangeType)
    }
    
    private func save(newExchangeType: ExchangeType) {
        let exchangeName = newExchangeType.displayName
        let wt: String = newExchangeType.walletType.rawValue
        
        let serializedValue: String = exchangeName + ":" + wt
        
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
    
    private func loadExchangeType() {
        guard let parts = (storage.value(forKey: StorageKey.selectExchangeType) as? String)?.split(separator: ":"),
              parts.count == 2,
              let walletType = WalletType(rawValue: String(parts[1])) else {
            
            // Fallback for legacy values or unknown formats
            state.exchangeType = Exchange(.bybit, wallet: .unified)
            return
        }
        
        let identifier = ExchangeIdentifier(rawValue: String(parts[0]))
        
        // Validate if this exchange registered
        guard ExchangeRegistry.shared.capabilities(for: identifier) != nil else {
            state.exchangeType = Exchange(.bybit, wallet: .unified)
            return
        }
        
        state.exchangeType = Exchange(identifier, wallet: walletType)
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
