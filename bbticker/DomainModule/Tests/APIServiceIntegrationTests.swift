//
//  APIServiceIntegrationTests.swift
//  LLCoreTests
//
//  Integration tests for LLApiService with LLCore components
//  Converted from XCTest to modern Swift Testing framework
//

import Testing
import Foundation
import LLApiService
import LLCore
@testable import bbticker

@Suite("API Service Integration Tests")
@MainActor
struct APIServiceIntegrationTests {
    
    // MARK: - Test Infrastructure
    
    let mockCredentialManager: MockCredentialManager
    let mockURLSession: MockedURLSession
    let mockSettingsService: MockSettingsService
    let apiService: TestAPIServiceWrapper
    
    init() async {
        mockCredentialManager = MockCredentialManager()
        mockURLSession = MockedURLSession()
        mockSettingsService = MockSettingsService()
        
        // Setup default credentials for all exchanges
        await mockCredentialManager.setCredentials(
            TestFixtures.TestCredentials.bybit,
            forAccount: "bybit"
        )
        await mockCredentialManager.setCredentials(
            TestFixtures.TestCredentials.kucoin,
            forAccount: "kucoin"
        )
        await mockCredentialManager.setCredentials(
            TestFixtures.TestCredentials.binance,
            forAccount: "binance"
        )
        
        // Initialize wrapper with mocks
        apiService = TestAPIServiceWrapper(
            urlSession: mockURLSession,
            credentialManager: mockCredentialManager
        )
    }
    
    // MARK: - Application-Level Error Detection Tests (HTTP 200 with errors)
    
    @Test("Bybit API key expired error")
    func testBybitAPIKeyExpiredError() async {
        // Given: Bybit returns HTTP 200 with API key expired error
        let errorResponse = """
        {
            "retCode": 33004,
            "retMsg": "Your api key has expired.",
            "result": {},
            "retExtInfo": {},
            "time": 1759564016973
        }
        """
        
        await setupMockResponse(data: errorResponse, statusCode: 200, url: "https://api.bybit.com")
        
        // When & Then
        do {
            _ = try await apiService.fetchWalletBalance(for: Exchange(.bybit, wallet: .unified))
            Issue.record("Expected APIDomainError to be thrown")
        } catch let error as APIDomainError {
            guard case .keyRevokedOrInactive(let context) = error else {
                Issue.record("Expected keyRevokedOrInactive error, got \(error)")
                return
            }
            #expect(context.apiCode == "33004")
            #expect(context.rawMessage == "Your api key has expired.")
            #expect(context.exchange == .bybit)
            #expect(context.httpStatus == 200)
        } catch {
            Issue.record("Expected APIDomainError, got \(error)")
        }
    }
    
    @Test("Bybit invalid signature error")
    func testBybitInvalidSignatureError() async {
        // Given: Bybit returns HTTP 200 with signature error
        let errorResponse = """
        {
            "retCode": 10004,
            "retMsg": "Invalid signature",
            "result": {},
            "retExtInfo": {},
            "time": 1759564016973
        }
        """
        
        await setupMockResponse(data: errorResponse, statusCode: 200)
        
        do {
            _ = try await apiService.fetchWalletBalance(for: Exchange(.bybit, wallet: .unified))
            Issue.record("Expected APIDomainError to be thrown")
        } catch let error as APIDomainError {
            guard case .signatureInvalid(let context) = error else {
                Issue.record("Expected signatureInvalid error, got \(error)")
                return
            }
            #expect(context.apiCode == "10004")
            #expect(context.rawMessage == "Invalid signature")
            #expect(context.exchange == .bybit)
        } catch {
            Issue.record("Expected APIDomainError, got \(error)")
        }
    }
    
