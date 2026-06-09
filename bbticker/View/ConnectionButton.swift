import SwiftUI
import Combine
import LLCore

struct ConnectionButton: View {
    @ObservedObject var bybitClient: BBClient
    @ObservedObject var disableCenter: DisableCenter
    
    let accountIdentifier: String
    let buttonStyle: ConnectionButtonStyle
    
    // MARK: - Constants
    private let horizontalPadding: CGFloat = 8
    private let verticalPadding: CGFloat = 8
    
    enum ConnectionButtonStyle {
        case prominent
        case plain
    }
    
    init(
        bybitClient: BBClient,
        disableCenter: DisableCenter,
        accountIdentifier: String,
        style: ConnectionButtonStyle = .prominent
    ) {
        self.bybitClient = bybitClient
        self.disableCenter = disableCenter
        self.accountIdentifier = accountIdentifier
        self.buttonStyle = style
    }
    
    var body: some View {
        switch bybitClient.connectionStatus {
        case .disconnected:
            Button(action: {
                // Check kill-switch first
                if disableCenter.isActive {
                    bybitClient.authenticationError = disableCenter.message
                    print("🔥 Connection blocked by kill-switch: \(disableCenter.message)")
                    return
                }
                
                if !bybitClient.isNetworkConnected {
                    bybitClient.authenticationError = "No network connection available."
                    return
                }
                
                Task {
                    await bybitClient.connect()
                }
            }) {
                Text("Connect")
                    .foregroundColor(buttonStyle == .prominent ? .white : .green)
                    .paddedIfProminent(buttonStyle == .prominent, h: self.horizontalPadding, v: self.verticalPadding)
                    .background(buttonStyle == .prominent ? Color.blue : Color.clear)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .disabled(!bybitClient.isNetworkConnected || disableCenter.isActive)
            #if os(iOS)
            .controlSize(.large)
            #endif
            
        case .connected:
            Button(action: {
                bybitClient.disconnect()
            }) {
                Text("Disconnect")
                    .foregroundColor(buttonStyle == .prominent ? .white : .red)
                    .paddedIfProminent(buttonStyle == .prominent, h: self.horizontalPadding, v: self.verticalPadding)
                    .background(buttonStyle == .prominent ? Color.red : Color.clear)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            #if os(iOS)
            .controlSize(.large)
            #endif
            
        case .connecting:
            Button(action: {}) {
                HStack(spacing: 4) {
//                    ProgressView()
//                        .scaleEffect(buttonStyle == .prominent ? 0.6 : 0.5)
                    Text("Connecting")
                        .font(.system(size: buttonStyle == .prominent ? 16 : 14))
                }
                .paddedIfProminent(buttonStyle == .prominent, h: self.horizontalPadding, v: self.verticalPadding)
                .background(buttonStyle == .prominent ? Color.gray : Color.clear)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .disabled(true)
            #if os(iOS)
            .controlSize(.large)
            #endif
            
        case .disconnecting:
            Button(action: {}) {
                HStack(spacing: 4) {
//                    ProgressView()
//                        .scaleEffect(buttonStyle == .prominent ? 0.6 : 0.5)
                    Text("Disconnecting")
                        .font(.system(size: buttonStyle == .prominent ? 16 : 14))
                }
                .paddedIfProminent(buttonStyle == .prominent, h: self.horizontalPadding, v: self.verticalPadding)
                .background(buttonStyle == .prominent ? Color.red.opacity(0.6) : Color.clear)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .disabled(true)
            #if os(iOS)
            .controlSize(.large)
            #endif
        }
    }
}

private extension View {
    func paddedIfProminent(_ prominent: Bool, h: CGFloat, v: CGFloat) -> some View {
        padding(prominent
                ? EdgeInsets(top: v, leading: h, bottom: v, trailing: h)
                : EdgeInsets())
    }
}

#if DEBUG
struct ConnectionButton_Previews: PreviewProvider {
    class MockNetworkMonitorForPreviews: NetworkStoreProtocol {
        var statusStream: AsyncStream<Bool> = AsyncStream<Bool>.makeStream().stream
        
        var state: NetworkState = NetworkState()
    }
    
    class MockAPIServiceForPreviews: APIServiceProtocol {
        func fetchWalletBalanceForCurrentExchange() async throws -> WalletData {
            return WalletData(totalEquity: 1000.00, walletBalance: 500.00)
        }
        
        func fetchWalletBalance(for exchangeType: ExchangeType) async throws -> WalletData {
            // Return mock data for previews
            return WalletData(totalEquity: 1000.00, walletBalance: 500.00)
        }
    }
    
    class MockSharedDataManagerForPreviews: SharedDataManagerProtocol {
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
    
    actor MockCredentialManagerForPreviews: CredentialManagerProtocol {
        func saveCredentials(key: String, secret: String, passphrase: String, forAccount account: String) async -> OSStatus {
            return errSecSuccess
        }
        
        func deleteCredentials(forAccount account: String) async -> OSStatus {
            return errSecSuccess
        }
        
        func getCredentials(forAccount account: String) async -> Credentials {
            return Credentials(apiKey: "preview-key", apiSecret: "preview-secret", passphrase: nil)
        }
        func invalidateCache(forAccount account: String) async {}
        func invalidateAll() async {}
    }
    
    class MockWalletRepository: WalletRepositoryProtocol, @unchecked Sendable {
        func getWalletData(for exchangeType: any LLCore.ExchangeType) async throws -> LLCore.WalletData {
            WalletData(totalEquity: 123.1, walletBalance: 32.1)
        }
    }
    
    class MockBybitClient: BBClient {
        init() {
            super.init(
                settingsService: Mocks.MockSettingsService(),
                networkMonitor: MockNetworkMonitorForPreviews(),
                //apiService: MockAPIServiceForPreviews(),
                sharedDataManager: MockSharedDataManagerForPreviews(),
                //credentialManager: MockCredentialManagerForPreviews()
                walletRepository: MockWalletRepository()
            )
            self.connectionStatus = .disconnected
        }
    }
    
    class MockNetworkMonitor: NetworkMonitor {
        override init() {
            super.init()
            self.isConnected = true
        }
    }
    
    static var previews: some View {
        VStack(spacing: 20) {
            Text("Prominent Style")
            ConnectionButton(
                bybitClient: MockBybitClient(),
                disableCenter: DisableCenter(),
                accountIdentifier: "preview",
                style: .prominent
            )
            
            Text("Plain Style")
            ConnectionButton(
                bybitClient: MockBybitClient(),
                disableCenter: DisableCenter(),
                accountIdentifier: "preview",
                style: .plain
            )
        }
        .padding()
    }
}
#endif
