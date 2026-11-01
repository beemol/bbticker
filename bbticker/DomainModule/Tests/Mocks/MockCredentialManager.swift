//
//  MockCredentialManager.swift
//  LLCoreTests
//
//  Created for testing purposes
//

import Foundation
@testable import LLCore

///// Mock credential manager for testing
//public actor MockCredentialManager: CredentialManagerProtocol {
//    private var credentials: [String: Credentials] = [:]
//    
//    public init() {}
//    
//    /// Configure credentials for a specific account
//    public func setCredentials(_ creds: Credentials, forAccount account: String) {
//        credentials[account] = creds
//    }
//    
//    public func getCredentials(forAccount account: String) async throws -> Credentials {
//        guard let creds = credentials[account] else {
//            throw NSError(domain: "MockCredentialManager", code: 404, userInfo: [
//                NSLocalizedDescriptionKey: "No credentials found for account: \(account)"
//            ])
//        }
//        return creds
//    }
//    
//    public func saveCredentials(key: String, secret: String, passphrase: String, forAccount account: String) async -> OSStatus {
//        let creds = Credentials(apiKey: key, apiSecret: secret, passphrase: passphrase)
//        credentials[account] = creds
//        return errSecSuccess
//    }
//    
//    public func deleteCredentials(forAccount account: String) async -> OSStatus {
//        credentials.removeValue(forKey: account)
//        return errSecSuccess
//    }
//}

