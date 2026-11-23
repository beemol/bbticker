//
//  BBAPIService.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 13/07/2025.
//

import Foundation
import CommonCrypto
import LLApiService
import LLCore

@MainActor
protocol APIServiceProtocol {
    var registry: ExchangeRegistryProtocol { get }
    
    func fetchWalletBalance(for exchange: Exchange) async throws -> WalletData
    func fetchWalletBalanceForCurrentExchange() async throws -> WalletData
    func fetchApiKeyInfo(for exchange: Exchange) async throws -> ApiKeyInfo
}
