import SwiftUI
import Combine

// MARK: - Wallet Models

struct NetworkItem: Codable, Equatable {
    let id: String
    let networkName: String
    let gasToken: String
    let supportedCurrencies: [String]
}

struct DonationStep: Codable, Equatable {
    let stepNumber: Int
    let description: String
}

struct DonationInstructions: Codable, Equatable {
    let instructionsTitle: String
    let donationSteps: [DonationStep]
    let confirmationMessage: String
}

struct WalletResponse: Codable, Equatable {
    let wallet_address: String
    let networks: [NetworkItem]  // Array maintains order
    let instructions: DonationInstructions?
}

struct DisplayWallet: Identifiable, Equatable {
    let id: String
    let networkName: String
    let address: String
    let currencies: [String]
    
    init(address: String, networkItem: NetworkItem) {
        self.id = networkItem.id
        self.networkName = networkItem.networkName
        self.address = address
        self.currencies = networkItem.supportedCurrencies
    }
}

// MARK: - DonationViewModel

@MainActor
class DonationViewModel: ObservableObject {
    @Published var wallets: [DisplayWallet] = []
    @Published var isLoading = true
    @Published var copiedAddress: String?
    @Published var instructions: DonationInstructions? = nil
    
    private let remoteConfigManager: RemoteConfigManagerProtocol
    private let walletConfigKey = "donation_wallets_config"
    
    // Fallback wallet configuration with explicit order
    private let fallbackAddress = "0xd537463b7b25e0e6559b4f33b094f355b9a7a983"
    private let fallbackNetworks: [NetworkItem] = [
        NetworkItem(
            id: "Etherum",
            networkName: "Ethereum (ERC20), Arbitrum One, Mantle Network",
            gasToken: "ETH",
            supportedCurrencies: ["USDT", "ETH", "USDC"]
        )
    ]
    
    private let fallbackInstructions = DonationInstructions(
        instructionsTitle: "For Bybit Users:",
        donationSteps: [
            DonationStep(stepNumber: 1, description: "Go to Assets → Withdraw."),
            DonationStep(stepNumber: 2, description: "Select USDT, USDC, ETH, MNT, or ARB."),
            DonationStep(stepNumber: 3, description: "Choose the correct chain: Mantle or Arbitrum One."),
            DonationStep(stepNumber: 4, description: "Paste the wallet address."),
            DonationStep(stepNumber: 5, description: "Enter the amount."),
            DonationStep(stepNumber: 6, description: "Confirm the withdrawal.")
        ],
        // add exclamation mark emoji
        confirmationMessage: "⚠️ Your donation WILL NOT unlock premium features. It is purely voluntary and helps support development."
    )
    
    private var fallbackWallets: [DisplayWallet] {
        return fallbackNetworks.map { networkItem in
            DisplayWallet(address: fallbackAddress, networkItem: networkItem)
        }
    }
    
    init(remoteConfigManager: RemoteConfigManagerProtocol) {
        self.remoteConfigManager = remoteConfigManager
    }
    
    func loadWalletConfiguration() {
        // Instead of making a remote config call, use cached data from RemoteConfigManager
        print("DonationViewModel: Loading wallet configuration from cache...")
        
        let cachedConfig = remoteConfigManager.getDonationWalletConfig()
        parseWalletConfiguration(jsonString: cachedConfig)
        
        // Set loading to false since we're using cached data
        self.isLoading = false
    }
    
    func copyToClipboard(address: String, walletId: String) {
        #if os(macOS)
        NSPasteboard.general.setString(address, forType: .string)
        #endif
        copiedAddress = walletId
        
        // Clear the "copied" state after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if self.copiedAddress == walletId {
                self.copiedAddress = nil
            }
        }
    }
    
    private func parseWalletConfiguration(jsonString: String?) {
        guard let jsonString = jsonString,
              !jsonString.isEmpty,
              let jsonData = jsonString.data(using: .utf8) else {
            print("DonationViewModel: Invalid JSON string, using fallback wallets")
            wallets = fallbackWallets
            instructions = fallbackInstructions
            return
        }
        
        do {
            // Try array-based structure first (maintains order)
            let walletResponse = try JSONDecoder().decode(WalletResponse.self, from: jsonData)
            wallets = walletResponse.networks.map { networkItem in
                DisplayWallet(address: walletResponse.wallet_address, networkItem: networkItem)
            }
            instructions = walletResponse.instructions ?? fallbackInstructions
            
            // Validate that we have at least one wallet
            if wallets.isEmpty {
                print("DonationViewModel: No networks found in cached config, using fallbacks")
                wallets = fallbackWallets
                instructions = fallbackInstructions
            }
            
            print("DonationViewModel: Successfully loaded \(wallets.count) wallets from cache")
        } catch {
            print("DonationViewModel: Failed to decode wallet configuration: \(error)")
            wallets = fallbackWallets
            instructions = fallbackInstructions
        }
    }
}
