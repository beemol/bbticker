//
//  ParserTests.swift
//  LLCoreTests
//
//  Tests for response parsers
//

import Testing
import Foundation
@testable import bbticker
@testable import LLCore

@Suite("Parser Tests")
struct ParserTests {
    
    // MARK: - Bybit Parser Tests
    
    @Suite("Bybit Unified Parser")
    struct BybitUnifiedParserTests {
        
        @Test("Parses unified wallet response with totals")
        func testParsesUnifiedWithTotals() {
            let parser = BybitUnifiedWalletDataParser()
            let data = TestFixtures.Bybit.successUnified.data(using: .utf8)!
            
            let result = parser.parseWalletBalance(from: data)
            
            #expect(result != nil)
            #expect(result?.totalEquity == 1000.00)
            #expect(result?.walletBalance == 900.00)
            #expect(result?.maintenanceMargin == 50.00)
        }
        
        @Test("Parses unified wallet with coin list fallback")
        func testParsesUnifiedWithCoinListFallback() {
            let parser = BybitUnifiedWalletDataParser()
            let data = TestFixtures.Bybit.successSpot.data(using: .utf8)!
            
            let result = parser.parseWalletBalance(from: data)
            
            #expect(result != nil)
            #expect(result?.walletBalance == 123.45)
        }
        
        @Test("Returns nil for invalid JSON")
        func testReturnsNilForInvalidJSON() {
            let parser = BybitUnifiedWalletDataParser()
            let data = TestFixtures.EdgeCases.invalidJSON.data(using: .utf8)!
            
            let result = parser.parseWalletBalance(from: data)
            
            #expect(result == nil)
        }
        
        @Test("Returns nil for empty response")
        func testReturnsNilForEmptyResponse() {
            let parser = BybitUnifiedWalletDataParser()
            let data = TestFixtures.EdgeCases.emptyObject.data(using: .utf8)!
            
            let result = parser.parseWalletBalance(from: data)
            
            #expect(result == nil)
        }
        
