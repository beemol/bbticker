//
//  ModelTests.swift
//  LLCoreTests
//
//  Tests for data models
//

import Testing
import Foundation
@testable import bbticker
@testable import LLCore

@Suite("Model Tests")
struct ModelTests {
    
    // MARK: - Exchange Tests
    
    @Suite("Exchange")
    struct ExchangeTests {
        
        @Test("Bybit unified has correct properties")
        func testBybitUnifiedProperties() {
            let exchange = Exchange(.bybit, wallet: .unified)
            
            #expect(exchange.walletType == .unified)
            #expect(exchange.displayName == "bybit")
            #expect(exchange.baseURL == "https://api.bybit.com")
            #expect(exchange.endpoint == "/v5/account/wallet-balance?accountType=UNIFIED")
            #expect(exchange.identifier == .bybit)
        }
        
        @Test("Bybit spot has correct properties")
        func testBybitSpotProperties() {
            let exchange = Exchange(.bybit, wallet: .spot)
            
            #expect(exchange.walletType == .spot)
            #expect(exchange.displayName == "bybit")
            #expect(exchange.baseURL == "https://api.bybit.com")
            #expect(exchange.endpoint == "/v5/account/wallet-balance?accountType=SPOT")
        }
        
        @Test("Bybit demo environment has correct URL")
        func testBybitDemoEnvironment() {
            let exchange = Exchange(.bybit, environment: .demo, wallet: .unified)
            
            #expect(exchange.environment == .demo)
            #expect(exchange.baseURL == "https://api-demo.bybit.com")
        }
        
        @Test("KuCoin futures has correct properties")
        func testKuCoinFuturesProperties() {
            let exchange = Exchange(.kucoin, wallet: .futures)
            
            #expect(exchange.walletType == .futures)
            #expect(exchange.displayName == "kucoin")
            #expect(exchange.baseURL == "https://api-futures.kucoin.com")
            #expect(exchange.endpoint == "/api/v1/account-overview?currency=USDT")
            #expect(exchange.identifier == .kucoin)
        }
        
        @Test("KuCoin spot has correct properties")
        func testKuCoinSpotProperties() {
            let exchange = Exchange(.kucoin, wallet: .spot)
            
            #expect(exchange.walletType == .spot)
            #expect(exchange.displayName == "kucoin")
            #expect(exchange.baseURL == "https://api-futures.kucoin.com")
            #expect(exchange.endpoint == "/api/v1/accounts?type=main")
        }
        
        @Test("Available wallet types for Bybit")
        func testBybitAvailableWalletTypes() {
            let exchange = Exchange(.bybit, wallet: .unified)
            
            #expect(exchange.availableWalletTypes.contains(.unified))
        }
        
        @Test("Available wallet types for KuCoin")
        func testKuCoinAvailableWalletTypes() {
            let exchange = Exchange(.kucoin, wallet: .futures)
            
            #expect(exchange.availableWalletTypes.contains(.futures))
        }
        
        @Test("Equality works correctly")
        func testEquality() {
            let exchange1 = Exchange(.bybit, wallet: .unified)
            let exchange2 = Exchange(.bybit, wallet: .unified)
            let exchange3 = Exchange(.bybit, wallet: .spot)
            let exchange4 = Exchange(.kucoin, wallet: .unified)
            
            #expect(exchange1 == exchange2)
            #expect(exchange1 != exchange3)
            #expect(exchange1 != exchange4)
        }
        
        @Test("Equality ignores registry")
        func testEqualityIgnoresRegistry() {
            let exchange1 = Exchange(.bybit, wallet: .unified, registry: ExchangeRegistry.shared)
            let exchange2 = Exchange(.bybit, wallet: .unified, registry: ExchangeRegistry.shared)
            
            #expect(exchange1 == exchange2)
        }
        
        @Test("Hashable works correctly")
        func testHashable() {
            let exchange1 = Exchange(.bybit, wallet: .unified)
            let exchange2 = Exchange(.bybit, wallet: .unified)
            let exchange3 = Exchange(.kucoin, wallet: .futures)
            
            var set = Set<Exchange>()
            set.insert(exchange1)
            set.insert(exchange2) // Should not add duplicate
            set.insert(exchange3)
            
            #expect(set.count == 2)
            #expect(set.contains(exchange1))
            #expect(set.contains(exchange3))
        }
        
