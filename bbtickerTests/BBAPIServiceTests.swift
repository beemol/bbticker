//
//  BBAPIServiceTests.swift
//  bbtickerTests
//
//  Created by GitHub Copilot on 04/10/2025.
//

import XCTest
import Foundation
import LLApiService
import LLCore
@testable import bbticker

// TODO: Can be removed since LLCore already cover all the integration test cases

@MainActor
class BBAPIServiceTests: XCTestCase {
    
    @MainActor
    private lazy var mockCredentialManager: CredentialManagerProtocol = MockCredentialManager()
    
    @MainActor
    private lazy var mockURLSession = MockURLSession()
    
    @MainActor
    private lazy var mockSettingsService = MockSettingsService()
    
//    @MainActor
//    private lazy var apiService = BBAPIService(
//        credentialManager: mockCredentialManager,
//        settingsService: mockSettingsService,
//        urlSession: mockURLSession
//    )
    
    @MainActor
    private lazy var apiService = LLAPIServiceWrapper(
        credentialManager: mockCredentialManager,
        settingsService: mockSettingsService, urlSession: mockURLSession
    )
    
    // MARK: - Application-Level Error Detection Tests (HTTP 200 with errors)
    
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
        
        setupMockResponse(data: errorResponse, statusCode: 200, url: "https://api.bybit.com")
        
