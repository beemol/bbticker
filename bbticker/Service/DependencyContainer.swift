import Foundation
import LLCore

/// A dependency container for the app that provides access to shared services
/// This is used by AppIntents and other contexts that need global access to dependencies
/// while avoiding direct singleton usage in business logic.
@MainActor
final class DependencyContainer {
    
    /// Shared instance for global access
    /// Note: This is a singleton, but it's a container pattern, not a service singleton
    static let shared = DependencyContainer()
    
    // MARK: - Dependencies
    
    private(set) var settingsService: (any SettingsServiceProtocol)?
    private(set) var credentialManager: CredentialManagerProtocol?
    private(set) var keychainHelper: KeychainHelperProtocol?
    private(set) var analyticsManager: AnalyticsManagerProtocol?
    
    private init() {
        // Private init to enforce singleton
    }
    
    // MARK: - Registration
    
    /// Register dependencies - should be called once at app launch
    func register(
        settingsService: any SettingsServiceProtocol,
        credentialManager: CredentialManagerProtocol
        //keychainHelper: KeychainHelperProtocol,
        //analyticsManager: AnalyticsManagerProtocol
    ) {
        self.settingsService = settingsService
        self.credentialManager = credentialManager
        //self.keychainHelper = keychainHelper
        //self.analyticsManager = analyticsManager
    }
    
    // MARK: - Getters with fallback
    
    /// Get SettingsService or create a new instance if not registered
    func getSettingsService() -> any SettingsServiceProtocol {
        if let service = settingsService {
            return service
        }
        // Fallback: create new instance if not registered yet
        // This can happen if AppIntent is called before app fully initializes
        print("[DependencyContainer] Warning: SettingsService not registered, creating fallback instance")
        let fallback = SettingsService()
        self.settingsService = fallback
        return fallback
    }
    
    /// Get CredentialManager or create a new instance if not registered
    func getCredentialManager() -> CredentialManagerProtocol {
        if let manager = credentialManager {
            return manager
        }
        print("[DependencyContainer] Warning: CredentialManager not registered, creating fallback instance")
        let fallback = CredentialManager(keychainHelper: KeychainHelper.shared)
        self.credentialManager = fallback
        return fallback
    }
    
    /// Get KeychainHelper or create a new instance if not registered
//    func getKeychainHelper() -> KeychainHelperProtocol {
//        if let helper = keychainHelper {
//            return helper
//        }
//        print("[DependencyContainer] Warning: KeychainHelper not registered, creating fallback instance")
//        let fallback = KeychainHelper()
//        self.keychainHelper = fallback
//        return fallback
//    }
    
    /// Get AnalyticsManager or create a new instance if not registered
//    func getAnalyticsManager() -> AnalyticsManagerProtocol {
//        if let manager = analyticsManager {
//            return manager
//        }
//        print("[DependencyContainer] Warning: AnalyticsManager not registered, creating fallback instance")
//        let fallback = AnalyticsManager.shared
//        self.analyticsManager = fallback
//        return fallback
//    }
}

