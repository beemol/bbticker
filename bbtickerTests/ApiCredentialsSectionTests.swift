import Testing
import SwiftUI
import LLCore
@testable import bbticker

@MainActor
@Suite("Api Credentials Section Tests")
struct ApiCredentialsSectionTests {
    
    // MARK: - Integration Tests
    // this test will cover exchange platform switch as well
    @Test("Complete workflow: save, switch, switch back")
    func completeWorkflow() async throws {
        let settingsService = MockSettingsService()
        let credentialManager = MockCredentialManager(fallbackOnMissing: false)
        
        // Start with Bybit
        settingsService.setExchangeType(Exchange(.bybit, wallet: .unified))
        let state = ApiCredentialsState(
            settingsService: settingsService,
            credentialManager: credentialManager
        )
        
        // Enter and save Bybit credentials
        state.apiKey = "bybit-key"
        state.apiSecret = "bybit-secret"
        #expect(state.canSaveCredentials == true)
        
        await state.saveCredentials()
        #expect(state.saveStatus == .success(message: "Credentials saved successfully!"))
        
        // Switch to KuCoin
        settingsService.setExchangeType(Exchange(.kucoin, wallet: .futures))
        await state.loadCredentials()
        #expect(state.apiKey == "")
        #expect(state.requiresPassphrase == true)
        
        // Enter and save KuCoin credentials
        state.apiKey = "kucoin-key"
        state.apiSecret = "kucoin-secret"
        state.apiPassphrase = "kucoin-passphrase"
        #expect(state.canSaveCredentials == true)
        
        await state.saveCredentials()
        #expect(state.saveStatus == .success(message: "Credentials saved successfully!"))
        
        // Switch back to Bybit
        settingsService.setExchangeType(Exchange(.bybit, wallet: .unified))
        await state.loadCredentials()
        #expect(state.apiKey == "bybit-key")
        #expect(state.apiSecret == "bybit-secret")
        #expect(state.apiPassphrase == "")
        #expect(state.requiresPassphrase == false)
    }
    
    // MARK: - State Property Tests
    
    @Test("Initial state has empty fields")
    func initialStateIsEmpty() async throws {
        let settingsService = MockSettingsService()
        let credentialManager = MockCredentialManager(fallbackOnMissing: false)
        
        let state = ApiCredentialsState(
            settingsService: settingsService,
            credentialManager: credentialManager
        )
        
        #expect(state.apiKey == "")
        #expect(state.apiSecret == "")
        #expect(state.apiPassphrase == "")
        #expect(state.isSecureField == true)
        #expect(state.saveStatus == .idle)
    }
    
    @Test("Can set and get credential fields")
    func canSetAndGetFields() async throws {
        let settingsService = MockSettingsService()
        let credentialManager = MockCredentialManager(fallbackOnMissing: false)
        
        let state = ApiCredentialsState(
            settingsService: settingsService,
            credentialManager: credentialManager
        )
        
        state.apiKey = "test-key"
        state.apiSecret = "test-secret"
        state.apiPassphrase = "test-passphrase"
        
        #expect(state.apiKey == "test-key")
        #expect(state.apiSecret == "test-secret")
        #expect(state.apiPassphrase == "test-passphrase")
    }
    
    @Test("Toggle secure field changes visibility")
    func toggleSecureField() async throws {
        let settingsService = MockSettingsService()
        let credentialManager = MockCredentialManager(fallbackOnMissing: false)
        
        let state = ApiCredentialsState(
            settingsService: settingsService,
            credentialManager: credentialManager
        )
        
        #expect(state.isSecureField == true)
        
        state.toggleSecureField()
        #expect(state.isSecureField == false)
        
        state.toggleSecureField()
        #expect(state.isSecureField == true)
    }
    
    // MARK: - Validation Tests
    
    @Test("Cannot save credentials with empty key")
    func cannotSaveWithEmptyKey() async throws {
        let settingsService = MockSettingsService()
        let credentialManager = MockCredentialManager(fallbackOnMissing: false)
        settingsService.setExchangeType(Exchange(.bybit, wallet: .unified))
        
        let state = ApiCredentialsState(
            settingsService: settingsService,
            credentialManager: credentialManager
        )
        
        state.apiKey = ""
        state.apiSecret = "secret"
        
        #expect(state.canSaveCredentials == false)
    }
    
