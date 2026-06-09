import Foundation
import AppIntents

// MARK: - Simple Balance Intent
#if !os(macOS)
struct GetBalanceIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Balance"
    static var description = IntentDescription("Get your current balance")
    
    // Add suggested invocation phrase
    static var suggestedInvocationPhrase: String = "What's my BBTicker balance?"
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Get dependencies from container
        let container = DependencyContainer.shared
        let settingsService = await container.getSettingsService()
        let credentialManager = await container.getCredentialManager()
        let analyticsManager = AnalyticsManager.shared
        
        // Get current exchange type from SettingsService
        let accountName = await settingsService.state.exchangeType.displayName
        
        // Get credentials from Keychain
        // Note: Keychain is configured with kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        // to allow access even when device is locked (required for Siri)
        let creds = try await credentialManager.getCredentials(forAccount: accountName)
        
        let key = creds.apiKey
        let secret = creds.apiSecret
        
        // Check if credentials are set up
        guard !key.isEmpty, !secret.isEmpty else {
            analyticsManager.track(.other(msg: "siri_no_credentials"))
            return .result(dialog: "You need to set up your API credentials in the \(getAppName()) app first.")
        }
        
        // Fetch balance using async/await
        do {
            let apiService = await LLAPIServiceWrapper(
                credentialManager: credentialManager,
                settingsService: settingsService,
                urlSession: URLSession.shared
            )
            let walletData = try await apiService.fetchWalletBalanceForCurrentExchange()
            
            // Format the balance
            let balance = Double(walletData.totalEquity) ?? 0.0
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "USD"
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 0
            
            let formattedBalance = formatter.string(from: NSNumber(value: balance)) ?? "$\(String(Int(balance)))"
            
            // Track success
            analyticsManager.track(.other(msg:  "siti_getWalletBalance"))
            
            return .result(dialog: "Your \(accountName) balance is \(formattedBalance)")
            
        } catch {
            // Track error
            analyticsManager.track(.unexpectedError(
                context: "siri_balance_fetch",
                description: error.localizedDescription
            ))
            
            return .result(dialog: "Sorry, I couldn't get your balance right now. Please try again later.")
        }
    }
}

// MARK: - App Shortcuts Provider

struct BalanceShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetBalanceIntent(),
            phrases: [
                "What's my \(.applicationName) balance?",
                "Check my balance in \(.applicationName)",
                "Show my \(.applicationName) balance",
                "Get my \(.applicationName) balance",
                "What's my balance in \(.applicationName)?",
                "Check my \(.applicationName) balance",
                "Show me my \(.applicationName) balance",
                "What's my crypto balance in \(.applicationName)?",
                "Check my crypto balance in \(.applicationName)",
                "Get balance from \(.applicationName)",
                "Hey Siri, what's my \(.applicationName) balance?",
                "Hey Siri, check my \(.applicationName) balance"
            ],
            shortTitle: "Get Balance",
            systemImageName: "dollarsign.circle"
        )
    }
} 

#endif
