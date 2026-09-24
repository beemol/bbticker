//
//  GetBalanceIntent.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 15/09/2026.
//

import Foundation
import AppIntents

// MARK: - Simple Balance Intent
#if !os(macOS)
struct GetBalanceIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Balance"
    static let description = IntentDescription("Get your current balance")
    
    // Add suggested invocation phrase
    static let suggestedInvocationPhrase: String = "What's my BBTicker balance?"
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<String> {
        // Get dependencies from container
        let container = DependencyContainer.shared
        let settingsService = container.getSettingsService()
        let credentialManager = container.getCredentialManager()
        let analyticsManager = AnalyticsManager.shared
        
        // Get current exchange type from SettingsService
        let exchangeType = settingsService.state.exchangeType
        let accountDisplayName = exchangeType.displayName
        
        // Get credentials from Keychain using stable envIDString ("bybit:production", etc.)
        let creds = try await credentialManager.getCredentials(forAccount: exchangeType.envIDString)
        
        let key = creds.apiKey
        let secret = creds.apiSecret
        
        // Check if credentials are set up
        guard !key.isEmpty, !secret.isEmpty else {
            Task.detached {
                await analyticsManager.track(.other(msg: "siri_no_credentials"))
            }
            return .result(
                value: "$0.00",
                dialog: "You need to set up your API credentials in the \(getAppName()) app first."
            )
        }
        
        // Fetch balance
        do {
            let apiService = LLAPIServiceWrapper(
                credentialManager: credentialManager,
                settingsService: settingsService,
                urlSession: URLSession.shared
            )
            let walletData = try await apiService.fetchWalletBalanceForCurrentExchange()
            
            // Format the balance
            let balance = walletData.totalEquity
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "USD"
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 0
            
            let formattedBalance = formatter.string(from: NSNumber(value: balance)) ?? "$\(String(Int(balance)))"
            
            // Track success async
            Task.detached {
                await analyticsManager.track(.other(msg: "siri_getWalletBalance"))
            }
            
            return .result(
                value: formattedBalance,
                dialog: "Your \(accountDisplayName) balance is \(formattedBalance)"
            )
            
        } catch {
            // Track error async
            Task.detached {
                await analyticsManager.track(.unexpectedError(
                    context: "siri_balance_fetch",
                    description: error.localizedDescription
                ))
            }
            
            return .result(
                value: "Unavailable",
                dialog: "Sorry, I couldn't get your balance right now. Please try again later."
            )
        }
    }
}

// MARK: - App Shortcuts Provider

struct BalanceShortcutsProvider: AppShortcutsProvider {
    static let shortcutTileColor: ShortcutTileColor = .navy

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetBalanceIntent(),
            phrases: [
                "What's my \(.applicationName) balance",
                "Check my balance in \(.applicationName)",
                "Show my \(.applicationName) balance",
                "Get my \(.applicationName) balance",
                "Check my \(.applicationName) balance",
                "Show me my \(.applicationName) balance",
                "What's my crypto balance in \(.applicationName)",
                "Check my crypto balance in \(.applicationName)",
                "Get balance from \(.applicationName)"
            ],
            shortTitle: "Get Balance",
            systemImageName: "dollarsign.circle"
        )
    }
} 

#endif
