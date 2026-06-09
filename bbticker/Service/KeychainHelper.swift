//
//  KeychainHelper.swift.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 03/07/2025.
//

import Foundation
import Security

protocol KeychainHelperProtocol: Sendable {
    func save(key: String, secret: String, passphrase: String, forAccount account: String) async -> OSStatus
    func retrieve(forAccount: String) async -> (String?, String?, String?)
    func retrieve(forAccount: String, attribute: Attribute) async -> String?
    func delete(account: String) async -> OSStatus
}

enum Attribute: String {
    case key = "_apiKey"
    case secret = "_apiSecret"
    case passphrase = "_passphrase"
}

final class KeychainHelper: KeychainHelperProtocol {
    
    #if TESTING
    @available(*, unavailable, message: "Do not use singletons in tests. Use DI instead.")
    public static var shared: KeychainHelper { fatalError() }
    #else
    public static let shared = KeychainHelper()
    #endif

    static let service = getBundleIdentifier()
    
    func save(key: String, secret: String, passphrase: String, forAccount account: String) async -> OSStatus {

        let keyStatus = await updateOrAdd(key: account + "_apiKey", value: key)
        let secretStatus = await updateOrAdd(key: account + "_apiSecret", value: secret)
        
        if !passphrase.isEmpty {
            let passphraseStatus = await updateOrAdd(key: account + Attribute.passphrase.rawValue, value: passphrase)
            return max(keyStatus, secretStatus, passphraseStatus)
        }
        
        return max(keyStatus, secretStatus)
    }
    
    func retrieve(forAccount: String) async -> (String?, String?, String?) {
        // no need to call concurrently since keychain access is synchronous
        let key: String?        = await retrieve(forAccount: forAccount, attribute: .key)
        let secret: String?     = await retrieve(forAccount: forAccount, attribute: .secret)
        let passphrase: String? = await retrieve(forAccount: forAccount, attribute: .passphrase)

        return (key, secret, passphrase)
    }
    
    func retrieve(forAccount: String, attribute: Attribute) async -> String? {
        
        // "Any" can hold any type, but we are sure it will have only strings or constants, so we can ask compiler to shut up
        nonisolated(unsafe) let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: KeychainHelper.service,
            kSecAttrAccount as String: forAccount + attribute.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                var itemRef: AnyObject?
                let status = SecItemCopyMatching(query as CFDictionary, &itemRef)
                
                if status == errSecSuccess, let data = itemRef as? Data {
                    continuation.resume(returning: String(data: data, encoding: .utf8))
                } else {
                    // Don't log error for passphrase if it doesn't exist, as this is normal for some exchanges
                    if attribute == .passphrase && status == errSecItemNotFound {
                        print("KeychainHelper: Passphrase not found for \(forAccount) (this is normal for exchanges that don't use passphrases)")
                    } else {
                        print("KeychainHelper: Failed to retrieve item for \(forAccount + attribute.rawValue): \(status)")
                        print("KeychainHelper: Query used: \(query)")
                    }
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    func delete(account: String) async -> OSStatus {
        nonisolated(unsafe) let keyQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: KeychainHelper.service,
            kSecAttrAccount as String: account + "_apiKey"
        ]
        nonisolated(unsafe) let secretQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: KeychainHelper.service,
            kSecAttrAccount as String: account + "_apiSecret"
        ]
        nonisolated(unsafe) let passphraseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: KeychainHelper.service,
            kSecAttrAccount as String: account + Attribute.passphrase.rawValue
        ]
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                
                let keyStatus = SecItemDelete(keyQuery as CFDictionary)
                let secretStatus = SecItemDelete(secretQuery as CFDictionary)
                let passphraseStatus = SecItemDelete(passphraseQuery as CFDictionary)
                
                // It's normal for passphrase to not exist for exchanges that don't use it
                // So we don't treat passphrase deletion failure as an error
                let effectivePassphraseStatus = (passphraseStatus == errSecItemNotFound) ? errSecSuccess : passphraseStatus
                
                continuation.resume(returning: max(keyStatus, secretStatus, effectivePassphraseStatus))
            }
        }
    }
    
    // helper method
    private func updateOrAdd(key: String, value: String) async -> OSStatus {
        // Use kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly to allow Siri access when device is locked
        // This is more secure than kSecAttrAccessibleAlways and still allows background/Siri access
        nonisolated(unsafe) let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: KeychainHelper.service,
            kSecAttrAccount as String: key,
            kSecValueData as String: value.data(using: .utf8)!,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        
        nonisolated(unsafe) let attributesToUpdate: [String: Any] = [
            kSecValueData as String: value.data(using: .utf8)!,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                let updateStatus = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
                
                if updateStatus == errSecSuccess {
                    // Item exists, update itkSecValueData as String: item
                    continuation.resume(returning: updateStatus)
                } else if updateStatus == errSecItemNotFound {
                    // Item doesn't exist, add it
                    let addStatus = SecItemAdd(query as CFDictionary, nil)
                    continuation.resume(returning: addStatus)
                } else {
                    // Some other error occurred
                    continuation.resume(returning: updateStatus)
                }
            }
        }
    }
}
