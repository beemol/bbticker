//
//  RequestBuilderTests.swift
//  LLCoreTests
//
//  Tests for API request builders
//

import Testing
import Foundation
@testable import bbticker
@testable import LLCore

@Suite("Request Builder Tests")
struct RequestBuilderTests {
    
    // MARK: - Bybit Request Builder Tests
    
    @Suite("Bybit Request Builder")
    struct BybitRequestBuilderTests {
        
        @Test("Creates valid unified wallet request")
        func testUnifiedWalletRequest() {
            let exchange = Exchange(.bybit, wallet: .unified)
            let credentials = TestFixtures.TestCredentials.bybit
            let builder = BybitWalletAPIRequestBuilder(
                exchangeConfiguration: RegistryHelper().getBybitRegistry().configuration(for: exchange)!,
                walletType: exchange.walletType,
                creds: credentials
            )
            
            let request = try? builder.createRequest()
            
            #expect(request != nil)
            #expect(request?.httpMethod == "GET")
            #expect(request?.url?.absoluteString.contains("api.bybit.com") == true)
            #expect(request?.url?.absoluteString.contains("accountType=UNIFIED") == true)
            #expect(request?.value(forHTTPHeaderField: "X-BAPI-API-KEY") == credentials.apiKey)
            #expect(request?.value(forHTTPHeaderField: "X-BAPI-TIMESTAMP") != nil)
            #expect(request?.value(forHTTPHeaderField: "X-BAPI-RECV-WINDOW") == "5000")
            #expect(request?.value(forHTTPHeaderField: "X-BAPI-SIGN") != nil)
        }
        
        @Test("Creates valid spot wallet request")
        func testSpotWalletRequest() {
            let exchange = Exchange(.bybit, wallet: .spot)
            let credentials = TestFixtures.TestCredentials.bybit
            let builder = BybitWalletAPIRequestBuilder(
                exchangeConfiguration: RegistryHelper().getBybitRegistry().configuration(for: exchange)!,
                walletType: exchange.walletType,
                creds: credentials
            )
            
            let request = try? builder.createRequest()
            
            #expect(request != nil)
            #expect(request?.url?.absoluteString.contains("accountType=SPOT") == true)
        }
        
        @Test("Signature changes with different timestamps")
        func testSignatureChangesWithTimestamp() {
            let exchange = Exchange(.bybit, wallet: .unified)
            let credentials = TestFixtures.TestCredentials.bybit
            let builder = BybitWalletAPIRequestBuilder(
                exchangeConfiguration: RegistryHelper().getBybitRegistry().configuration(for: exchange)!,
                walletType: exchange.walletType,
                creds: credentials
            )
            
            let request1 = try? builder.createRequest()
            Thread.sleep(forTimeInterval: 0.01) // Small delay to ensure different timestamp
            let request2 = try? builder.createRequest()
            
            let signature1 = request1?.value(forHTTPHeaderField: "X-BAPI-SIGN")
            let signature2 = request2?.value(forHTTPHeaderField: "X-BAPI-SIGN")
            
            #expect(signature1 != nil)
            #expect(signature2 != nil)
            #expect(signature1 != signature2)
        }
        
        @Test("Uses correct base URL for unified wallet")
        func testCorrectBaseURL() {
            let exchange = Exchange(.bybit, wallet: .unified)
            let credentials = TestFixtures.TestCredentials.bybit
            let builder = BybitWalletAPIRequestBuilder(
                exchangeConfiguration: RegistryHelper().getBybitRegistry().configuration(for: exchange)!,
                walletType: exchange.walletType,
                creds: credentials
            )
            
            let request = try? builder.createRequest()
            
            #expect(request?.url?.scheme == "https")
            #expect(request?.url?.host == "api.bybit.com")
        }
    }
    
    #if false
    // MARK: - KuCoin Request Builder Tests
    
    @Suite("KuCoin Request Builder")
    struct KuCoinRequestBuilderTests {
        
