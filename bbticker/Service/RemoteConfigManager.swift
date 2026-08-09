import Foundation
import Combine
#if canImport(FirebaseRemoteConfig)
import FirebaseRemoteConfig
#endif

// MARK: - Remote Config Manager Protocol

@MainActor
protocol RemoteConfigManagerProtocol {
    /// Fetches all remote config data in background and caches it locally
    func refreshAllConfigurations() async
    
    /// Gets version-specific kill-switch configuration from cache
//    func getVersionedKillSwitchConfig() -> (isDisabled: Bool, message: String)
    
    /// Gets donation wallet configuration from cache
    func getDonationWalletConfig() -> String?
    
    /// Sets up default values for all configurations
    func setupDefaults()
}

// MARK: - Remote Config Manager Implementation
class RemoteConfigManager: RemoteConfigManagerProtocol, ObservableObject {
    
    private var remoteConfig: RemoteConfig? = nil
    
    // MARK: - Version-based Kill Switch Support
    
    /// Gets the major version number from the app's bundle
    private func getMajorAppVersionNumber() -> Int {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            AppLog.remoteConfig.warning("Could not retrieve app version, defaulting to 1")
            return 1
        }
        
        // Extract major version (e.g., "1.2.3" -> 1)
        let majorVersion = version.split(separator: ".").first.flatMap { Int(String($0)) } ?? 1
        return majorVersion
    }
    
    // MARK: - Configuration Keys
    private enum ConfigKeys: String, CaseIterable {
        case killSwitch = "kill_switch"
        case donationWalletConfig = "donation_wallets_config"
        
        // Define the expected type for each key
        enum ValueType {
            case string, stringOptional
        }
        
        var valueType: ValueType {
            switch self {
            case .killSwitch:
                return .stringOptional // Only cache if not empty
            case .donationWalletConfig:
                return .stringOptional // Only cache if not empty
            }
        }
        
        // Dictionary of default values with subscript access
        private static let defaults: [ConfigKeys: String] = [
            .killSwitch: """
            {
                "version": 1,
                "shouldBeKilled": false,
                "msg": ""
            }
            """,
            .donationWalletConfig: """
            {
                "wallet_address": "0xd537463b7b25e0e6559b4f33b094f355b9a7a983",
                "networks": [
                    {
                        "id": "mantle",
                        "networkName": "Mantle Network: $0.0 fee",
                        "gasToken": "MNT",
                        "supportedCurrencies": ["USDT", "ETH", "MNT", "USDC"]
                    },
                    {
                        "id": "arbitrumOne",
                        "networkName": "Arbitrum One",
                        "gasToken": "ETH",
                        "supportedCurrencies": ["USDT: $0.0 fee", "ETH: $0.13 fee", "ARB", "USDC: $1.0 fee"]
                    }
                ],
                "instructions": {
                    "instructionsTitle": "For Bybit Users:",
                    "donationSteps": [
                        {"stepNumber": 1, "description": "Go to Assets → Withdraw."},
                        {"stepNumber": 2, "description": "Select USDT, USDC, ETH, MNT, or ARB."},
                        {"stepNumber": 3, "description": "Choose the correct chain: Mantle or Arbitrum One."},
                        {"stepNumber": 4, "description": "Paste the wallet address."},
                        {"stepNumber": 5, "description": "Enter the amount."},
                        {"stepNumber": 6, "description": "Confirm the withdrawal."}
                    ],
                    "confirmationMessage": "✅ Your donation will be credited after one confirmation—usually within seconds."
                }
            }
            """
        ]
        
        // Get default value using subscript access with safe fallback
        var defaultValue: NSObject {
            guard let value = Self.defaults[self] else {
                // Safe fallback based on expected type
                switch valueType {
                case .string, .stringOptional:
                    return "" as NSObject
                }
            }
            return value as NSObject
        }
        
        // Get all configs as dictionary for Firebase Remote Config defaults
        static var allConfigs: [String: NSObject] {
            return Dictionary(uniqueKeysWithValues: allCases.map { ($0.rawValue, $0.defaultValue) })
        }
    }
    
    init() {
        guard FirebaseBootstrap.isConfigured else {
            AppLog.remoteConfig.info("FirebaseRemoteConfig not available, using local defaults only")
            return
        }
        
        self.remoteConfig = RemoteConfig.remoteConfig()
        setupRemoteConfigSettings()
        setupDefaults()
    }
    
    // For testing with dependency injection
    init(remoteConfig: RemoteConfig) {
        guard FirebaseBootstrap.isConfigured else { return }
        
        self.remoteConfig = remoteConfig
        setupRemoteConfigSettings()
        setupDefaults()
    }
    
    // MARK: - Private Setup Methods
    
    private func setupRemoteConfigSettings() {
        guard FirebaseBootstrap.isConfigured else { return }
        
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 3600 // 0 for immediate fetching for testing
        remoteConfig?.configSettings = settings
    }
    
    // MARK: - Protocol Implementation
    
    func setupDefaults() {
        guard FirebaseBootstrap.isConfigured else { return }
        // Set Firebase Remote Config defaults (this is the intended Firebase pattern)
        remoteConfig?.setDefaults(ConfigKeys.allConfigs)
        // print("RemoteConfigManager: Set Firebase Remote Config defaults")
    }
    
    func refreshAllConfigurations() async {
        guard FirebaseBootstrap.isConfigured else { return }
        
        // print("RemoteConfigManager: Starting background refresh of all configurations...")
        do {
            let status = try await remoteConfig?.fetchAndActivate()
            switch status {
            case .successFetchedFromRemote:
                // print("RemoteConfigManager: Successfully fetched new config from remote")
                break
            case .successUsingPreFetchedData:
                // print("RemoteConfigManager: Using pre-fetched config data")
                break
            case .error:
                break
            case .none:
                break
            @unknown default:
                // print("RemoteConfigManager: Unknown fetch status")
                break
            }
        } catch {
            AppLog.remoteConfig.error("Error fetching remote config: \(error)")
        }
    }
    
