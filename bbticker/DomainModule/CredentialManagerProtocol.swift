//
//  CredentialManagerProtocol.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 10/7/26.
//

import Foundation
import LLCore

public protocol CredentialManagerProtocol: Actor {
    func getCredentials(forAccount account: String) async throws -> Credentials
    func saveCredentials(key: String, secret: String, passphrase: String, forAccount account: String) async -> OSStatus
    func deleteCredentials(forAccount account: String) async -> OSStatus
}