        @Test("Creates valid futures wallet request")
        func testFuturesWalletRequest() {
            let exchange = Exchange(.kucoin, wallet: .futures)
            let credentials = TestFixtures.TestCredentials.kucoin
            let builder = KuCoinAPIRequestBuilder(Exchange: Exchange, creds: credentials)
            
            let request = try? builder.createRequest()
            
            #expect(request != nil)
            #expect(request?.httpMethod == "GET")
            #expect(request?.url?.absoluteString.contains("api-futures.kucoin.com") == true)
            #expect(request?.value(forHTTPHeaderField: "KC-API-KEY") == credentials.apiKey)
            #expect(request?.value(forHTTPHeaderField: "KC-API-TIMESTAMP") != nil)
            #expect(request?.value(forHTTPHeaderField: "KC-API-SIGN") != nil)
            #expect(request?.value(forHTTPHeaderField: "KC-API-PASSPHRASE") != nil)
            #expect(request?.value(forHTTPHeaderField: "KC-API-KEY-VERSION") == "3")
        }
        
        @Test("Creates valid spot wallet request")
        func testSpotWalletRequest() {
            let exchange = Exchange(.kucoin, wallet: .spot)
            let credentials = TestFixtures.TestCredentials.kucoin
            let builder = KuCoinAPIRequestBuilder(Exchange: Exchange, creds: credentials)
            
            let request = try? builder.createRequest()
            
            #expect(request != nil)
            #expect(request?.url?.absoluteString.contains("kucoin.com") == true)
            #expect(request?.url?.absoluteString.contains("/api/v1/accounts") == true)
        }
        
        @Test("Encrypts passphrase for API v3")
        func testPassphraseEncryption() {
            let exchange = Exchange(.kucoin, wallet: .futures)
            let credentials = TestFixtures.TestCredentials.kucoin
            let builder = KuCoinAPIRequestBuilder(Exchange: Exchange, creds: credentials)
            
            let request = try? builder.createRequest()
            let passphrase = request?.value(forHTTPHeaderField: "KC-API-PASSPHRASE")
            
            #expect(passphrase != nil)
            #expect(passphrase != credentials.passphrase) // Should be encrypted, not plain text
        }
        
        @Test("Signature is base64 encoded")
        func testSignatureFormat() {
            let exchange = Exchange(.kucoin, wallet: .futures)
            let credentials = TestFixtures.TestCredentials.kucoin
            let builder = KuCoinAPIRequestBuilder(Exchange: Exchange, creds: credentials)
            
            let request = try? builder.createRequest()
            let signature = request?.value(forHTTPHeaderField: "KC-API-SIGN")
            
            #expect(signature != nil)
            // Base64 strings typically end with = or contain +/
            let isBase64Like = signature?.contains(where: { "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=".contains($0) }) ?? false
            #expect(isBase64Like)
        }
        
        @Test("Uses correct endpoint for futures")
        func testFuturesEndpoint() {
            let exchange = Exchange(.kucoin, wallet: .futures)
            let credentials = TestFixtures.TestCredentials.kucoin
            let builder = KuCoinAPIRequestBuilder(Exchange: Exchange, creds: credentials)
            
            let request = try? builder.createRequest()
            
            #expect(request?.url?.path.contains("/api/v1/account-overview") == true)
            #expect(request?.url?.query?.contains("currency=USDT") == true)
        }
    }
    
    // MARK: - Binance Request Builder Tests
    
    @Suite("Binance Request Builder")
    struct BinanceRequestBuilderTests {
        
        @Test("Creates valid futures wallet request")
        func testFuturesWalletRequest() {
            let exchange = Exchange(.binance, wallet: .futures)
            let credentials = TestFixtures.TestCredentials.binance
            let builder = BinanceAPIRequestBuilder(Exchange: Exchange, creds: credentials)
            
            let request = try? builder.createRequest()
            
            #expect(request != nil)
            #expect(request?.httpMethod == "GET")
            #expect(request?.url?.absoluteString.contains("binance") == true)
            #expect(request?.url?.absoluteString.contains("/fapi/v2/account") == true)
            #expect(request?.value(forHTTPHeaderField: "X-MBX-APIKEY") == credentials.apiKey)
        }
        
        @Test("Includes timestamp in query string")
        func testTimestampInQuery() {
            let exchange = Exchange(.binance, wallet: .futures)
            let credentials = TestFixtures.TestCredentials.binance
            let builder = BinanceAPIRequestBuilder(Exchange: Exchange, creds: credentials)
            
            let request = try? builder.createRequest()
            
            #expect(request?.url?.query?.contains("timestamp=") == true)
            #expect(request?.url?.query?.contains("recvWindow=5000") == true)
        }
        
