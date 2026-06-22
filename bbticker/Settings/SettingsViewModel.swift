import SwiftUI
import Combine
import Foundation
import Security
#if canImport(FirebaseRemoteConfig)
import FirebaseRemoteConfig
#endif

import LLCore
import Observation

@MainActor
class SettingsViewModel: ObservableObject {
    // TODO: Refactor into smaller view models if it grows too large
    
    @Published var widgetEnabled: Bool = false
    @Published var widgetRefreshInterval: Double = 5.0
    
    //@Published var updateFrequency: Double = 5.0 // Update frequency in seconds
    // @Published private(set) var isUpdateFrequencyUnlocked: Bool = false
    @Published var purchaseState: PurchaseState = .idle
    
    let settingsService: any SettingsServiceProtocol
    let credentialManager: CredentialManagerProtocol

    var isProActive: Bool {
        settingsService.state.isProActive
    }
    
    var exchangeType: ExchangeType {
        settingsService.state.exchangeType
    }
    
    private var cancellables = Set<AnyCancellable>()

    private let sharedDataService: SharedDataManagerProtocol
    private let iapManager: IAPManagerProtocol
    
    private let contact_config_string = "contact_config_string"
    
    // MARK: - Initializers
    
    init(settingsService: any SettingsServiceProtocol, credentialManager: CredentialManagerProtocol, sharedDataService: SharedDataManagerProtocol, iapManager: IAPManagerProtocol) {
        self.settingsService = settingsService
        self.credentialManager = credentialManager
        self.sharedDataService = sharedDataService
        self.iapManager = iapManager
        
        Task {
            await performInitialLoad()
        }
        
        loadWidgetSettings()
    }
    
    func performInitialLoad() async {
        await refreshIAP()
    }
    
    func setUpdateFrequency(_ frequency: Double) {
        settingsService.setUpdateFrequency(frequency)
        Task {
            await AnalyticsManager.shared.track(.settingsChange(key: "update_frequency", newValue: String(frequency)))
        }
    }
    
    // MARK: - Widget Settings
    
    func setWidgetEnabled(_ enabled: Bool) {
        widgetEnabled = enabled
        sharedDataService.setWidgetEnabled(enabled)
        Task {
            await AnalyticsManager.shared.track(.widgetConfiguration(enabled: enabled, refreshInterval: widgetRefreshInterval))
        }
    }
    
    func setWidgetRefreshInterval(_ interval: Double) {
        widgetRefreshInterval = interval
        sharedDataService.setWidgetRefreshInterval(interval)
        Task {
            await AnalyticsManager.shared.track(.widgetConfiguration(enabled: widgetEnabled, refreshInterval: interval))
        }
    }
    
    private func loadWidgetSettings() {
        widgetEnabled = sharedDataService.isWidgetEnabled()
        widgetRefreshInterval = sharedDataService.getWidgetRefreshInterval()
    }
    
    // MARK: - Binding Helpers
    var widgetEnabledBinding: Binding<Bool> {
        Binding(
            get: { self.widgetEnabled },
            set: { self.setWidgetEnabled($0) }
        )
    }
    
    var widgetRefreshIntervalBinding: Binding<Double> {
        Binding(
            get: { self.widgetRefreshInterval },
            set: { self.setWidgetRefreshInterval($0) }
        )
    }
    
    var updateFrequencyBinding: Binding<Double> {
        Binding(
            get: { self.settingsService.state.updateFrequency },
            set: { self.settingsService.setUpdateFrequency($0) }
        )
    }

    // MARK: - IAP
    enum PurchaseState {
        case idle
        case purchasing
        case restoring
        case purchased
        case failed(String)
    }

    func refreshIAP() async {
        let unlocked = await iapManager.isProActive()
        settingsService.applyProStatus(unlocked)
    }

    func unlockUpdateFrequency() {
        Task {
            purchaseState = .purchasing
            do {
                let success = try await iapManager.purchasePro()
                if success {
                    purchaseState = .purchased
                    settingsService.applyProStatus(true)
                    Task {
                        await AnalyticsManager.shared.track(.settingsChange(key: "iap_unlock_succeeded", newValue: ""))
                    }
                } else {
                    purchaseState = .failed("Purchase cancelled or unverified")
                    Task {
                        await AnalyticsManager.shared.track(.settingsChange(key: "iap_unlock_failed", newValue: ""))
                    }
                }
            } catch {
                purchaseState = .failed(error.localizedDescription)
                Task {
                    await AnalyticsManager.shared.track(.settingsChange(key: "iap_unlock_failed", newValue: ""))
                }
            }
        }
    }

    func restorePurchases() {
        Task {
            purchaseState = .restoring
            let success = await iapManager.restorePurchases()
            if success {
                purchaseState = .purchased
                settingsService.applyProStatus(true)
                Task {
                    await AnalyticsManager.shared.track(.settingsChange(key:"iap_restore_succeeded", newValue: ""))
                }
            } else {
                await refreshIAP()
                purchaseState = .failed("No purchases to restore")
                Task {
                    await AnalyticsManager.shared.track(.settingsChange(key:"iap_restore_failed", newValue: ""))
                }
            }
        }
    }
}

struct APIKeySteps: Codable {
    let exchange: String
    let steps: [String]
    let notes: String?
}

extension SettingsViewModel {
    /// Loads API key creation steps for a given exchange from Firebase Remote Config, or falls back to local file
    func loadAPIKeySteps() -> APIKeySteps? {
        let exchange = settingsService.state.exchangeType.displayName
        
        if FirebaseBootstrap.isConfigured {
            let remoteConfig = RemoteConfig.remoteConfig()
            let remoteValue = remoteConfig["apikeysteps_\(exchange)"].stringValue
            if let data = remoteValue.data(using: .utf8),
               let steps = try? JSONDecoder().decode(APIKeySteps.self, from: data) {
                return steps
            }
        }
        
        // Fallback: read from local file
        let fileName = "apikeysteps_\(exchange).json"
        let fallbackURL = Bundle.main.url(forResource: fileName, withExtension: nil)
        
        guard let url = fallbackURL, let data = try? Data(contentsOf: url) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        let steps = try? decoder.decode(APIKeySteps.self, from: data)
        return steps
    }
}