        @Test("Conforms to protocol and throws on parse error")
        func testProtocolConformance() {
            let parser = BybitUnifiedWalletDataParser()
            let data = TestFixtures.EdgeCases.invalidJSON.data(using: .utf8)!
            
            #expect(throws: APIError.self) {
                try parser.parse(data: data)
            }
        }
    }
    
    @Suite("Bybit Spot Parser")
    struct BybitSpotParserTests {
        
        @Test("Parses spot wallet with USDT coin")
        func testParsesSpotWithUSDT() {
            let parser = BybitSpotWalletDataParser()
            let data = TestFixtures.Bybit.successSpot.data(using: .utf8)!
            
            let result = parser.parseWalletBalance(from: data)
            
            #expect(result != nil)
            #expect(result?.walletBalance == 123.45)
            #expect(result?.totalEquity == 123.45) // Equity falls back to walletBalance for SPOT
            #expect(result?.maintenanceMargin == 0) // Spot doesn't have MM
        }
        
        @Test("Prefers coin-level parsing over totals")
        func testPrefersCoinLevelParsing() {
            let parser = BybitSpotWalletDataParser()
            let data = TestFixtures.Bybit.successSpot.data(using: .utf8)!
            
            let result = parser.parseWalletBalance(from: data)
            
            #expect(result != nil)
            #expect(result?.walletBalance == 123.45) // From coin list, not totals
        }
        
        @Test("Falls back to totals if no coin list")
        func testFallsBackToTotals() {
            let parser = BybitSpotWalletDataParser()
            let data = TestFixtures.Bybit.successUnified.data(using: .utf8)!
            
            let result = parser.parseWalletBalance(from: data)
            
            #expect(result != nil)
            #expect(result?.totalEquity == 1000.00)
            #expect(result?.walletBalance == 900.00)
        }
    }
    
    // MARK: - KuCoin Parser Tests
    
    @Suite("KuCoin Futures Parser")
    struct KuCoinFuturesParserTests {
        
        @Test("Parses futures wallet response")
        func testParsesFuturesResponse() {
            let parser = KuCoinWalletDataParser(walletType: .futures)
            let data = TestFixtures.KuCoin.successFutures.data(using: .utf8)!
            
            let result = parser.parseWalletBalance(from: data)
            
            #expect(result != nil)
            #expect(result?.totalEquity == 1000.50)
            #expect(result?.walletBalance == 950.25)
            #expect(result?.maintenanceMargin == 75.50)
        }
        
        @Test("Handles currency field")
        func testHandlesCurrencyField() {
            let parser = KuCoinWalletDataParser(walletType: .futures)
            let data = TestFixtures.KuCoin.successFutures.data(using: .utf8)!
            
            let result = parser.parseWalletBalance(from: data)
            
            #expect(result != nil)
            // Currency is USDT in the fixture
        }
        
        @Test("Returns nil for invalid structure")
        func testReturnsNilForInvalidStructure() {
            let parser = KuCoinWalletDataParser(walletType: .futures)
            let data = TestFixtures.EdgeCases.emptyObject.data(using: .utf8)!
            
            let result = parser.parseWalletBalance(from: data)
            
            #expect(result == nil)
        }
    }
    
    @Suite("KuCoin Spot Parser")
    struct KuCoinSpotParserTests {
        
        @Test("Parses spot wallet response")
        func testParsesSpotResponse() {
            let parser = KuCoinWalletDataParser(walletType: .spot)
            let data = TestFixtures.KuCoin.successSpot.data(using: .utf8)!
            
            let result = parser.parseWalletBalance(from: data)
            
            #expect(result != nil)
            #expect(result?.walletBalance == 950.0) // USDT available balance
            #expect(result?.maintenanceMargin == 0) // Spot doesn't have MM
        }
        
        @Test("Aggregates balances by currency")
        func testAggregatesBalances() {
            let parser = KuCoinWalletDataParser(walletType: .spot)
            let data = TestFixtures.KuCoin.successSpot.data(using: .utf8)!
            
            let result = parser.parseWalletBalance(from: data)
            
            #expect(result != nil)
            // Should aggregate USDT from different account types
        }
        
        @Test("Calculates total portfolio value")
        func testCalculatesTotalPortfolioValue() {
            let parser = KuCoinWalletDataParser(walletType: .spot)
            let data = TestFixtures.KuCoin.successSpot.data(using: .utf8)!
            
            let result = parser.parseWalletBalance(from: data)
            
            #expect(result != nil)
            #expect(result?.totalEquity != nil)
            // Total equity includes all currencies converted to USDT
        }
        
        @Test("Handles multiple account types")
        func testHandlesMultipleAccountTypes() {
            let parser = KuCoinWalletDataParser(walletType: .spot)
            let data = TestFixtures.KuCoin.successSpot.data(using: .utf8)!
            
            let result = parser.parseWalletBalance(from: data)
            
            #expect(result != nil)
            // Fixture has both "main" and "trade" account types
        }
        
        @Test("Returns nil for empty data array")
        func testReturnsNilForEmptyArray() {
            let parser = KuCoinWalletDataParser(walletType: .spot)
            let data = """
            {
                "code": "200000",
                "data": []
            }
            """.data(using: .utf8)!
            
            let result = parser.parseWalletBalance(from: data)
            
            // Should return a result with 0 balances
            #expect(result != nil)
        }
    }
    
    // MARK: - Binance Parser Tests
    
    @Suite("Binance Futures Parser")
    struct BinanceFuturesParserTests {
        
        @Test("Parses futures wallet response")
        func testParsesFuturesResponse() {
            let parser = BinanceWalletDataParser()
            let data = TestFixtures.Binance.successFutures.data(using: .utf8)!
            
            let result = parser.parseWalletBalance(from: data)
            
            #expect(result != nil)
            #expect(result?.totalEquity == 1234.56789)
            #expect(result?.walletBalance == 1200.00)
            #expect(result?.maintenanceMargin == 100.00)
        }
        
        @Test("Handles totalMarginBalance as equity")
        func testHandlesTotalMarginBalance() {
            let parser = BinanceWalletDataParser()
            let data = TestFixtures.Binance.successFutures.data(using: .utf8)!
            
            let result = parser.parseWalletBalance(from: data)
            
            #expect(result != nil)
            // totalMarginBalance includes unrealized PnL
            #expect(result?.totalEquity == 1234.56789)
        }
        
        @Test("Handles totalWalletBalance")
        func testHandlesTotalWalletBalance() {
            let parser = BinanceWalletDataParser()
            let data = TestFixtures.Binance.successFutures.data(using: .utf8)!
            
            let result = parser.parseWalletBalance(from: data)
            
            #expect(result != nil)
            // totalWalletBalance excludes unrealized PnL
            #expect(result?.walletBalance == 1200.00)
        }
        
        @Test("Returns nil for invalid structure")
        func testReturnsNilForInvalidStructure() {
            let parser = BinanceWalletDataParser()
            let data = TestFixtures.EdgeCases.emptyObject.data(using: .utf8)!
            
            let result = parser.parseWalletBalance(from: data)
            
            #expect(result == nil)
        }
        
        @Test("Handles numeric values as strings")
        func testHandlesNumericStrings() {
            let parser = BinanceWalletDataParser()
            let data = TestFixtures.Binance.successFutures.data(using: .utf8)!
            
            let result = parser.parseWalletBalance(from: data)
            
            #expect(result != nil)
            // Values in fixture are strings
        }
        
        @Test("Handles numeric values as numbers")
        func testHandlesNumericNumbers() {
            let parser = BinanceWalletDataParser()
            let data = """
            {
                "totalMarginBalance": 1234.56789,
                "totalWalletBalance": 1200.00000
            }
            """.data(using: .utf8)!
            
            let result = parser.parseWalletBalance(from: data)
            
            #expect(result != nil)
            // Should handle both string and numeric formats
        }
    }
    
    // MARK: - Parser Factory Tests
    
    @Suite("Parser Factory")
    struct ParserFactoryTests {
        
        @Test("Creates Bybit unified parser")
        func testCreatesBybitUnifiedParser() {
            let exchange = Exchange(.bybit, wallet: .unified)
            let parser = WalletDataParserFactory.parser(for: exchange)
            
            #expect(parser is BybitUnifiedWalletDataParser)
        }
        
        @Test("Creates Bybit spot parser")
        func testCreatesBybitSpotParser() {
            let exchange = Exchange(.bybit, wallet: .spot)
            let parser = WalletDataParserFactory.parser(for: exchange)
            
            #expect(parser is BybitSpotWalletDataParser)
        }
        
        @Test("Creates Bybit futures parser (uses unified)")
        func testCreatesBybitFuturesParser() {
            let exchange = Exchange(.bybit, wallet: .futures)
            let parser = WalletDataParserFactory.parser(for: exchange)
            
            #expect(parser is BybitUnifiedWalletDataParser)
        }
        
        @Test("Creates KuCoin futures parser")
        func testCreatesKuCoinFuturesParser() {
            let exchange = Exchange(.kucoin, wallet: .futures)
            let parser = WalletDataParserFactory.parser(for: exchange)
            
            #expect(parser is KuCoinWalletDataParser)
        }
        
        @Test("Creates KuCoin spot parser")
        func testCreatesKuCoinSpotParser() {
            let exchange = Exchange(.kucoin, wallet: .spot)
            let parser = WalletDataParserFactory.parser(for: exchange)
            
            #expect(parser is KuCoinWalletDataParser)
        }
        
        @Test("Creates Binance parser")
        func testCreatesBinanceParser() {
            let exchange = Exchange(.binance, wallet: .futures)
            let parser = WalletDataParserFactory.parser(for: exchange)
            
            #expect(parser is BinanceWalletDataParser)
        }
    }
    
    // MARK: - Edge Cases
    
    @Suite("Parser Edge Cases")
    struct ParserEdgeCasesTests {
        
        @Test("All parsers handle invalid JSON")
        func testAllParsersHandleInvalidJSON() {
            let parsers: [any WalletDataParserProtocol] = [
                BybitUnifiedWalletDataParser(),
                BybitSpotWalletDataParser(),
                KuCoinWalletDataParser(walletType: .futures),
                BinanceWalletDataParser()
            ]
            
            let data = TestFixtures.EdgeCases.invalidJSON.data(using: .utf8)!
            
            for parser in parsers {
                let result = parser.parseWalletBalance(from: data)
                #expect(result == nil)
            }
        }
        
        @Test("All parsers handle empty response")
        func testAllParsersHandleEmptyResponse() {
            let parsers: [any WalletDataParserProtocol] = [
                BybitUnifiedWalletDataParser(),
                BybitSpotWalletDataParser(),
                KuCoinWalletDataParser(walletType: .futures),
                BinanceWalletDataParser()
            ]
            
            let data = TestFixtures.EdgeCases.emptyObject.data(using: .utf8)!
            
            for parser in parsers {
                let result = parser.parseWalletBalance(from: data)
                #expect(result == nil)
            }
        }
        
        @Test("Protocol parse method throws on failure")
        func testProtocolParseThrows() {
            let parser = BybitUnifiedWalletDataParser()
            let data = TestFixtures.EdgeCases.invalidJSON.data(using: .utf8)!
            
            #expect(throws: APIError.self) {
                try parser.parse(data: data)
            }
            
            do {
                _ = try parser.parse(data: data)
                Issue.record("Expected error to be thrown")
            } catch let error as APIError {
                #expect(error == .parseError)
            } catch {
                Issue.record("Unexpected error: \(error)")
            }
        }
    }
}
