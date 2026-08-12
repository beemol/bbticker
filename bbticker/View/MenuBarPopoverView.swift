import SwiftUI
import Combine
import Foundation
import LLCore

#if os(macOS)

struct MenuBarPopoverView: View {
    @EnvironmentObject var settingsService: SettingsService
    
    @ObservedObject var bybitClient: BBClient
    var networkMonitor: NetworkStoreProtocol
    @ObservedObject var disableCenter: DisableCenter
    
    let accountIdentifier: String
    let openSettings: () -> Void
    let openDonation: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(settingsService.state.exchangeType.displayName)
                    //.font(.headline)
                    .foregroundColor(settingsService.state.exchangeType.displayColor)
                    //.padding(.bottom, 2)
                Text("( \(settingsService.state.exchangeType.walletType.rawValue) )")
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            HStack {
                VStack {
                    NetworkStatusView(state: networkMonitor.state)
                    
                    VStack {
                        Text("API: \(bybitClient.connectionStatus.description)")
                            .font(.subheadline)
                            .foregroundColor(bybitClient.connectionStatus.color)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                Divider()
                
                ApiKeyExpirationView(state: bybitClient.apiKeyExpirationStore.state)
                    .onAppear {
                        bybitClient.apiKeyExpirationStore.dispatch(.checkExpiration(settingsService.state.exchangeType))
                    }
            }
            .frame(height: 40)
            
            if let authError = bybitClient.authenticationError {
                Divider()
                Text(authError)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .truncationMode(.tail)
            } else if disableCenter.isActive {
                Divider()
                Text(disableCenter.message)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .truncationMode(.tail)
            }
            
            Divider()
            
            WalletInfo(walletState: bybitClient.$walletState)
                .frame(height: 40)
            
            Divider()
            
            Button {
                openSettings()
            } label: {
                HStack {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(AccessibilityID.popoverSettingsButton)
            
            HStack {
                Image(systemName: "power")
                ConnectionButton(
                    bybitClient: bybitClient,
                    disableCenter: disableCenter,
                    accountIdentifier: accountIdentifier,
                    style: .plain
                )
            }
            
            Divider()
            
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Text("Quit")
            }
            .buttonStyle(.plain)
        }
        .padding(EdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 10))
        .frame(minWidth: 200, maxWidth: 220, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.windowBackgroundColor).opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
        )
    }
}

// MARK: - Donation Button Component
//struct DonationButton: View {
//    let openDonation: () -> Void
//    
//    var body: some View {
//        Button {
//            openDonation()
//        } label: {
//            HStack(spacing: 4) {
//                Image(systemName: "heart")
//                    .foregroundColor(.yellow)
//                Text("Donate")
//            }
//        }
//        .buttonStyle(.plain)
//    }
//}

#if DEBUG
struct MenuBarPopoverView_Previews: PreviewProvider {
    static var previews: some View {
        MenuBarPopoverView(
            bybitClient: Mocks.MockBybitClient(),
            networkMonitor: Mocks.MockNetworkMonitor(),
            disableCenter: Mocks.MockDisableCenter(),
            accountIdentifier: "previewUser",
            openSettings: {
                // print("Settings opened in preview")
            },
            openDonation: {
                // print("Donation opened in preview")
            }
        )
        .environmentObject(SettingsService())
        .frame(width: 260)
        .previewDisplayName("Menu Bar Popover")
    }
}
#endif

#endif

class Mocks {
    final class MockSettingsService: SettingsServiceProtocol {
        func setWallet(_ wallet: WalletType) {
            //
        }

        let state = SettingsState()

        // MARK: - Optional conveniences (not required by the protocol)
        // We keep these if your code still reads these directly instead of state.*
        var exchangeType: ExchangeType { state.exchangeType }
        var updateFrequency: Double { state.updateFrequency }

        // MARK: - Legacy Combine bridges (safe to remove once fully on Observation)
        private let exchangeTypeSubject: CurrentValueSubject<ExchangeType, Never>
        private let unlockSubject: CurrentValueSubject<Bool, Never>