        @Test("Includes signature in query string")
        func testSignatureInQuery() {
            let exchange = Exchange(.binance, wallet: .futures)
            let credentials = TestFixtures.TestCredentials.binance
            let builder = BinanceAPIRequestBuilder(Exchange: Exchange, creds: credentials)
            
            let request = try? builder.createRequest()
            
            #expect(request?.url?.query?.contains("signature=") == true)
        }
        
        @Test("Signature is hex string")
        func testSignatureFormat() {
            let exchange = Exchange(.binance, wallet: .futures)
            let credentials = TestFixtures.TestCredentials.binance
            let builder = BinanceAPIRequestBuilder(Exchange: Exchange, creds: credentials)
            
            let request = try? builder.createRequest()
            
            guard let query = request?.url?.query,
                  let signatureRange = query.range(of: "signature="),
                  let signature = query[signatureRange.upperBound...].split(separator: "&").first else {
                Issue.record("Could not extract signature from query string")
                return
            }
            
            // Hex strings contain only 0-9 and a-f
            let isHex = signature.allSatisfy { "0123456789abcdef".contains($0) }
            #expect(isHex)
        }
        
        @Test("Uses testnet URL")
        func testTestnetURL() {
            let exchange = Exchange(.binance, wallet: .futures)
            let credentials = TestFixtures.TestCredentials.binance
            let builder = BinanceAPIRequestBuilder(Exchange: Exchange, creds: credentials)
            
            let request = try? builder.createRequest()
            
            // Currently uses testnet - update this test if switching to production
            #expect(request?.url?.absoluteString.contains("testnet.binancefuture.com") == true)
        }
    }
    
    #endif
    // MARK: - Factory Tests
    
    @Suite("Request Builder Factory")
    struct RequestBuilderFactoryTests {
        
        @Test("Creates Bybit builder")
        @MainActor
        func testCreatesBybitBuilder() async {
            let credManager = MockCredentialManager()
            await credManager.setCredentials(TestFixtures.TestCredentials.bybit, forAccount: "bybit")
            
            let exchange = Exchange(.bybit, wallet: .unified)
            let builder = await APIRequestBuilderFactory.builder(for: exchange, exchangeConfiguration: RegistryHelper().getBybitRegistry().configuration(for: exchange)!, creds: credManager)
            
            #expect(builder != nil)
            #expect(builder is BybitWalletAPIRequestBuilder)
        }
        
        #if false
        @Test("Creates KuCoin builder")
        @MainActor
        func testCreatesKuCoinBuilder() async {
            let credManager = MockCredentialManager()
            await credManager.setCredentials(TestFixtures.TestCredentials.kucoin, forAccount: "kucoin")
            
            let exchange = Exchange(.kucoin, wallet: .futures)
            let builder = await APIRequestBuilderFactory.builder(for: exchange, exchangeConfiguration: RegistryHelper().getBybitRegistry().configuration(for: exchange)!, creds: credManager)
            
            #expect(builder != nil)
            #expect(builder is KuCoinAPIRequestBuilder)
        }
        
        @Test("Creates Binance builder")
        @MainActor
        func testCreatesBinanceBuilder() async {
            let credManager = MockCredentialManager()
            await credManager.setCredentials(TestFixtures.TestCredentials.binance, forAccount: "binance")
            
            let exchange = Exchange(.binance, wallet: .futures)
            let builder = await APIRequestBuilderFactory.builder(for: exchange, exchangeConfiguration: RegistryHelper().getBybitRegistry().configuration(for: exchange)!, creds: credManager)
            
            #expect(builder != nil)
            #expect(builder is BinanceAPIRequestBuilder)
        }
        
        #endif
        @Test("Returns nil when credentials not found")
        @MainActor
        func testReturnsNilForMissingCredentials() async {
            let credManager = MockCredentialManager(fallbackOnMissing: false)
            // Don't set any credentials
            
            let exchange = Exchange(.bybit, wallet: .unified)
            let builder = await APIRequestBuilderFactory.builder(for: exchange, exchangeConfiguration: RegistryHelper().getBybitRegistry().configuration(for: exchange)!, creds: credManager)
            
            #expect(builder == nil)
        }
    }
}