    @Test("Bybit IP not allowed error")
    func testBybitIPNotAllowedError() async {
        // Given: Bybit returns HTTP 200 with IP whitelist error
        let errorResponse = """
        {
            "retCode": 10006,
            "retMsg": "IP address not in whitelist",
            "result": {},
            "retExtInfo": {},
            "time": 1759564016973
        }
        """
        
        await setupMockResponse(data: errorResponse, statusCode: 200)
        
        do {
            _ = try await apiService.fetchWalletBalance(for: Exchange(.bybit, wallet: .unified))
            Issue.record("Expected APIDomainError to be thrown")
        } catch let error as APIDomainError {
            guard case .ipNotAllowed(let context) = error else {
                Issue.record("Expected ipNotAllowed error, got \(error)")
                return
            }
            #expect(context.apiCode == "10006")
            #expect(context.rawMessage == "IP address not in whitelist")
        } catch {
            Issue.record("Expected APIDomainError, got \(error)")
        }
    }
    
    @Test("Bybit rate limited error")
    func testBybitRateLimitedError() async {
        // Given: Bybit returns HTTP 200 with rate limit error
        let errorResponse = """
        {
            "retCode": 10016,
            "retMsg": "Too many requests",
            "result": {},
            "retExtInfo": {},
            "time": 1759564016973
        }
        """
        
        await setupMockResponse(data: errorResponse, statusCode: 200)
        
        do {
            _ = try await apiService.fetchWalletBalance(for: Exchange(.bybit, wallet: .unified))
            Issue.record("Expected APIDomainError to be thrown")
        } catch let error as APIDomainError {
            guard case .rateLimited(let context) = error else {
                Issue.record("Expected rateLimited error, got \(error)")
                return
            }
            #expect(context.apiCode == "10016")
            #expect(context.rawMessage == "Too many requests")
        } catch {
            Issue.record("Expected APIDomainError, got \(error)")
        }
    }
    
    @Test("Bybit permission denied error")
    func testBybitPermissionDeniedError() async {
        // Given: Bybit returns HTTP 200 with permission error
        let errorResponse = """
        {
            "retCode": 10018,
            "retMsg": "Permission denied for this API",
            "result": {},
            "retExtInfo": {},
            "time": 1759564016973
        }
        """
        
        await setupMockResponse(data: errorResponse, statusCode: 200)
        
        do {
            _ = try await apiService.fetchWalletBalance(for: Exchange(.bybit, wallet: .unified))
            Issue.record("Expected APIDomainError to be thrown")
        } catch let error as APIDomainError {
            guard case .permissionDenied(let context) = error else {
                Issue.record("Expected permissionDenied error, got \(error)")
                return
            }
            #expect(context.apiCode == "10018")
            #expect(context.rawMessage == "Permission denied for this API")
        } catch {
            Issue.record("Expected APIDomainError, got \(error)")
        }
    }
    
    @Test("Bybit unknown error")
    func testBybitUnknownError() async {
        // Given: Bybit returns HTTP 200 with unknown error code
        let errorResponse = """
        {
            "retCode": 99999,
            "retMsg": "Unknown error occurred",
            "result": {},
            "retExtInfo": {},
            "time": 1759564016973
        }
        """
        
        await setupMockResponse(data: errorResponse, statusCode: 200)
        
        do {
            _ = try await apiService.fetchWalletBalance(for: Exchange(.bybit, wallet: .unified))
            Issue.record("Expected APIDomainError to be thrown")
        } catch let error as APIDomainError {
            guard case .unknown(let context) = error else {
                Issue.record("Expected unknown error, got \(error)")
                return
            }
            #expect(context.apiCode == "99999")
            #expect(context.rawMessage == "Unknown error occurred")
        } catch {
            Issue.record("Expected APIDomainError, got \(error)")
        }
    }
    
    // MARK: - KuCoin Application-Level Error Tests
    
