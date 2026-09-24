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
    
    var networkMonitor: any NetworkStoreProtocol
    @ObservedObject var disableCenter: DisableCenter
    let accountIdentifier: String

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
                        NetworkStatusView(state: networkMonitor.state)
                        Text("API: \(bybitClient.connectionStatus.description)")
                            .font(.headline)
                            .foregroundColor(bybitClient.isConnected ? .green : .red)
                    }

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
                        Text(String(format: "%.1f", bybitClient.walletState.equity))
                            .font(.title2)
                            .bold()
                    }
                    .padding(.horizontal)

                    HStack {
                        Text("Wallet Balance:")
                        Spacer()
                        Text(String(format: "%.1f", bybitClient.walletState.balance))
                            .font(.title2)
                            .bold()
                    }
                    .padding(.horizontal)

                    HStack {
                        Text("Maintenance Margin:")
                        Spacer()
                        Text(String(format: "%.1f", bybitClient.walletState.maintenanceMarginPercentage))
                            .font(.title2)
                            .bold()
                            .foregroundColor(bybitClient.walletState.maintenanceMarginColor)
                    }
                    .padding(.horizontal)

                    Divider()

                    // Single dynamic connection button
                    ConnectionButton(
                        disableCenter: disableCenter,
                        accountIdentifier: accountIdentifier,
                        style: .prominent,
                        connectionStatus: bybitClient.connectionStatus,
                        isNetworkConnected: bybitClient.isNetworkConnected,
                        onConnect: { await bybitClient.connect() },
                        onDisconnect: { bybitClient.disconnect() }
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
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView_iOS(viewModel: settingsViewModel)
        }
    }
}

// For Xcode Previews
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let settings = SettingsService()
        let client = BBClient(
            settingsService: settings,
            networkMonitor: Mocks.MockNetworkMonitor(),
            sharedDataManager: SharedDataManager.shared,
            walletRepository: Mocks.MockWalletRepository()
        )
        let settingsViewModel = Mocks.MockSettingsViewModel()
        return ContentView(
            networkMonitor: Mocks.MockNetworkMonitor(),
            disableCenter: Mocks.MockDisableCenter(),
            accountIdentifier: "previewUser"
        )
        .environmentObject(client)
        .environmentObject(settings)
        .environmentObject(settingsViewModel)
    }
}
#endif