//    func getVersionedKillSwitchConfig() -> (isDisabled: Bool, message: String) {
//        let currentVersion = getMajorAppVersionNumber()
//        
//        // Get kill switch data directly from Firebase Remote Config
//        let remoteValue = remoteConfig[ConfigKeys.killSwitch.rawValue]
//        let jsonString = remoteValue.stringValue
//        
//        // Debug: Show where the value is coming from
//        let sourceDescription = switch remoteValue.source {
//        case .remote: "Firebase server"
//        case .default: "local default"
//        case .static: "Firebase static fallback"
//        @unknown default: "unknown source"
//        }
//        print("RemoteConfigManager: Kill-switch source: \(sourceDescription)")
//        
//        // Parse JSON data
//        guard !jsonString.isEmpty,
//              let jsonData = jsonString.data(using: .utf8) else {
//            print("RemoteConfigManager: Empty kill-switch data - kill-switch is OFF")
//            return (isDisabled: false, message: "")
//        }
//        
//        do {
//            if let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
//               let targetVersion = json["version"] as? Int,
//               let shouldBeKilled = json["shouldBeKilled"] as? Bool,
//               let message = json["msg"] as? String {
//                
//                // Check if this kill-switch applies to the current app version
//                let isDisabled = (currentVersion == targetVersion) && shouldBeKilled
//                
//                print("RemoteConfigManager: Kill-switch config - target version: \(targetVersion), current version: \(currentVersion), shouldBeKilled: \(shouldBeKilled), isDisabled: \(isDisabled), message: \(message)")
//                return (isDisabled: isDisabled, message: message)
//            }
//        } catch {
//            print("RemoteConfigManager: Error parsing kill-switch JSON: \(error)")
//        }
//        
//        // Fallback: If parsing fails, assume kill-switch is off
//        print("RemoteConfigManager: Failed to parse kill-switch data - kill-switch is OFF")
//        return (isDisabled: false, message: "")
//    }
    
    func getDonationWalletConfig() -> String? {
        guard FirebaseBootstrap.isConfigured else { return nil }
        
        let remoteValue = remoteConfig?[ConfigKeys.donationWalletConfig.rawValue]
        let config = remoteValue?.stringValue
        let sourceDescription = switch remoteValue?.source {
        case .remote: "Firebase server"
        case .default: "local default"
        case .static: "Firebase static fallback"
        case .none: "unknown source"
        @unknown default: "unknown source"
        }
        // print("RemoteConfigManager: Retrieved donation wallet config from \(sourceDescription)")
        return config
    }
}

// MARK: - Mock Implementation for Testing

class MockRemoteConfigManager: RemoteConfigManagerProtocol {
    
    var shouldFailRefresh = false
    var mockKillSwitchJSON: String = """
    {
        "version": 1,
        "shouldBeKilled": false,
        "msg": "Test message"
    }
    """
    var donationWalletConfig: String? = """
    {
        "wallet_address": "0xtest123",
        "networks": [
            {
                "id": "test",
                "networkName": "Test Network",
                "gasToken": "TEST",
                "supportedCurrencies": ["TEST"]
            }
        ]
    }
    """
    
    func refreshAllConfigurations() async {
        // print("MockRemoteConfigManager: \(shouldFailRefresh ? "Simulating refresh failure" : "Simulating successful refresh")")
    }
    
//    func getVersionedKillSwitchConfig() -> (isDisabled: Bool, message: String) {
//        // Parse the mock JSON to simulate real behavior
//        guard let jsonData = mockKillSwitchJSON.data(using: .utf8),
//              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
//              let targetVersion = json["version"] as? Int,
//              let shouldBeKilled = json["shouldBeKilled"] as? Bool,
//              let message = json["msg"] as? String else {
//            return (isDisabled: false, message: "")
//        }
//        
//        // Assume current version is 1 for testing
//        let currentVersion = 1
//        let isDisabled = (currentVersion == targetVersion) && shouldBeKilled
//        
//        return (isDisabled: isDisabled, message: message)
//    }
    
    func getDonationWalletConfig() -> String? {
        return donationWalletConfig
    }
    
    func setupDefaults() {
        // print("MockRemoteConfigManager: Setup defaults called")
    }
    
    // Helper methods for testing
    func setKillSwitchConfig(version: Int, shouldBeKilled: Bool, message: String) {
        mockKillSwitchJSON = """
        {
            "version": \(version),
            "shouldBeKilled": \(shouldBeKilled),
            "msg": "\(message)"
        }
        """
    }
} 