    @Test("KuCoin API key not exists error")
    func testKuCoinAPIKeyNotExistsError() async {
        // Given: KuCoin returns HTTP 200 with API key error
        let errorResponse = """
        {
            "code": "400003",
            "msg": "KC-API-KEY not exists"
        }
        """
        
        await setupMockResponse(data: errorResponse, statusCode: 200)
        
        do {
            _ = try await apiService.fetchWalletBalance(for: Exchange(.kucoin, wallet: .futures))
            Issue.record("Expected APIDomainError to be thrown")
        } catch let error as APIDomainError {
            guard case .invalidCredentials(let context) = error else {
                Issue.record("Expected invalidCredentials error, got \(error)")
                return
            }
            #expect(context.apiCode == "400003")
            #expect(context.rawMessage == "KC-API-KEY not exists")
            #expect(context.exchange == .kucoin)
        } catch {
            Issue.record("Expected APIDomainError, got \(error)")
        }
    }
    
    @Test("KuCoin invalid signature error")
    func testKuCoinInvalidSignatureError() async {
        // Given: KuCoin returns HTTP 200 with signature error
        let errorResponse = """
        {
            "code": "400005",
            "msg": "KC-API-SIGN Invalid"
        }
        """
        
        await setupMockResponse(data: errorResponse, statusCode: 200)
        
        do {
            _ = try await apiService.fetchWalletBalance(for: Exchange(.kucoin, wallet: .futures))
            Issue.record("Expected APIDomainError to be thrown")
        } catch let error as APIDomainError {
            guard case .signatureInvalid(let context) = error else {
                Issue.record("Expected signatureInvalid error, got \(error)")
                return
            }
            #expect(context.apiCode == "400005")
            #expect(context.rawMessage == "KC-API-SIGN Invalid")
        } catch {
            Issue.record("Expected APIDomainError, got \(error)")
        }
    }
    
    @Test("KuCoin rate limited error")
    func testKuCoinRateLimitedError() async {
        // Given: KuCoin returns HTTP 200 with rate limit error
        let errorResponse = """
        {
            "code": "429000",
            "msg": "Too Many Requests"
        }
        """
        
        await setupMockResponse(data: errorResponse, statusCode: 200)
        
        do {
            _ = try await apiService.fetchWalletBalance(for: Exchange(.kucoin, wallet: .futures))
            Issue.record("Expected APIDomainError to be thrown")
        } catch let error as APIDomainError {
            guard case .rateLimited(let context) = error else {
                Issue.record("Expected rateLimited error, got \(error)")
                return
            }
            #expect(context.apiCode == "429000")
            #expect(context.rawMessage == "Too Many Requests")
        } catch {
            Issue.record("Expected APIDomainError, got \(error)")
        }
    }
    
    // MARK: - Binance Application-Level Error Tests
    
    @Test("Binance invalid API key error")
    func testBinanceInvalidAPIKeyError() async {
        // Given: Binance returns HTTP 200 with API key error
        let errorResponse = """
        {
            "code": -2014,
            "msg": "API-key format invalid."
        }
        """
        
        await setupMockResponse(data: errorResponse, statusCode: 200)
        
        do {
            _ = try await apiService.fetchWalletBalance(for: Exchange(.binance, wallet: .futures))
            Issue.record("Expected APIDomainError to be thrown")
        } catch let error as APIDomainError {
            guard case .invalidCredentials(let context) = error else {
                Issue.record("Expected invalidCredentials error, got \(error)")
                return
            }
            #expect(context.apiCode == "-2014")
            #expect(context.rawMessage == "API-key format invalid.")
            #expect(context.exchange == .binance)
        } catch {
            Issue.record("Expected APIDomainError, got \(error)")
        }
    }
    