        @Test("Environment defaults to production")
        func testEnvironmentDefaultsToProduction() {
            let exchange = Exchange(.bybit, wallet: .unified)
            
            #expect(exchange.environment == .production)
        }
    }
    
    // MARK: - ExchangeIdentifier Tests
    
    @Suite("ExchangeIdentifier")
    struct ExchangeIdentifierTests {
        
        @Test("Known identifiers are defined")
        func testKnownIdentifiers() {
            #expect(ExchangeIdentifier.bybit.rawValue == "bybit")
            #expect(ExchangeIdentifier.kucoin.rawValue == "kucoin")
            #expect(ExchangeIdentifier.binance.rawValue == "binance")
        }
        
        @Test("Can create custom identifier")
        func testCustomIdentifier() {
            let custom = ExchangeIdentifier(rawValue: "okx")
            #expect(custom.rawValue == "okx")
        }
        
        @Test("String literal initialization")
        func testStringLiteralInit() {
            let identifier: ExchangeIdentifier = "kraken"
            #expect(identifier.rawValue == "kraken")
        }
        
        @Test("Identifier is hashable")
        func testHashable() {
            var set = Set<ExchangeIdentifier>()
            set.insert(.bybit)
            set.insert(.kucoin)
            set.insert(.binance)
            
            #expect(set.count == 3)
        }
        
        @Test("Identifier is equatable")
        func testEquatable() {
            #expect(ExchangeIdentifier.bybit == ExchangeIdentifier(rawValue: "bybit"))
            #expect(ExchangeIdentifier.bybit != ExchangeIdentifier.kucoin)
        }
    }
    
    // MARK: - WalletType Tests
    
    @Suite("WalletType")
    struct WalletTypeTests {
        
        @Test("All wallet types are defined")
        func testAllWalletTypes() {
            let types = WalletType.allCases
            
            #expect(types.contains(.spot))
            #expect(types.contains(.futures))
            #expect(types.contains(.unified))
            #expect(types.count == 3)
        }
        
        @Test("Wallet type raw values")
        func testRawValues() {
            #expect(WalletType.spot.rawValue == "spot")
            #expect(WalletType.futures.rawValue == "futures")
            #expect(WalletType.unified.rawValue == "unified")
        }
        
        @Test("Wallet type is hashable")
        func testHashable() {
            var set = Set<WalletType>()
            set.insert(.spot)
            set.insert(.futures)
            set.insert(.unified)
            
            #expect(set.count == 3)
        }
        
        @Test("WalletType is Sendable")
        func testWalletTypeIsSendable() {
            let walletType = WalletType.unified
            
            // Should compile without warnings about Sendable
            Task {
                let _ = walletType
            }
        }
    }
    
    // MARK: - APIEnvironment Tests
    
    @Suite("APIEnvironment")
    struct APIEnvironmentTests {
        
        @Test("All environments are defined")
        func testAllEnvironments() {
            #expect(APIEnvironment.production.rawValue == "production")
            #expect(APIEnvironment.testnet.rawValue == "testnet")
            #expect(APIEnvironment.demo.rawValue == "demo")
        }
        
        @Test("Environment is hashable")
        func testHashable() {
            var set = Set<APIEnvironment>()
            set.insert(.production)
            set.insert(.testnet)
            set.insert(.demo)
            
            #expect(set.count == 3)
        }
    }
    
    // MARK: - ExchangeCapabilities Tests
    
    @Suite("ExchangeCapabilities")
    struct ExchangeCapabilitiesTests {
        
        @Test("Available wallet types derived from endpoints")
        func testAvailableWalletTypesDerived() {
            let caps = ExchangeCapabilities(
                urls: [.production: "https://api.example.com"],
                endpoints: [.wallet(.spot): "/spot", .wallet(.futures): "/futures"]
            )
            
            #expect(caps.availableWalletTypes.contains(.spot))
            #expect(caps.availableWalletTypes.contains(.futures))
            #expect(!caps.availableWalletTypes.contains(.unified))
        }
        
        @Test("Available environments derived from urls")
        func testAvailableEnvironmentsDerived() {
            let caps = ExchangeCapabilities(
                urls: [.production: "https://api.example.com", .demo: "https://demo.example.com"],
                endpoints: [.wallet(.spot): "/spot"]
            )
            
            #expect(caps.availableEnvironments.contains(.production))
            #expect(caps.availableEnvironments.contains(.demo))
            #expect(!caps.availableEnvironments.contains(.testnet))
        }
    }
    
