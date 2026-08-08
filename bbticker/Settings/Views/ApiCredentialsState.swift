//
//  ApiCredentialsState.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 17/11/2025.
//

import SwiftUI
import Observation
import LLCore

enum SaveStatus: Equatable {
    case idle
    case success(message: String)
    case failure(message: String)

    var message: String {
        switch self {
        case .idle: return ""
        case .success(let msg): return msg
        case .failure(let msg): return msg
        }
    }

    var isShowing: Bool {
        if case .idle = self { return false }
        return true
    }
}

@MainActor
@Observable
final class ApiCredentialsState {
    var apiKey: String = ""
    var apiSecret: String = ""
    var apiPassphrase: String = ""
    var isSecureField: Bool = true
    var saveStatus: SaveStatus = .idle
    
    let settingsService: any SettingsServiceProtocol
    let credentialManager: CredentialManagerProtocol
    
    init(settingsService: any SettingsServiceProtocol,
         credentialManager: CredentialManagerProtocol) {
        self.settingsService = settingsService
        self.credentialManager = credentialManager
    }
    
    var canSaveCredentials: Bool {
        let hasKeyAndSecret = !apiKey.isEmpty && !apiSecret.isEmpty
        
        // KuCoin requires a passphrase, other exchanges don't
        if settingsService.state.exchangeType.identifier == .kucoin {
            return hasKeyAndSecret && !apiPassphrase.isEmpty
        }
        
        return hasKeyAndSecret
    }
    
    var requiresPassphrase: Bool {
        if settingsService.state.exchangeType.identifier == .kucoin {
            return true
        }
        return false
    }
    
    func saveCredentials() async {
        print("ApiCredentialsState: Saving credentials for exchange: \(settingsService.state.exchangeType.displayName)")
        
        let status = await credentialManager.saveCredentials(
            key: apiKey,
            secret: apiSecret,
            passphrase: apiPassphrase,
            forAccount: settingsService.state.exchangeType.displayName
        )
        
        if status == errSecSuccess {
            saveStatus = .success(message: "Credentials saved successfully!")
            await AnalyticsManager.shared.track(.credentialsSaved)
        } else {
            saveStatus = .failure(message: "Failed to save credentials (Error: \(status)).")
            await AnalyticsManager.shared.track(.keychainError(operation: "save", status: status))
        }
    }
    
    func deleteCredentials() async {
        let status = await credentialManager.deleteCredentials(
            forAccount: settingsService.state.exchangeType.displayName
        )
        
        if status == errSecSuccess {
            saveStatus = .success(message: "Credentials deleted!")
            clearFields()
            await AnalyticsManager.shared.track(.credentialsDeleted)
        } else {
            saveStatus = .failure(message: "Failed to delete credentials (Error: \(status)).")
            await AnalyticsManager.shared.track(.keychainError(operation: "delete", status: status))
        }
    }
    
    func loadCredentials() async {
        let account = settingsService.state.exchangeType.displayName
        
        if let credentials = try? await credentialManager.getCredentials(forAccount: account) {
            apiKey = credentials.apiKey
            apiSecret = credentials.apiSecret
            apiPassphrase = credentials.passphrase ?? ""
        } else {
            clearFields()
        }
    }
    
    func clearFields() {
        apiKey = ""
        apiSecret = ""
        apiPassphrase = ""
    }
    
    func toggleSecureField() {
        isSecureField.toggle()
    }
}