    @Test("Binance invalid signature error")
    func testBinanceInvalidSignatureError() async {
        // Given: Binance returns HTTP 200 with signature error
        let errorResponse = """
        {
            "code": -1022,
            "msg": "Signature for this request is not valid."
        }
        """
        
        await setupMockResponse(data: errorResponse, statusCode: 200)
        
        do {
            _ = try await apiService.fetchWalletBalance(for: Exchange(.binance, wallet: .futures))
            Issue.record("Expected APIDomainError to be thrown")
        } catch let error as APIDomainError {
            guard case .signatureInvalid(let context) = error else {
                Issue.record("Expected signatureInvalid error, got \(error)")
                return
            }
            #expect(context.apiCode == "-1022")
            #expect(context.rawMessage == "Signature for this request is not valid.")
        } catch {
            Issue.record("Expected APIDomainError, got \(error)")
        }
    }
    
    @Test("Binance timestamp error")
    func testBinanceTimestampError() async {
        // Given: Binance returns HTTP 200 with timestamp error
        let errorResponse = """
        {
            "code": -1021,
            "msg": "Timestamp for this request is outside of the recvWindow."
        }
        """
        
        await setupMockResponse(data: errorResponse, statusCode: 200)
        
        do {
            _ = try await apiService.fetchWalletBalance(for: Exchange(.binance, wallet: .futures))
            Issue.record("Expected APIDomainError to be thrown")
        } catch let error as APIDomainError {
            guard case .timestampOutOfRange(let context) = error else {
                Issue.record("Expected timestampOutOfRange error, got \(error)")
                return
            }
            #expect(context.apiCode == "-1021")
            #expect(context.rawMessage == "Timestamp for this request is outside of the recvWindow.")
        } catch {
            Issue.record("Expected APIDomainError, got \(error)")
        }
    }
    
    // MARK: - Success Cases (No Application Errors)
    
    @Test("Bybit unified success parses totals")
    func testBybitUnifiedSuccessParsesTotals() async {
        // Given: Bybit unified-style totals in result
        let successResponse = """
        {
            "retCode": 0,
            "retMsg": "OK",
            "result": {
                "totalEquity": "1000.00",
                "totalWalletBalance": "900.00"
            },
            "retExtInfo": {},
            "time": 1759564016973
        }
        """
        
        await setupMockResponse(data: successResponse, statusCode: 200)
        
        do {
            let data = try await apiService.fetchWalletBalance(for: Exchange(.bybit, wallet: .unified))
            #expect(data.totalEquity == 1000.00)
            #expect(data.walletBalance == 900.00)
        } catch {
            Issue.record("Expected successful parse, got error: \(error)")
        }
    }
    
    @Test("KuCoin success response no application error")
    func testKuCoinSuccessResponseNoApplicationError() async {
        // Given: KuCoin returns HTTP 200 with success (code = "200000")
        let successResponse = """
        {
            "code": "200000",
            "data": [
                {
                    "currency": "USDT",
                    "balance": "1000.00",
                    "available": "1000.00"
                }
            ]
        }
        """
        
        await setupMockResponse(data: successResponse, statusCode: 200)
        
        do {
            _ = try await apiService.fetchWalletBalance(for: Exchange(.kucoin, wallet: .unified))
        } catch let error as APIDomainError {
            Issue.record("Should not throw APIDomainError for successful response, got \(error)")
        } catch {
            // Expected parse error - this is fine, we just want to ensure no APIDomainError
            #expect(error is APIError)
        }
    }
    
    // MARK: - Edge Cases
    
    @Test("Invalid JSON response no application error")
    func testInvalidJSONResponseNoApplicationError() async {
        // Given: Invalid JSON response
        let invalidResponse = "{ invalid json"
        
        await setupMockResponse(data: invalidResponse, statusCode: 200)
        
        do {
            _ = try await apiService.fetchWalletBalance(for: Exchange(.bybit, wallet: .unified))
            Issue.record("Expected parse error")
        } catch let error as APIDomainError {
            Issue.record("Should not throw APIDomainError for invalid JSON, got \(error)")
        } catch {
            // Expected - invalid JSON should result in parse error, not application error
            #expect(error is APIError)
        }
    }
    
