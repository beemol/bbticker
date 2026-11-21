//
//  WalletDataParser.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 20/11/2025.
//

import Foundation
import LLCore
import LLApiService

// MARK: - WalletDataParser Protocol
public protocol WalletDataParserProtocol: LLResponseParserProtocol where Output == WalletData {
    func parseWalletBalance(from data: Data) -> WalletData?
}

public extension WalletDataParserProtocol {
    func parse(data: Data) throws -> WalletData {
        guard let result = parseWalletBalance(from: data) else {
            throw APIError.parseError
        }
        return result
    }
}

struct WalletDataParserFactory {
    static func parser(for exchange: Exchange) -> any WalletDataParserProtocol {
        switch exchange.identifier {
        case .bybit:
            switch exchange.walletType {
            case .spot:
                return BybitSpotWalletDataParser()
            case .unified:
                return BybitUnifiedWalletDataParser()
            case .futures:
                return BybitUnifiedWalletDataParser()
            }
        case .kucoin:
            return KuCoinWalletDataParser(walletType: exchange.walletType)
        case .binance:
            return BinanceWalletDataParser()
        default:
            return BybitUnifiedWalletDataParser()
        }
    }
}

//// MARK: - Enhanced Parser Protocol for Detailed Information
//public protocol EnhancedWalletDataParserProtocol: WalletDataParserProtocol {
//    func parseDetailedWalletBalance(from data: Data) -> BBWalletDataEnhanced?
//}

// MARK: concrete implementations

// MARK: - Bybit Parsers

struct BybitSpotWalletDataParser: WalletDataParserProtocol {
    func parseWalletBalance(from data: Data) -> WalletData? {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let result = json["result"] as? [String: Any] else {
                return nil
            }
            // SPOT prefers coin-level parsing, fallback to totals
            return bybitParseUSDTFromCoins(result) ?? bybitParseTotals(result)
        } catch {
            print("Bybit JSON Parse Error: \(error.localizedDescription)")
            return nil
        }
    }
}

struct BybitUnifiedWalletDataParser: WalletDataParserProtocol {
    func parseWalletBalance(from data: Data) -> WalletData? {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let result = json["result"] as? [String: Any] else {
                return nil
            }
            // UNIFIED prefers totals, fallback to coin-level if present
            return bybitParseTotals(result) ?? bybitParseUSDTFromCoins(result)
        } catch {
            print("Bybit JSON Parse Error: \(error.localizedDescription)")
            return nil
        }
    }
}

// Shared helpers to avoid duplication between spot and unified parsers
private func bybitParseUSDTFromCoins(_ result: [String: Any]) -> WalletData? {
    if let list = result["list"] as? [[String: Any]],
       let first = list.first,
       let coins = first["coin"] as? [[String: Any]],
       let usdtCoin = coins.first(where: { $0["coin"] as? String == "USDT" }) {
        
        // Parse wallet balance
        guard let walletBalance = parseDouble(usdtCoin["walletBalance"]) 
                ?? parseDouble(usdtCoin["availableToWithdraw"]) else {
            return nil
        }
        
        // Parse equity (fallback to wallet balance)
        let totalEquity = parseDouble(usdtCoin["equity"]) ?? walletBalance
        let maintenanceMargin = parseDouble(first["totalMaintenanceMargin"]) ?? 0
        
        return WalletData(totalEquity: totalEquity, walletBalance: walletBalance, maintenanceMargin: maintenanceMargin)
    }
    return nil
}

private func bybitParseTotals(_ result: [String: Any]) -> WalletData? {
    guard let totalEquity = parseDouble(result["totalEquity"]),
          let totalWalletBalance = parseDouble(result["totalWalletBalance"]) else {
        return nil
    }
    let maintenanceMargin = parseDouble(result["totalMaintenanceMargin"]) ?? 0
    return WalletData(totalEquity: totalEquity, walletBalance: totalWalletBalance, maintenanceMargin: maintenanceMargin)
}

/// Helper to parse Double from various formats (String, Double, Int, NSNumber)
private func parseDouble(_ value: Any?) -> Double? {
    if let doubleValue = value as? Double {
        return doubleValue
    }
    if let stringValue = value as? String, let parsed = Double(stringValue) {
        return parsed
    }
    if let intValue = value as? Int {
        return Double(intValue)
    }
    if let numValue = value as? NSNumber {
        return numValue.doubleValue
    }
    return nil
}

// MARK: - KuCoin Parser
struct KuCoinWalletDataParser: WalletDataParserProtocol {
    let walletType: WalletType
    