        // If a ViewModel still uses Combine, expose these:
        var exchangeTypePublisher: AnyPublisher<ExchangeType, Never> {
            exchangeTypeSubject.eraseToAnyPublisher()
        }

        var isUpdateFrequencyUnlockedPublisher: AnyPublisher<Bool, Never> {
            unlockSubject.eraseToAnyPublisher()
        }

        // MARK: - Call tracking for assertions
        private(set) var setUpdateFrequencyCalled = false
        private(set) var setExchangeTypeCalled = false
        private(set) var setUpdateFrequencyUnlockedCalled = false
        private(set) var setAPIEnvironmentCalled = false

        private(set) var lastUpdateFrequency: Double?
        private(set) var lastExchangeType: ExchangeType?
        private(set) var lastAPIEnvironment: APIEnvironment?

        // MARK: - Init
        init(
            initialExchange: Exchange = Exchange(.bybit, wallet: .unified),
            initialFrequency: Double = 5.0,
            initialUnlocked: Bool = false
        ) {
            state.exchangeType = initialExchange
            state.updateFrequency = initialFrequency
            state.isProActive = initialUnlocked

            exchangeTypeSubject = .init(initialExchange)
            unlockSubject = .init(initialUnlocked)
        }

        // MARK: - SettingsServiceProtocol
        func setUpdateFrequency(_ frequency: Double) {
            setUpdateFrequencyCalled = true
            lastUpdateFrequency = frequency
            state.updateFrequency = frequency
            // No publisher needed for frequency (BBClient observes via Observation)
        }

        func setExchangeType(_ exchangeType: Exchange) {
            setExchangeTypeCalled = true
            lastExchangeType = exchangeType
            state.exchangeType = exchangeType
            exchangeTypeSubject.send(exchangeType)
        }

        func applyProStatus(_ unlocked: Bool) {
            setUpdateFrequencyUnlockedCalled = true
            state.isProActive = unlocked
            unlockSubject.send(unlocked)
        }
        
        func setShowMarginLevelDot(_ enabled: Bool) {
            state.showMarginLevelDot = enabled
        }

        func setAPIEnvironment(_ environment: APIEnvironment) {
            setAPIEnvironmentCalled = true
            lastAPIEnvironment = environment
            state.apiEnvironment = environment
        }

        // MARK: - Test helper
        func reset() {
            setUpdateFrequencyCalled = false
            setExchangeTypeCalled = false
            setUpdateFrequencyUnlockedCalled = false
            setAPIEnvironmentCalled = false
            lastUpdateFrequency = nil
            lastExchangeType = nil
            lastAPIEnvironment = nil

            state.updateFrequency = 5.0
            state.exchangeType = Exchange(.bybit, wallet: .unified)
            state.isProActive = false

            exchangeTypeSubject.send(state.exchangeType)
            unlockSubject.send(state.isProActive)
        }
    }
    
    class MockRemoteConfigManager: RemoteConfigManagerProtocol {
        
        var killSwitchConfig: (isDisabled: Bool, message: String) = (false, "Test message")
        var donationWalletConfig: String? = nil
        var shouldFailRefresh = false
        var refreshCallCount = 0
        var setupDefaultsCallCount = 0
        
        func refreshAllConfigurations() async {
            refreshCallCount += 1
        }
        
        func getDonationWalletConfig() -> String? {
            return donationWalletConfig
        }
        
        func setupDefaults() {
            setupDefaultsCallCount += 1
        }
        
        // Helper methods for testing
        func setDonationConfig(_ jsonString: String) {
            donationWalletConfig = jsonString
        }
        
        func setKillSwitchConfig(version: Int, shouldBeKilled: Bool, message: String) {
            killSwitchConfig = (isDisabled: shouldBeKilled, message: message)
        }
        