    @Test("Empty response no application error")
    func testEmptyResponseNoApplicationError() async {
        // Given: Empty response
        await setupMockResponse(data: "", statusCode: 200)
        
        do {
            _ = try await apiService.fetchWalletBalance(for: Exchange(.bybit, wallet: .unified))
            Issue.record("Expected parse error")
        } catch let error as APIDomainError {
            Issue.record("Should not throw APIDomainError for empty response, got \(error)")
        } catch {
            // Expected - empty response should result in parse error
            #expect(error is APIError)
        }
    }
    
    // MARK: - Bybit SPOT Parsing
    
    @Test("Bybit spot parsing USDT")
    func testBybitSpotParsingUSDT() async {
        // Given: Bybit returns HTTP 200 with SPOT account list and USDT coin walletBalance
        let successResponse = """
        {
            "retCode": 0,
            "retMsg": "OK",
            "result": {
                "list": [
                    {
                        "accountType": "SPOT",
                        "coin": [
                            {"coin": "BTC", "walletBalance": "0.0000"},
                            {"coin": "USDT", "walletBalance": "123.45"}
                        ]
                    }
                ]
            },
            "retExtInfo": {},
            "time": 1759564016973
        }
        """
        
        await setupMockResponse(data: successResponse, statusCode: 200)
        
        do {
            let data = try await apiService.fetchWalletBalance(for: Exchange(.bybit, wallet: .unified))
            #expect(data.walletBalance == 123.45)
            #expect(data.totalEquity == 123.45) // equity falls back to walletBalance for SPOT
        } catch {
            Issue.record("Expected successful parse, got error: \(error)")
        }
    }
    
    // MARK: - HTTP Error Cases (Still Work)
    
    @Test("HTTP error still mapped")
    func testHTTPErrorStillMapped() async {
        // Given: HTTP 401 error (should still be handled by existing HTTP error mapping)
        let errorResponse = """
        {
            "error": "Unauthorized"
        }
        """
        
        await setupMockResponse(data: errorResponse, statusCode: 401)
        
        do {
            _ = try await apiService.fetchWalletBalance(for: Exchange(.bybit, wallet: .unified))
            Issue.record("Expected APIDomainError to be thrown")
        } catch is APIDomainError {
            // Should still map HTTP errors correctly - the exact error type depends on APIErrorMapper
            // Test passes if we catch an APIDomainError
        } catch {
            Issue.record("Expected APIDomainError for HTTP error, got \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupMockResponse(data: String, statusCode: Int, url: String = "https://api.test.com") async {
        await mockURLSession.setupResponse(data: data, statusCode: statusCode, url: url)
    }
}

// MARK: - Test API Service Wrapper

@MainActor
class TestAPIServiceWrapper {
    private let urlSession: MockedURLSession
    private let credentialManager: MockCredentialManager
    
    init(urlSession: MockedURLSession, credentialManager: MockCredentialManager) {
        self.urlSession = urlSession
        self.credentialManager = credentialManager
    }
    
    func fetchWalletBalance(for exchangeType: any ExchangeType) async throws -> WalletData {
        // Build request
        guard let requestBuilder = await APIRequestBuilderFactory.builder(
            for: exchangeType,
            creds: credentialManager
        ) else {
            throw APIError.invalidRequest
        }
        
        guard let request = try? requestBuilder.createRequest() else {
            throw APIError.invalidRequest
        }
        
        // Execute request
        let (data, response) = try await urlSession.data(for: request)
        
        // Detect errors
        let appDetector = AplicationErrorDetectorFactory.build(for: exchangeType.identifier)
        let errorDetector = HTTPStatusErrorDetector(
            exchange: exchangeType.identifier,
            endpoint: exchangeType.endpoint,
            appLevelDetector: appDetector
        )
        
        try errorDetector.detectError(data: data, response: response)
        
        // Parse response
        let parser = WalletDataParserFactory.parser(for: exchangeType)
        return try parser.parse(data: data)
    }
}