    // MARK: - WalletData Tests
    
    @Suite("WalletData")
    struct WalletDataTests {
        
        @Test("Initializes with values")
        func testInitialization() {
            let data = WalletData(totalEquity: 1000.00, walletBalance: 900.00)
            
            #expect(data.totalEquity == 1000.00)
            #expect(data.walletBalance == 900.00)
            #expect(data.maintenanceMargin == 0) // Default value
        }
        
        @Test("Initializes with maintenance margin")
        func testInitializationWithMaintenanceMargin() {
            let data = WalletData(totalEquity: 1000.00, walletBalance: 900.00, maintenanceMargin: 50.00)
            
            #expect(data.totalEquity == 1000.00)
            #expect(data.walletBalance == 900.00)
            #expect(data.maintenanceMargin == 50.00)
        }
        
        @Test("Handles zero values")
        func testHandlesZeroValues() {
            let data = WalletData(totalEquity: 0.00, walletBalance: 0.00)
            
            #expect(data.totalEquity == 0.00)
            #expect(data.walletBalance == 0.00)
            #expect(data.maintenanceMargin == 0)
        }
        
        @Test("Ensures maintenance margin is non-negative")
        func testMaintenanceMarginNonNegative() {
            let data = WalletData(totalEquity: 1000.00, walletBalance: 900.00, maintenanceMargin: -50.00)
            
            #expect(data.maintenanceMargin == 0) // Clamped to 0
        }
        
        @Test("Handles large values")
        func testHandlesLargeValues() {
            let data = WalletData(
                totalEquity: 123456789.12345678,
                walletBalance: 987654321.87654321
            )
            
            #expect(abs(data.totalEquity - 123456789.12345678) < 0.0001)
            #expect(abs(data.walletBalance - 987654321.87654321) < 0.0001)
        }
        
        @Test("Calculates maintenance margin percentage correctly")
        func testMaintenanceMarginPercentageCalculation() {
            let data = WalletData(totalEquity: 1000.00, walletBalance: 900.00, maintenanceMargin: 50.00)
            
            let percentage = data.maintenanceMarginPercentage
            #expect(abs(percentage - 5.0) < 0.001) // 50/1000 * 100 = 5%
        }
        
        @Test("Calculates high maintenance margin percentage")
        func testHighMaintenanceMarginPercentage() {
            let data = WalletData(totalEquity: 10.00, walletBalance: 5.00, maintenanceMargin: 3.8)
            
            let percentage = data.maintenanceMarginPercentage
            #expect(abs(percentage - 38.0) < 0.001) // 3.8/10 * 100 = 38%
        }
        
        @Test("Returns zero percentage for zero maintenance margin")
        func testMaintenanceMarginPercentageZeroMM() {
            let data = WalletData(totalEquity: 1000.00, walletBalance: 900.00) // MM defaults to 0
            
            let percentage = data.maintenanceMarginPercentage
            #expect(percentage == 0) // 0/1000 * 100 = 0%
        }
        
        @Test("Returns zero for zero equity")
        func testMaintenanceMarginPercentageZeroEquity() {
            let data = WalletData(totalEquity: 0.00, walletBalance: 0.00, maintenanceMargin: 50.00)
            
            #expect(data.maintenanceMarginPercentage == 0) // Avoid division by zero, return 0
        }
        
//        @Test("Formats maintenance margin percentage correctly")
//        func testMaintenanceMarginPercentageFormatted() {
//            let data = WalletData(totalEquity: 1000.00, walletBalance: 900.00, maintenanceMargin: 50.00)
//            
//            #expect(data.maintenanceMarginPercentageFormatted() == "5.00%")
//            #expect(data.maintenanceMarginPercentageFormatted(decimalPlaces: 1) == "5.0%")
//            #expect(data.maintenanceMarginPercentageFormatted(decimalPlaces: 3) == "5.000%")
//        }
        
//        @Test("Formats zero percentage correctly")
//        func testMaintenanceMarginPercentageFormattedZero() {
//            let data = WalletData(totalEquity: 1000.00, walletBalance: 900.00) // MM defaults to 0
//            
//            #expect(data.maintenanceMarginPercentageFormatted() == "0.00%")
//        }
        