    init(walletType: WalletType = .spot) {
        self.walletType = walletType
    }
    
    func parseWalletBalance(from data: Data) -> WalletData? {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                print("KuCoin JSON Parse Error: Invalid data structure")
                return nil
            }
            
            switch walletType {
            case .spot:
                return parseSpotWalletBalance(from: json)
            case .futures:
                return parseFuturesWalletBalance(from: json)
            case .unified:
                return parseFuturesWalletBalance(from: json) // Kucoin does not have unified wallet
            }
            
        } catch {
            print("KuCoin JSON Parse Error: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Spot Wallet Parsing
    
    private func parseSpotWalletBalance(from json: [String: Any]) -> WalletData? {
        guard let dataArray = json["data"] as? [[String: Any]] else {
            print("KuCoin Spot: Invalid data structure")
            return nil
        }
        
        // Parse all accounts
        let accounts = parseKuCoinAccounts(from: dataArray)
        
        // Aggregate balances by currency
        let aggregatedBalances = aggregateBalances(accounts: accounts)
        
        // Find USDT balance (primary focus)
        let usdtBalance = aggregatedBalances.first { $0.currency == "USDT" }
        
        // Calculate total portfolio value in USDT
        let totalPortfolioValue = calculateTotalPortfolioValue(aggregatedBalances: aggregatedBalances)
        
        // Use USDT available balance as wallet balance, total portfolio as equity
        let walletBalance = usdtBalance?.totalAvailable ?? 0
        let totalEquity = totalPortfolioValue
        
        // Spot accounts don't have maintenance margin (0)
        return WalletData(totalEquity: totalEquity, walletBalance: walletBalance, maintenanceMargin: 0)
    }
    
    // MARK: - Futures Wallet Parsing
    
    private func parseFuturesWalletBalance(from json: [String: Any]) -> WalletData? {
        // Parse the actual futures response structure
        if let data = json["data"] as? [String: Any],
           let accountEquity = data["accountEquity"] as? Double,
           let availableBalance = data["availableBalance"] as? Double,
           let currency = data["currency"] as? String {
            
            // Extract maintenance margin if available (defaults to 0)
            let maintenanceMargin = (data["marginBalance"] as? Double) ?? 0
            
            print("KuCoin  Currency: \(currency)")
            print("KuCoin  Account Equity: \(accountEquity)")
            print("KuCoin  Available Balance: \(availableBalance)")
            print("KuCoin  Maintenance Margin: \(maintenanceMargin)")
            
            return WalletData(totalEquity: accountEquity, walletBalance: availableBalance, maintenanceMargin: maintenanceMargin)
        }
        
        // Fallback: try to parse as spot format if futures uses similar structure
        print("KuCoin Futures: Trying fallback parsing")
        return parseSpotWalletBalance(from: json)
    }
    
//    public func parseDetailedWalletBalance(from data: Data) -> BBWalletDataEnhanced? {
//        do {
//            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
//                  let dataArray = json["data"] as? [[String: Any]] else {
//                print("KuCoin JSON Parse Error: Invalid data structure")
//                return nil
//            }
//            
//            // Parse all accounts
//            let accounts = parseKuCoinAccounts(from: dataArray)
//            
//            // Aggregate balances by currency
//            let aggregatedBalances = aggregateBalances(accounts: accounts)
//            
//            // Calculate total portfolio value
//            let totalPortfolioValue = calculateTotalPortfolioValue(aggregatedBalances: aggregatedBalances)
//            
//            // Create breakdown by account type
//            var breakdown: [String: String] = [:]
//            var allAssets: [String: String] = [:]
//            
//            // Group by account type
//            var accountTypeMap: [String: [KuCoinAccount]] = [:]
//            for account in accounts {
//                if accountTypeMap[account.type] == nil {
//                    accountTypeMap[account.type] = []
//                }
//                accountTypeMap[account.type]?.append(account)
//            }
//            
//            // Calculate totals by account type
//            for (accountType, typeAccounts) in accountTypeMap {
//                let totalBalance = typeAccounts.compactMap { Double($0.balance) }.reduce(0, +)
//                breakdown[accountType] = String(format: "%.2f", totalBalance)
//            }
//            
//            // Create asset summary
//            for balance in aggregatedBalances {
//                allAssets[balance.currency] = String(format: "%.2f", balance.totalBalance)
//            }
//            
//            // Find USDT balance for wallet balance
//            let usdtBalance = aggregatedBalances.first { $0.currency == "USDT" }
//            let walletBalance = usdtBalance?.totalAvailable.description ?? "0.00"
//            
//            return BBWalletDataEnhanced(
//                totalEquity: String(format: "%.2f", totalPortfolioValue),
//                walletBalance: walletBalance,
//                breakdown: breakdown,
//                allAssets: allAssets
//            )
//            
//        } catch {
//            print("KuCoin JSON Parse Error: \(error.localizedDescription)")
//            return nil
//        }
//    }
    
    // MARK: - Helper Methods
    
    private func parseKuCoinAccounts(from dataArray: [[String: Any]]) -> [KuCoinAccount] {
        var accounts: [KuCoinAccount] = []
        
        for accountData in dataArray {
            guard let id = accountData["id"] as? String,
                  let currency = accountData["currency"] as? String,
                  let type = accountData["type"] as? String,
                  let balance = accountData["balance"] as? String,
                  let available = accountData["available"] as? String,
                  let holds = accountData["holds"] as? String else {
                continue
            }
            
            let account = KuCoinAccount(
                id: id,
                currency: currency,
                type: type,
                balance: balance,
                available: available,
                holds: holds
            )
            accounts.append(account)
        }
        
        return accounts
    }
    
    private func aggregateBalances(accounts: [KuCoinAccount]) -> [KuCoinAggregatedBalance] {
        var balanceMap: [String: [KuCoinAccount]] = [:]
        
        // Group accounts by currency
        for account in accounts {
            if balanceMap[account.currency] == nil {
                balanceMap[account.currency] = []
            }
            balanceMap[account.currency]?.append(account)
        }
        
        // Calculate totals for each currency
        var aggregatedBalances: [KuCoinAggregatedBalance] = []
        
        for (currency, currencyAccounts) in balanceMap {
            let totalBalance = currencyAccounts.compactMap { Double($0.balance) }.reduce(0, +)
            let totalAvailable = currencyAccounts.compactMap { Double($0.available) }.reduce(0, +)
            
            let aggregatedBalance = KuCoinAggregatedBalance(
                currency: currency,
                totalBalance: totalBalance,
                totalAvailable: totalAvailable,
                accounts: currencyAccounts
            )
            aggregatedBalances.append(aggregatedBalance)
        }
        
        return aggregatedBalances
    }
    
    private func calculateTotalPortfolioValue(aggregatedBalances: [KuCoinAggregatedBalance]) -> Double {
        // For now, we'll focus on major currencies and estimate USDT value
        // In a production app, you'd want to fetch current exchange rates
        
        var totalValue: Double = 0
        
        for balance in aggregatedBalances {
            switch balance.currency {
            case "USDT", "USDC", "TUSD", "BUSD":
                // Stablecoins - 1:1 with USD
                totalValue += balance.totalBalance
            case "BTC", "ETH":
                // Major cryptocurrencies - rough estimate (you'd want real-time rates)
                // For now, we'll use a conservative estimate
                let estimatedRate: Double = balance.currency == "BTC" ? 40000 : 2000
                totalValue += balance.totalBalance * estimatedRate
            default:
                // Other currencies - could be worth significant amounts
                // For now, we'll include them but with a note
                print("KuCoin: Including \(balance.currency) balance: \(balance.totalBalance) (consider fetching real-time rates)")
                totalValue += balance.totalBalance * 0.1 // Conservative estimate
            }
        }
        
        return totalValue
    }
}

// MARK: - Binance Parser
struct BinanceWalletDataParser: WalletDataParserProtocol {
    func parseWalletBalance(from data: Data) -> WalletData? {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                return nil
            }

            // Prefer USDT-M Futures account response fields (GET /fapi/v2/account)
            // totalMarginBalance = equity (wallet balance + unrealized PnL)
            // totalWalletBalance = wallet balance (excludes unrealized PnL)
            // totalMaintMargin = maintenance margin
            guard let totalMarginBalance = valueAsDouble(json["totalMarginBalance"]),
                  let totalWalletBalance = valueAsDouble(json["totalWalletBalance"]) else {
                return nil
            }
            
            let maintenanceMargin = valueAsDouble(json["totalMaintMargin"]) ?? 0
            return WalletData(totalEquity: totalMarginBalance, walletBalance: totalWalletBalance, maintenanceMargin: maintenanceMargin)

        } catch {
            print("Binance JSON Parse Error: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func valueAsDouble(_ value: Any?) -> Double? {
        if let dbl = value as? Double { return dbl }
        if let str = value as? String { return Double(str) }
        if let num = value as? NSNumber { return num.doubleValue }
        if let intVal = value as? Int { return Double(intVal) }
        return nil
    }
}