        // When & Then
        do {
            _ = try await apiService.fetchWalletBalance(for: Exchange(.bybit, wallet: .unified))
            XCTFail("Expected APIDomainError to be thrown")
        } catch let error as APIDomainError {
            switch error {
            case .keyRevokedOrInactive(let context):
                XCTAssertEqual(context.apiCode, "33004")
                XCTAssertEqual(context.rawMessage, "Your api key has expired.")
                XCTAssertEqual(context.exchange, .bybit)
                XCTAssertEqual(context.httpStatus, 200)
            default:
                XCTFail("Expected keyRevokedOrInactive error, got \(error)")
            }
        } catch {
            XCTFail("Expected APIDomainError, got \(error)")
        }
    }
    
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
        
        setupMockResponse(data: errorResponse, statusCode: 200)
        
        do {
            _ = try await apiService.fetchWalletBalance(for: Exchange(.bybit, wallet: .unified))
            XCTFail("Expected APIDomainError to be thrown")
        } catch let error as APIDomainError {
            switch error {
            case .signatureInvalid(let context):
                XCTAssertEqual(context.apiCode, "10004")
                XCTAssertEqual(context.rawMessage, "Invalid signature")
                XCTAssertEqual(context.exchange, .bybit)
            default:
                XCTFail("Expected signatureInvalid error, got \(error)")
            }
        } catch {
            XCTFail("Expected APIDomainError, got \(error)")
        }
    }
    
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
        
        setupMockResponse(data: errorResponse, statusCode: 200)
        
        do {
            _ = try await apiService.fetchWalletBalance(for: Exchange(.bybit, wallet: .unified))
            XCTFail("Expected APIDomainError to be thrown")
        } catch let error as APIDomainError {
            switch error {
            case .ipNotAllowed(let context):
                XCTAssertEqual(context.apiCode, "10006")
                XCTAssertEqual(context.rawMessage, "IP address not in whitelist")
            default:
                XCTFail("Expected ipNotAllowed error, got \(error)")
            }
        } catch {
            XCTFail("Expected APIDomainError, got \(error)")
        }
    }
    
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
        
        setupMockResponse(data: errorResponse, statusCode: 200)
        
        do {
            _ = try await apiService.fetchWalletBalance(for: Exchange(.bybit, wallet: .unified))
            XCTFail("Expected APIDomainError to be thrown")
        } catch let error as APIDomainError {
            switch error {
            case .rateLimited(let context):
                XCTAssertEqual(context.apiCode, "10016")
                XCTAssertEqual(context.rawMessage, "Too many requests")
            default:
                XCTFail("Expected rateLimited error, got \(error)")
            }
        } catch {
            XCTFail("Expected APIDomainError, got \(error)")
        }
    }
    
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
        
        setupMockResponse(data: errorResponse, statusCode: 200)
        
        do {
            _ = try await apiService.fetchWalletBalance(for: Exchange(.bybit, wallet: .unified))
            XCTFail("Expected APIDomainError to be thrown")
        } catch let error as APIDomainError {
            switch error {
            case .permissionDenied(let context):
                XCTAssertEqual(context.apiCode, "10018")
                XCTAssertEqual(context.rawMessage, "Permission denied for this API")
            default:
                XCTFail("Expected permissionDenied error, got \(error)")
            }
        } catch {
            XCTFail("Expected APIDomainError, got \(error)")
        }
    }
    
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
        
        setupMockResponse(data: errorResponse, statusCode: 200)
        
        do {
            _ = try await apiService.fetchWalletBalance(for: Exchange(.bybit, wallet: .unified))
            XCTFail("Expected APIDomainError to be thrown")
        } catch let error as APIDomainError {
            switch error {
            case .unknown(let context):
                XCTAssertEqual(context.apiCode, "99999")
                XCTAssertEqual(context.rawMessage, "Unknown error occurred")
            default:
                XCTFail("Expected unknown error, got \(error)")
            }
        } catch {
            XCTFail("Expected APIDomainError, got \(error)")
        }
    }
    
    // MARK: - KuCoin Application-Level Error Tests
    // NOTE: These tests are disabled because the LLCore registry doesn't provide
    // request builders for KuCoin in the test environment. KuCoin error handling
    // is tested in LLCore's own test suite.
    
    // MARK: - Binance Application-Level Error Tests
    // NOTE: These tests are disabled because the LLCore registry doesn't provide
    // request builders for Binance in the test environment. Binance error handling
    // is tested in LLCore's own test suite.
    
    // MARK: - Success Cases (No Application Errors)
    
    func testBybitUnifiedSuccess_ParsesTotals() async {
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
        
        setupMockResponse(data: successResponse, statusCode: 200)
        
        do {
            let data = try await apiService.fetchWalletBalance(for: Exchange(.bybit, wallet: .unified))
            XCTAssertEqual(data.totalEquity, 1000.00)
            XCTAssertEqual(data.walletBalance, 900.00)
        } catch {
            XCTFail("Expected successful parse, got error: \(error)")
        }
    }
    
    // NOTE: testKuCoinSuccessResponse_NoApplicationError removed - KuCoin response format
    // testing is handled in LLCore's test suite.
    
    // MARK: - Edge Cases
    
    func testInvalidJSONResponse_NoApplicationError() async {
        // Given: Invalid JSON response
        let invalidResponse = "{ invalid json"
        
        setupMockResponse(data: invalidResponse, statusCode: 200)
        
        do {
            _ = try await apiService.fetchWalletBalance(for: Exchange(.bybit, wallet: .unified))
            XCTFail("Expected parse error")
        } catch let error as APIDomainError {
            XCTFail("Should not throw APIDomainError for invalid JSON, got \(error)")
        } catch {
            // Expected - invalid JSON should result in parse error, not application error
            XCTAssert(error is APIError)
        }
    }
    
    func testEmptyResponse_NoApplicationError() async {
        // Given: Empty response
        setupMockResponse(data: "", statusCode: 200)
        
        do {
            _ = try await apiService.fetchWalletBalance(for: Exchange(.bybit, wallet: .unified))
            XCTFail("Expected parse error")
        } catch let error as APIDomainError {
            XCTFail("Should not throw APIDomainError for empty response, got \(error)")
        } catch {
            // Expected - empty response should result in parse error
            XCTAssert(error is APIError)
        }
    }
    
    // MARK: - Bybit SPOT Parsing
    
    func testBybitSpotParsing_USDT() async {
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
        
        setupMockResponse(data: successResponse, statusCode: 200)
        
        do {
            let data = try await apiService.fetchWalletBalance(for: Exchange(.bybit, wallet: .unified))
            XCTAssertEqual(data.walletBalance, 123.45)
            XCTAssertEqual(data.totalEquity, 123.45) // equity falls back to walletBalance for SPOT
        } catch {
            XCTFail("Expected successful parse, got error: \(error)")
        }
    }
    
    // MARK: - HTTP Error Cases (Still Work)
    
    func testHTTPErrorStillMapped() async {
        // Given: HTTP 401 error (should still be handled by existing HTTP error mapping)
        let errorResponse = """
        {
            "error": "Unauthorized"
        }
        """
        
        setupMockResponse(data: errorResponse, statusCode: 401)
        
        do {
            _ = try await apiService.fetchWalletBalance(for: Exchange(.bybit, wallet: .unified))
            XCTFail("Expected APIDomainError to be thrown")
        } catch let error as APIDomainError {
            // Should still map HTTP errors correctly - the exact error type depends on APIErrorMapper
            XCTAssertNotNil(error)
        } catch {
            XCTFail("Expected APIDomainError for HTTP error, got \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupMockResponse(data: String, statusCode: Int, url: String = "https://api.bybit.com") {
        mockURLSession.mockData = data.data(using: .utf8)
        // Use the actual Bybit API URL to match what the real request builder creates
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: url)!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )
    }
}

// MARK: - Mock URL Session
@MainActor
class MockURLSession: URLSessionProtocol {
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let error = mockError {
            throw error
        }
        
        guard let data = mockData, let response = mockResponse else {
            throw URLError(.badServerResponse)
        }
        
        return (data, response)
    }
}