        func reset() {
            killSwitchConfig = (false, "Test message")
            donationWalletConfig = nil
            shouldFailRefresh = false
            refreshCallCount = 0
            setupDefaultsCallCount = 0
        }
    }
    
    actor MockCredentialManager: CredentialManagerProtocol {
        func saveCredentials(key: String, secret: String, passphrase: String, forAccount account: String) async -> OSStatus {
            return errSecSuccess
        }
        
        func deleteCredentials(forAccount account: String) async -> OSStatus {
            return errSecSuccess
        }
        
        func getCredentials(forAccount account: String) async throws -> Credentials {
            return Credentials(apiKey: "preview-key", apiSecret: "preview-secret", passphrase: nil)
        }
    }
    
    class MockSharedDataManager: SharedDataManagerProtocol {
        func setWidgetEnabled(_ enabled: Bool) {
            
        }
        
        func isWidgetEnabled() -> Bool {
            false
        }
        
        func setWidgetRefreshInterval(_ interval: Double) {
            
        }
        
        func getWidgetRefreshInterval() -> Double {
            1.0
        }
        
        func updateWidgetData(totalEquity: String, walletBalance: String, connectionStatus: String) {
            // Do nothing for previews
        }
    }
    
    // mock for IAPManager
    actor MockIAPManager: IAPManagerProtocol {
        func startObservingTransactions(onProStatusChange: @escaping @Sendable (Bool) -> Void) {
            //
        }
        
        func isProActive() async -> Bool {
            true
        }
        
        func purchasePro() async throws -> Bool {
            true
        }
        
        func restorePurchases() async -> Bool {
            false
        }
    }
    
    class MockSettingsViewModel: SettingsViewModel {
        init() {
            super.init(settingsService: MockSettingsService(), credentialManager: MockCredentialManager(), sharedDataService: MockSharedDataManager(), iapManager: MockIAPManager())
        }
    }
    
    class MockDisableCenter: DisableCenter {
        override init() {
            super.init()
            // Set up mock state for preview
            self.isActive = false
            self.message = "Preview disable message"
        }
    }
    
    class MockNetworkMonitor: NetworkStoreProtocol {
        var statusStream: AsyncStream<Bool> = AsyncStream<Bool>.makeStream().stream
        
        var state = NetworkState()
        
    }
    
    class MockAPIService: APIServiceProtocol {
        func fetchApiKeyInfo(for exchangeType: any LLCore.ExchangeType) async throws -> any ApiKeyInfo {
            ApiKeyInfoData(createdAt: Date())
        }
        
        func fetchWalletBalanceForCurrentExchange() async throws -> WalletData {
            return WalletData(totalEquity: 1234.56, walletBalance: 789.01)
        }
        
        func fetchWalletBalance(for exchangeType: ExchangeType) async throws -> WalletData {
            return WalletData(totalEquity: 1234.56, walletBalance: 789.01)
        }
    }
    
    class MockWalletRepository: WalletRepositoryProtocol, @unchecked Sendable {
        func getApiKeyInfo(for exchangeType: any LLCore.ExchangeType) async throws -> any ApiKeyInfo {
            ApiKeyInfoData(createdAt: Date())
        }
        
        func getWalletData(for exchangeType: any LLCore.ExchangeType) async throws -> LLCore.WalletData {
            WalletData(totalEquity: 123.1, walletBalance: 32.1)
        }
    }
    
    class MockBybitClient: BBClient {
        init() {
            super.init(
                settingsService: MockSettingsService(),
                networkMonitor: MockNetworkMonitor(),
                //apiService: MockAPIService(),
                sharedDataManager: MockSharedDataManager(),
                //credentialManager: MockCredentialManager(),
                walletRepository: MockWalletRepository()
            )
            // Set mock data for preview
            self.walletState = WalletState(equity: 1234.56, balance: 789.01, maintenanceMarginPercentage: 25.0)
            self.connectionStatus = .connected
            self.authenticationError = nil
        }
    }
}
