import SwiftUI
import LLCore

struct ExchangeSection: View {
    let settingsService: any SettingsServiceProtocol
    
    #if os(macOS)
    @State private var isShowingExchangeInfoPopover = false
    #endif
    
    var body: some View {
        let exchange = settingsService.state.exchange
        let walletTypes = settingsService.availableWalletTypes

        return Section {
            Picker("Exchange", selection: settingsService.selectedExchangeBinding) {
                ForEach(settingsService.availableExchanges
                        // filter out the rest of the platforms for the first app store release.
                    .filter { $0 == .bybit }, id: \.self) { exchangeName in
                    Text(exchangeName.rawValue.capitalized).tag(exchangeName)
                }
            }
            .pickerStyle(.menu)
            
            Picker("Wallet Type", selection: settingsService.selectedWalletBinding) {
                ForEach(walletTypes
                        // filter out the rest of the wallets for the first app store release.
                    .filter { $0 == .unified }, id: \.self) { wallet in
                    Text(wallet.rawValue.capitalized).tag(wallet)
                }
            }
            .pickerStyle(.menu)
        } header: {
            #if os(macOS)
            HStack(spacing: 6) {
                Text("Select Exchange Platform")
                Image(systemName: "info.circle")
                    .foregroundColor(.secondary)
                    .onHover { hovering in
                        isShowingExchangeInfoPopover = hovering
                    }
                    .popover(isPresented: $isShowingExchangeInfoPopover, arrowEdge: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("API details for \(exchange.displayName.capitalized)")
                                .font(.headline)
                            Divider()
                            Text("Base URL")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(settingsService.exchangeConfiguration?.baseURL ?? "")
                                .font(.system(size: 12, weight: .regular, design: .monospaced))
                                .textSelection(.enabled)
                            Text("Endpoint")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 6)
                            Text(settingsService.exchangeConfiguration?.endpoint(for: .wallet(settingsService.state.exchange.walletType)) ?? "")
                                .font(.system(size: 12, weight: .regular, design: .monospaced))
                                .textSelection(.enabled)
                        }
                        .padding()
                        .frame(maxWidth: 420, alignment: .leading)
                    }
            }
            #else
            Text("Select Exchange Platform")
            #endif
        }
    }
}