        @Test("Calculates percentage with decimal values")
        func testMaintenanceMarginPercentageWithDecimals() {
            let data = WalletData(totalEquity: 9.47368421, walletBalance: 5.00, maintenanceMargin: 3.6)
            
            let percentage = data.maintenanceMarginPercentage
            #expect(abs(percentage - 38.0) < 0.1) // Approximately 38%
        }
    }
    
    // MARK: - Credentials Tests
    
    @Suite("Credentials")
    struct CredentialsTests {
        
        @Test("Initializes with all fields")
        func testInitializationWithAllFields() {
            let creds = Credentials(
                apiKey: "test-key",
                apiSecret: "test-secret",
                passphrase: "test-passphrase"
            )
            
            #expect(creds.apiKey == "test-key")
            #expect(creds.apiSecret == "test-secret")
            #expect(creds.passphrase == "test-passphrase")
        }
        
        @Test("Initializes without passphrase")
        func testInitializationWithoutPassphrase() {
            let creds = Credentials(
                apiKey: "test-key",
                apiSecret: "test-secret"
            )
            
            #expect(creds.apiKey == "test-key")
            #expect(creds.apiSecret == "test-secret")
            #expect(creds.passphrase == nil)
        }
        
        @Test("Credentials are equatable")
        func testEquatable() {
            let creds1 = Credentials(apiKey: "key1", apiSecret: "secret1", passphrase: "pass1")
            let creds2 = Credentials(apiKey: "key1", apiSecret: "secret1", passphrase: "pass1")
            let creds3 = Credentials(apiKey: "key2", apiSecret: "secret2", passphrase: "pass2")
            
            #expect(creds1 == creds2)
            #expect(creds1 != creds3)
        }
        
        @Test("Credentials with nil passphrase are equal")
        func testEquatableWithNilPassphrase() {
            let creds1 = Credentials(apiKey: "key1", apiSecret: "secret1", passphrase: nil)
            let creds2 = Credentials(apiKey: "key1", apiSecret: "secret1", passphrase: nil)
            
            #expect(creds1 == creds2)
        }
        
        @Test("Credentials are Sendable")
        func testCredentialsAreSendable() {
            let creds = Credentials(apiKey: "key", apiSecret: "secret")
            
            // Should compile without warnings about Sendable
            Task {
                let _ = creds
            }
        }
    }
    
    // MARK: - APIError Tests
    
    @Suite("APIError")
    struct APIErrorTests {
        
        @Test("All error cases are defined")
        func testAllErrorCases() {
            let error1: APIError = .invalidRequest
            let error2: APIError = .noData
            let error3: APIError = .parseError
            
            #expect(error1 == .invalidRequest)
            #expect(error2 == .noData)
            #expect(error3 == .parseError)
        }
        
        @Test("Localized descriptions are provided")
        func testLocalizedDescriptions() {
            #expect(APIError.invalidRequest.localizedDescription == "Invalid API request")
            #expect(APIError.noData.localizedDescription == "No data received from API")
            #expect(APIError.parseError.localizedDescription == "Failed to parse API response")
        }
        
        @Test("APIError is Error")
        func testIsError() {
            let error: Error = APIError.invalidRequest
            
            #expect(error is APIError)
        }
    }
    
    // MARK: - APIDomainError Tests
    
    @Suite("APIDomainError")
    struct APIDomainErrorTests {
        
        @Test("All domain error cases have message keys")
        func testMessageKeys() {
            let context = APIErrorContext(exchange: .bybit)
            
            #expect(APIDomainError.invalidCredentials(context: context).messageKey == "api.invalidCredentials.message")
            #expect(APIDomainError.permissionDenied(context: context).messageKey == "api.permissionDenied.message")
            #expect(APIDomainError.ipNotAllowed(context: context).messageKey == "api.ipNotAllowed.message")
            #expect(APIDomainError.keyRevokedOrInactive(context: context).messageKey == "api.keyRevokedOrInactive.message")
            #expect(APIDomainError.signatureInvalid(context: context).messageKey == "api.signatureInvalid.message")
            #expect(APIDomainError.timestampOutOfRange(context: context).messageKey == "api.timestampOutOfRange.message")
            #expect(APIDomainError.missingOrInvalidParams(context: context).messageKey == "api.missingOrInvalidParams.message")
            #expect(APIDomainError.rateLimited(context: context).messageKey == "api.rateLimited.message")
            #expect(APIDomainError.maintenance(context: context).messageKey == "api.maintenance.message")
            #expect(APIDomainError.server(context: context).messageKey == "api.server.message")
            #expect(APIDomainError.network(context: context).messageKey == "api.network.message")
            #expect(APIDomainError.unknown(context: context).messageKey == "api.unknown.message")
        }
        