    @Test("Cannot save credentials with empty secret")
    func cannotSaveWithEmptySecret() async throws {
        let settingsService = MockSettingsService()
        let credentialManager = MockCredentialManager(fallbackOnMissing: false)
        settingsService.setExchangeType(Exchange(.bybit, wallet: .unified))
        
        let state = ApiCredentialsState(
            settingsService: settingsService,
            credentialManager: credentialManager
        )
        
        state.apiKey = "key"
        state.apiSecret = ""
        
        #expect(state.canSaveCredentials == false)
    }
    
    @Test("Can save Bybit credentials with key and secret only")
    func canSaveBybitCredentials() async throws {
        let settingsService = MockSettingsService()
        let credentialManager = MockCredentialManager(fallbackOnMissing: false)
        settingsService.setExchangeType(Exchange(.bybit, wallet: .unified))
        
        let state = ApiCredentialsState(
            settingsService: settingsService,
            credentialManager: credentialManager
        )
        
        state.apiKey = "key"
        state.apiSecret = "secret"
        // No passphrase needed for Bybit
        
        #expect(state.canSaveCredentials == true)
    }
    
    @Test("Cannot save KuCoin credentials without passphrase")
    func cannotSaveKuCoinWithoutPassphrase() async throws {
        let settingsService = MockSettingsService()
        let credentialManager = MockCredentialManager(fallbackOnMissing: false)
        settingsService.setExchangeType(Exchange(.kucoin, wallet: .futures))
        
        let state = ApiCredentialsState(
            settingsService: settingsService,
            credentialManager: credentialManager
        )
        
        state.apiKey = "key"
        state.apiSecret = "secret"
        state.apiPassphrase = ""
        
        #expect(state.canSaveCredentials == false)
    }
    
    @Test("Can save KuCoin credentials with passphrase")
    func canSaveKuCoinWithPassphrase() async throws {
        let settingsService = MockSettingsService()
        let credentialManager = MockCredentialManager(fallbackOnMissing: false)
        settingsService.setExchangeType(Exchange(.kucoin, wallet: .futures))
        
        let state = ApiCredentialsState(
            settingsService: settingsService,
            credentialManager: credentialManager
        )
        
        state.apiKey = "key"
        state.apiSecret = "secret"
        state.apiPassphrase = "passphrase"
        
        #expect(state.canSaveCredentials == true)
    }
    
    @Test("Bybit does not require passphrase")
    func bybitDoesNotRequirePassphrase() async throws {
        let settingsService = MockSettingsService()
        let credentialManager = MockCredentialManager(fallbackOnMissing: false)
        settingsService.setExchangeType(Exchange(.bybit, wallet: .unified))
        
        let state = ApiCredentialsState(
            settingsService: settingsService,
            credentialManager: credentialManager
        )
        
        #expect(state.requiresPassphrase == false)
    }
    
    @Test("KuCoin requires passphrase")
    func kucoinRequiresPassphrase() async throws {
        let settingsService = MockSettingsService()
        let credentialManager = MockCredentialManager(fallbackOnMissing: false)
        settingsService.setExchangeType(Exchange(.kucoin, wallet: .futures))
        
        let state = ApiCredentialsState(
            settingsService: settingsService,
            credentialManager: credentialManager
        )
        
        #expect(state.requiresPassphrase == true)
    }
    
    // MARK: - Save Credentials Tests
    
    @Test("Save credentials successfully updates status")
    func saveCredentialsSuccess() async throws {
        let settingsService = MockSettingsService()
        let credentialManager = MockCredentialManager(fallbackOnMissing: false)
        settingsService.setExchangeType(Exchange(.bybit, wallet: .unified))
        
        let state = ApiCredentialsState(
            settingsService: settingsService,
            credentialManager: credentialManager
        )
        
        state.apiKey = "test-key"
        state.apiSecret = "test-secret"
        
        await state.saveCredentials()
        
        #expect(state.saveStatus == .success(message: "Credentials saved successfully!"))
        #expect(state.saveStatus.isShowing == true)
        
        // Verify credentials were actually saved
        let saved = try await credentialManager.getCredentials(forAccount: "bybit:production")
        #expect(saved.apiKey == "test-key")
        #expect(saved.apiSecret == "test-secret")
    }
    
