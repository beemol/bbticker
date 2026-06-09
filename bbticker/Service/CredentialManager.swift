import Foundation
import Security

import LLCore

actor CredentialManager: CredentialManagerProtocol {
    
    private var cache: [String: Credentials] = [:]
    
    private var inFlightCallsForKey: [String: Task<(Credentials), Error>] = [:]
    private var epoch: [String: Int] = [:]
    
    private let keychainHelper: KeychainHelperProtocol

    init(keychainHelper: KeychainHelperProtocol) {
        self.keychainHelper = keychainHelper
    }

    func getCredentials(forAccount account: String) async throws -> Credentials {
        if let cachedCredentials = cache[account] {
            return cachedCredentials
        }
        
        if let task = inFlightCallsForKey[account] {
            return try await task.value
        }
        
        let startEpoch = epoch[account, default: 0]

        let task = Task<Credentials, Error> { [keychainHelper] in
            
            let (key, secret, passphrase) = await keychainHelper.retrieve(forAccount: account)
            
            guard let key = key, let secret = secret else {
                throw NSError(domain: "CredentialManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Credentials are empty for account \(account)"])
            }
            
            return Credentials(apiKey: key, apiSecret: secret, passphrase: passphrase)
        }
        
        inFlightCallsForKey[account] = task
        
        do {
            let creds = try await task.value
            
            if startEpoch == epoch[account, default: 0] {
                cache[account] = creds
            }
            
            inFlightCallsForKey[account] = nil
            
            return cache[account] ?? creds
        } catch {
            inFlightCallsForKey[account] = nil
            throw error
        }
    }

    func saveCredentials(key: String, secret: String, passphrase: String, forAccount account: String) async -> OSStatus {
        let status = await keychainHelper.save(key: key, secret: secret, passphrase: passphrase, forAccount: account)
        if status == errSecSuccess {
            let credentials = Credentials(apiKey: key, apiSecret: secret, passphrase: passphrase)
            
            // bump actual version
            epoch[account, default: 0] += 1
            cache[account] = credentials
        }
        return status
    }

    func deleteCredentials(forAccount account: String) async -> OSStatus {
        let status = await keychainHelper.delete(account: account)
        if status == errSecSuccess {
            // bump actual version
            epoch[account, default: 0] += 1
            cache[account] = nil
        }
        return status
    }
}