        @Test("All domain errors have user messages")
        func testUserMessages() {
            let context = APIErrorContext(exchange: .bybit)
            
            #expect(!APIDomainError.invalidCredentials(context: context).userMessage.isEmpty)
            #expect(!APIDomainError.permissionDenied(context: context).userMessage.isEmpty)
            #expect(!APIDomainError.ipNotAllowed(context: context).userMessage.isEmpty)
            #expect(!APIDomainError.keyRevokedOrInactive(context: context).userMessage.isEmpty)
            #expect(!APIDomainError.signatureInvalid(context: context).userMessage.isEmpty)
            #expect(!APIDomainError.timestampOutOfRange(context: context).userMessage.isEmpty)
            #expect(!APIDomainError.rateLimited(context: context).userMessage.isEmpty)
            #expect(!APIDomainError.maintenance(context: context).userMessage.isEmpty)
            #expect(!APIDomainError.server(context: context).userMessage.isEmpty)
            #expect(!APIDomainError.network(context: context).userMessage.isEmpty)
            #expect(!APIDomainError.unknown(context: context).userMessage.isEmpty)
        }
        
        @Test("User messages include exchange name")
        func testUserMessagesIncludeExchangeName() {
            let bybitContext = APIErrorContext(exchange: .bybit)
            let kucoinContext = APIErrorContext(exchange: .kucoin)
            
            let bybitError = APIDomainError.maintenance(context: bybitContext)
            let kucoinError = APIDomainError.maintenance(context: kucoinContext)
            
            #expect(bybitError.userMessage.lowercased().contains("bybit"))
            #expect(kucoinError.userMessage.lowercased().contains("kucoin"))
        }
        
        @Test("Context property returns correct context")
        func testContextProperty() {
            let context = APIErrorContext(
                exchange: .bybit,
                httpStatus: 401,
                apiCode: "10004",
                requestId: "test-id",
                endpoint: "/test",
                rawMessage: "Error"
            )
            
            let error = APIDomainError.invalidCredentials(context: context)
            
            #expect(error.context == context)
        }
        
        @Test("APIDomainError is equatable")
        func testEquatable() {
            let context1 = APIErrorContext(exchange: .bybit)
            let context2 = APIErrorContext(exchange: .bybit)
            let context3 = APIErrorContext(exchange: .kucoin)
            
            let error1 = APIDomainError.invalidCredentials(context: context1)
            let error2 = APIDomainError.invalidCredentials(context: context2)
            let error3 = APIDomainError.invalidCredentials(context: context3)
            let error4 = APIDomainError.permissionDenied(context: context1)
            
            #expect(error1 == error2)
            #expect(error1 != error3)
            #expect(error1 != error4)
        }
        
        @Test("Unknown error includes request ID in message")
        func testUnknownErrorWithRequestID() {
            let context = APIErrorContext(
                exchange: .bybit,
                requestId: "abc-123"
            )
            
            let error = APIDomainError.unknown(context: context)
            
            #expect(error.userMessage.contains("abc-123"))
        }
    }
    
    // MARK: - ExchangeRegistry Tests
    
    @Suite("ExchangeRegistry")
    struct ExchangeRegistryTests {
        
        @Test("Returns capabilities for known exchanges")
        func testReturnsCapabilities() {
            let bybitCaps = ExchangeRegistry.shared.capabilities(for: .bybit)
            let kucoinCaps = ExchangeRegistry.shared.capabilities(for: .kucoin)
            
            #expect(bybitCaps != nil)
            #expect(kucoinCaps != nil)
        }
        
        @Test("Returns nil for unknown exchange")
        func testReturnsNilForUnknown() {
            let caps = ExchangeRegistry.shared.capabilities(for: ExchangeIdentifier(rawValue: "unknown"))
            #expect(caps == nil)
        }
        
        @Test("Available exchanges includes registered exchanges")
        func testAvailableExchanges() {
            let available = ExchangeRegistry.shared.availableExchanges
            
            #expect(available.contains(.bybit))
            #expect(available.contains(.kucoin))
        }
    }
}