    @Test("Save credentials failure updates status with error")
    func saveCredentialsFailure() async throws {
        let settingsService = MockSettingsService()
        let credentialManager = MockCredentialManager(fallbackOnMissing: false)
        settingsService.setExchangeType(Exchange(.bybit, wallet: .unified))
        
        // Configure mock to return failure
        await credentialManager.setSaveResult(errSecAuthFailed)
        
        let state = ApiCredentialsState(
            settingsService: settingsService,
            credentialManager: credentialManager
        )
        
        state.apiKey = "test-key"
        state.apiSecret = "test-secret"
        
        await state.saveCredentials()
        
        #expect(state.saveStatus.message.contains("Failed to save credentials"))
        #expect(state.saveStatus.message.contains("\(errSecAuthFailed)"))
        #expect(state.saveStatus.isShowing == true)
    }
    
    @Test("Save KuCoin credentials with passphrase")
    func saveKuCoinCredentialsWithPassphrase() async throws {
        let settingsService = MockSettingsService()
        let credentialManager = MockCredentialManager(fallbackOnMissing: false)
        settingsService.setExchangeType(Exchange(.kucoin, wallet: .futures))
        
        let state = ApiCredentialsState(
            settingsService: settingsService,
            credentialManager: credentialManager
        )
        
        state.apiKey = "kucoin-key"
        state.apiSecret = "kucoin-secret"
        state.apiPassphrase = "kucoin-passphrase"
        
        await state.saveCredentials()
        
        #expect(state.saveStatus == .success(message: "Credentials saved successfully!"))
        
        // Verify passphrase was saved
        let saved = try await credentialManager.getCredentials(forAccount: "kucoin:production")
        #expect(saved.apiKey == "kucoin-key")
        #expect(saved.apiSecret == "kucoin-secret")
        #expect(saved.passphrase == "kucoin-passphrase")
    }
    
    // MARK: - Delete Credentials Tests
    
    @Test("Delete credentials clears fields and updates status")
    func deleteCredentialsSuccess() async throws {
        let settingsService = MockSettingsService()
        let credentialManager = MockCredentialManager(fallbackOnMissing: false)
        settingsService.setExchangeType(Exchange(.bybit, wallet: .unified))
        
        let state = ApiCredentialsState(
            settingsService: settingsService,
            credentialManager: credentialManager
        )
        
        // First save some credentials
        state.apiKey = "test-key"
        state.apiSecret = "test-secret"
        await state.saveCredentials()
        
        // Now delete them
        await state.deleteCredentials()
        
        #expect(state.saveStatus == .success(message: "Credentials deleted!"))
        #expect(state.apiKey == "")
        #expect(state.apiSecret == "")
        #expect(state.apiPassphrase == "")
        #expect(state.saveStatus.isShowing == true)
    }
    
    @Test("Delete credentials failure updates status with error")
    func deleteCredentialsFailure() async throws {
        let settingsService = MockSettingsService()
        let credentialManager = MockCredentialManager(fallbackOnMissing: false)
        settingsService.setExchangeType(Exchange(.bybit, wallet: .unified))
        
        // Configure mock to return failure
        await credentialManager.setDeleteResult(errSecAuthFailed)
        
        let state = ApiCredentialsState(
            settingsService: settingsService,
            credentialManager: credentialManager
        )
        
        state.apiKey = "test-key"
        state.apiSecret = "test-secret"
        
        await state.deleteCredentials()
        
        #expect(state.saveStatus.message.contains("Failed to delete credentials"))
        #expect(state.saveStatus.message.contains("\(errSecAuthFailed)"))
        #expect(state.saveStatus.isShowing == true)
        
        // Fields should NOT be cleared on failure
        #expect(state.apiKey == "test-key")
        #expect(state.apiSecret == "test-secret")
    }
    
    // MARK: - Load Credentials Tests
    
    @Test("Load credentials populates fields")
    func loadCredentialsSuccess() async throws {
        let settingsService = MockSettingsService()
        let credentialManager = MockCredentialManager(fallbackOnMissing: false)
        settingsService.setExchangeType(Exchange(.bybit, wallet: .unified))
        
        // Pre-save credentials
        await credentialManager.saveCredentials(
            key: "saved-key",
            secret: "saved-secret",
            passphrase: "",
            forAccount: "bybit:production"
        )
        
        let state = ApiCredentialsState(
            settingsService: settingsService,
            credentialManager: credentialManager
        )
        
        await state.loadCredentials()
        
        #expect(state.apiKey == "saved-key")
        #expect(state.apiSecret == "saved-secret")
        #expect(state.apiPassphrase == "")
    }
    
