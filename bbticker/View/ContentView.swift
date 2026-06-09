//
//  ContentView.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 03/07/2025.
//

import SwiftUI
import LLCore

// Used for iOS only
#if !os(macOS)
struct ContentView: View {
    @EnvironmentObject var bybitClient: BBClient
    @EnvironmentObject var settingsService: SettingsService
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    
    @StateObject private var networkMonitor = NetworkMonitor()
    @StateObject private var disableCenter = DisableCenter()

    @State private var inputApiKey: String = ""
    @State private var inputApiSecret: String = ""
    @State private var inputPassphrase: String = "" // Passphrase is optional for Bybit
    @State private var accountIdentifier: String = "defaultUser" // Use a unique identifier for Keychain

    @State private var showSettings = false

    var body: some View {
        NavigationView {
            Form {
                VStack(spacing: 20) {
                    Text(settingsService.state.exchangeType.displayName)
                        .font(.largeTitle)
                        .foregroundColor(settingsService.state.exchangeType.displayColor)
                    Text(settingsService.state.exchangeType.walletType.rawValue)
                        .padding(.bottom, 2)
                    Divider()

                    HStack {
                        Text(networkMonitor.isConnected ? "Connected" : "Disconnected")
                            .font(.headline)
                            .foregroundColor(networkMonitor.isConnected ? .green : .red)
                        if networkMonitor.isConnected {
                            Text("(\(networkMonitor.connectionType.rawValue))")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Text("Connection Status: \(bybitClient.connectionStatus)")
                        .font(.headline)
                        .foregroundColor(bybitClient.isConnected ? .green : .red)

                    if let authError = bybitClient.authenticationError {
                        Text(authError)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Divider()

                    HStack {
                        Text("Total Equity:")
                        Spacer()
                        Text(bybitClient.totalEquity)
                            .font(.title2)
                            .bold()
                    }
                    .padding(.horizontal)

                    HStack {
                        Text("Wallet Balance:")
                        Spacer()
                        Text(bybitClient.walletBalance)
                            .font(.title2)
                            .bold()
                    }
                    .padding(.horizontal)

                    HStack {
                        Text("Maintenance Margin:")
                        Spacer()
                        Text(bybitClient.maintenanceMargin)
                            .font(.title2)
                            .bold()
                            .foregroundColor(bybitClient.walletState.maintenanceMarginColor)
                    }
                    .padding(.horizontal)

                    Divider()

                    // Single dynamic connection button
                    ConnectionButton(
                        bybitClient: bybitClient,
                        disableCenter: disableCenter,
                        accountIdentifier: accountIdentifier,
                        style: .prominent
                    )
                    
                    Spacer() // Pushes content to top
                }
                .padding()
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button { showSettings = true } label: {
                            Image(systemName: "gearshape.fill")
                        }
                    }
                }
                //.navigationTitle("App Settings")
                #if !os(macOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                #if os(macOS)
                .frame(minWidth: 350, minHeight: 400)
                #endif
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView_iOS(viewModel: settingsViewModel)
        }
    }
}

// For Xcode Previews
private final class PreviewAPIService: APIServiceProtocol {
    func fetchWalletBalance(for exchangeType: ExchangeType) async throws -> WalletData {
        WalletData(totalEquity: 1234.56, walletBalance: 789.01)
    }
    func fetchWalletBalanceForCurrentExchange() async throws -> WalletData {
        WalletData(totalEquity: 1234.56, walletBalance: 789.01)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let settings = SettingsService()
        let apiService = PreviewAPIService()
        let client = BBClient(
            settingsService: settings,
            networkMonitor: NetworkMonitorAdapter(),
            apiService: apiService,
            sharedDataManager: SharedDataManager.shared,
            credentialManager: Mocks.MockCredentialManager()
        )
        return ContentView()
            .environmentObject(client)
            .environmentObject(settings)
    }
}
#endif