    @Test("Load credentials clears fields when none exist")
    func loadCredentialsWhenNoneExist() async throws {
        let settingsService = MockSettingsService()
        let credentialManager = MockCredentialManager(fallbackOnMissing: false)
        settingsService.setExchangeType(Exchange(.bybit, wallet: .unified))
        
        let state = ApiCredentialsState(
            settingsService: settingsService,
            credentialManager: credentialManager
        )
        
        // Set some values first
        state.apiKey = "old-key"
        state.apiSecret = "old-secret"
        state.apiPassphrase = "old-passphrase"
        
        // Load credentials (none exist)
        await state.loadCredentials()
        
        #expect(state.apiKey == "")
        #expect(state.apiSecret == "")
        #expect(state.apiPassphrase == "")
    }
    
    @Test("Load KuCoin credentials includes passphrase")
    func loadKuCoinCredentialsWithPassphrase() async throws {
        let settingsService = MockSettingsService()
        let credentialManager = MockCredentialManager(fallbackOnMissing: false)
        settingsService.setExchangeType(Exchange(.kucoin, wallet: .futures))
        
        // Pre-save KuCoin credentials with passphrase
        await credentialManager.saveCredentials(
            key: "kucoin-key",
            secret: "kucoin-secret",
            passphrase: "kucoin-passphrase",
            forAccount: "kucoin:production"
        )
        
        let state = ApiCredentialsState(
            settingsService: settingsService,
            credentialManager: credentialManager
        )
        
        await state.loadCredentials()
        
        #expect(state.apiKey == "kucoin-key")
        #expect(state.apiSecret == "kucoin-secret")
        #expect(state.apiPassphrase == "kucoin-passphrase")
    }
    
    // MARK: - Exchange Switching Tests
    
    @Test("Switching from Bybit to KuCoin loads correct credentials")
    func switchFromBybitToKuCoin() async throws {
        let settingsService = MockSettingsService()
        let credentialManager = MockCredentialManager(fallbackOnMissing: false)
        
        // Save Bybit credentials
        settingsService.setExchangeType(Exchange(.bybit, wallet: .unified))
        await credentialManager.saveCredentials(
            key: "bybit-key",
            secret: "bybit-secret",
            passphrase: "",
            forAccount: "bybit:production"
        )
        
        // Save KuCoin credentials
        settingsService.setExchangeType(Exchange(.kucoin, wallet: .futures))
        await credentialManager.saveCredentials(
            key: "kucoin-key",
            secret: "kucoin-secret",
            passphrase: "kucoin-passphrase",
            forAccount: "kucoin:production"
        )
        
        // Start with Bybit
        settingsService.setExchangeType(Exchange(.bybit, wallet: .unified))
        let state = ApiCredentialsState(
            settingsService: settingsService,
            credentialManager: credentialManager
        )
        
        await state.loadCredentials()
        #expect(state.apiKey == "bybit-key")
        #expect(state.apiSecret == "bybit-secret")
        #expect(state.apiPassphrase == "")
        #expect(state.requiresPassphrase == false)
        
        // Switch to KuCoin
        settingsService.setExchangeType(Exchange(.kucoin, wallet: .futures))
        await state.loadCredentials()
        
        #expect(state.apiKey == "kucoin-key")
        #expect(state.apiSecret == "kucoin-secret")
        #expect(state.apiPassphrase == "kucoin-passphrase")
        #expect(state.requiresPassphrase == true)
    }
    
    @Test("Switching to exchange with no saved credentials clears fields")
    func switchToExchangeWithNoCredentials() async throws {
        let settingsService = MockSettingsService()
        let credentialManager = MockCredentialManager(fallbackOnMissing: false)
        
        // Save Bybit credentials only
        settingsService.setExchangeType(Exchange(.bybit, wallet: .unified))
        await credentialManager.saveCredentials(
            key: "bybit-key",
            secret: "bybit-secret",
            passphrase: "",
            forAccount: "bybit:production"
        )
        
        let state = ApiCredentialsState(
            settingsService: settingsService,
            credentialManager: credentialManager
        )
        
        await state.loadCredentials()
        #expect(state.apiKey == "bybit-key")
        
        // Switch to KuCoin (no credentials saved)
        settingsService.setExchangeType(Exchange(.kucoin, wallet: .futures))
        await state.loadCredentials()
        
        #expect(state.apiKey == "")
        #expect(state.apiSecret == "")
        #expect(state.apiPassphrase == "")
    }
    
    @Test("Switching back to exchange reloads saved credentials")
    func switchBackReloadsCredentials() async throws {
        let settingsService = MockSettingsService()
        let credentialManager = MockCredentialManager(fallbackOnMissing: false)
        
        // Save credentials for both exchanges
        settingsService.setExchangeType(Exchange(.bybit, wallet: .unified))
        await credentialManager.saveCredentials(
            key: "bybit-key",
            secret: "bybit-secret",
            passphrase: "",
            forAccount: "bybit:production"
        )
        
        settingsService.setExchangeType(Exchange(.kucoin, wallet: .futures))
        await credentialManager.saveCredentials(
            key: "kucoin-key",
            secret: "kucoin-secret",
            passphrase: "kucoin-passphrase",
            forAccount: "kucoin:production"
        )
        
        // Start with Bybit
        settingsService.setExchangeType(Exchange(.bybit, wallet: .unified))
        let state = ApiCredentialsState(
            settingsService: settingsService,
            credentialManager: credentialManager
        )
        
        await state.loadCredentials()
        #expect(state.apiKey == "bybit-key")
        
        // Switch to KuCoin
        settingsService.setExchangeType(Exchange(.kucoin, wallet: .futures))
        await state.loadCredentials()
        #expect(state.apiKey == "kucoin-key")
        
        // Switch back to Bybit
        settingsService.setExchangeType(Exchange(.bybit, wallet: .unified))
        await state.loadCredentials()
        #expect(state.apiKey == "bybit-key")
        #expect(state.apiSecret == "bybit-secret")
    }
    
    // MARK: - Clear Fields Tests
    
    @Test("Clear fields resets all credential fields")
    func clearFieldsResetsAll() async throws {
        let settingsService = MockSettingsService()
        let credentialManager = MockCredentialManager(fallbackOnMissing: false)
        
        let state = ApiCredentialsState(
            settingsService: settingsService,
            credentialManager: credentialManager
        )
        
        state.apiKey = "key"
        state.apiSecret = "secret"
        state.apiPassphrase = "passphrase"
        
        state.clearFields()
        
        #expect(state.apiKey == "")
        #expect(state.apiSecret == "")
        #expect(state.apiPassphrase == "")
    }
    
    // MARK: - Save Status Semantics Tests
    
    @Test("Save status success exposes message and is showing")
    func saveStatusSuccessSemantics() async throws {
        let settingsService = MockSettingsService()
        let credentialManager = MockCredentialManager(fallbackOnMissing: false)
        
        let state = ApiCredentialsState(
            settingsService: settingsService,
            credentialManager: credentialManager
        )
        
        state.saveStatus = .success(message: "Credentials saved successfully!")
        #expect(state.saveStatus.isShowing == true)
        #expect(state.saveStatus.message == "Credentials saved successfully!")
        
        state.saveStatus = .success(message: "Credentials deleted!")
        #expect(state.saveStatus.message == "Credentials deleted!")
    }
    
    @Test("Save status failure exposes message and idle hides it")
    func saveStatusFailureSemantics() async throws {
        let settingsService = MockSettingsService()
        let credentialManager = MockCredentialManager(fallbackOnMissing: false)
        
        let state = ApiCredentialsState(
            settingsService: settingsService,
            credentialManager: credentialManager
        )
        
        state.saveStatus = .failure(message: "Failed to save credentials (Error: -25300).")
        #expect(state.saveStatus.isShowing == true)
        #expect(state.saveStatus.message.contains("Failed to save credentials"))
        
        state.saveStatus = .failure(message: "Failed to delete credentials (Error: -25300).")
        #expect(state.saveStatus.message.contains("Failed to delete credentials"))
        
        state.saveStatus = .idle
        #expect(state.saveStatus.isShowing == false)
        #expect(state.saveStatus.message == "")
    }
    
    @Test("View can be initialized with state for testing")
    func viewInitializationWithState() async throws {
        let settingsService = MockSettingsService()
        let credentialManager = MockCredentialManager(fallbackOnMissing: false)
        settingsService.setExchangeType(Exchange(.bybit, wallet: .unified))
        
        let state = ApiCredentialsState(
            settingsService: settingsService,
            credentialManager: credentialManager
        )
        
        state.apiKey = "test-key"
        
        // Create view with state
        let _ = ApiCredentialsSection(state: state)
        
        // State should be accessible through the view
        #expect(state.apiKey == "test-key")
    }
}
