//
//  ErrorDetectorTests.swift
//  LLCoreTests
//
//  Tests for error detection functionality
//

import Testing
import Foundation
@testable import bbticker
import LLCore

@Suite("Error Detector Tests")
struct ErrorDetectorTests {
    
    // MARK: - Bybit Error Detector Tests
    
    @Suite("Bybit Error Detector")
    struct BybitErrorDetectorTests {
        
        @Test("Detects API key expired error")
        func testAPIKeyExpiredError() throws {
            let detector = BybitErrorDetector()
            let data = TestFixtures.Bybit.errorAPIKeyExpired.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: URL(string: "https://api.bybit.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            #expect(throws: APIDomainError.self) {
                try detector.detectError(data: data, response: response)
            }
            
            do {
                try detector.detectError(data: data, response: response)
                Issue.record("Expected error to be thrown")
            } catch let error as APIDomainError {
                guard case .keyRevokedOrInactive(let context) = error else {
                    Issue.record("Expected keyRevokedOrInactive error")
                    return
                }
                #expect(context.apiCode == "33004")
                #expect(context.rawMessage == "Your api key has expired.")
                #expect(context.httpStatus == 200)
            }
        }
        
        @Test("Detects invalid signature error")
        func testInvalidSignatureError() throws {
            let detector = BybitErrorDetector()
            let data = TestFixtures.Bybit.errorInvalidSignature.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: URL(string: "https://api.bybit.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            do {
                try detector.detectError(data: data, response: response)
                Issue.record("Expected error to be thrown")
            } catch let error as APIDomainError {
                guard case .signatureInvalid(let context) = error else {
                    Issue.record("Expected signatureInvalid error")
                    return
                }
                #expect(context.apiCode == "10004")
                #expect(context.rawMessage == "Invalid signature")
            }
        }
        
        @Test("Detects IP not allowed error")
        func testIPNotAllowedError() throws {
            let detector = BybitErrorDetector()
            let data = TestFixtures.Bybit.errorIPNotAllowed.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: URL(string: "https://api.bybit.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            do {
                try detector.detectError(data: data, response: response)
                Issue.record("Expected error to be thrown")
            } catch let error as APIDomainError {
                guard case .ipNotAllowed(let context) = error else {
                    Issue.record("Expected ipNotAllowed error")
                    return
                }
                #expect(context.apiCode == "10006")
                #expect(context.rawMessage == "IP address not in whitelist")
            }
        }
        
        @Test("Detects rate limited error")
        func testRateLimitedError() throws {
            let detector = BybitErrorDetector()
            let data = TestFixtures.Bybit.errorRateLimited.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: URL(string: "https://api.bybit.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            do {
                try detector.detectError(data: data, response: response)
                Issue.record("Expected error to be thrown")
            } catch let error as APIDomainError {
                guard case .rateLimited(let context) = error else {
                    Issue.record("Expected rateLimited error")
                    return
                }
                #expect(context.apiCode == "10016")
                #expect(context.rawMessage == "Too many requests")
            }
        }
        
        @Test("Detects permission denied error")
        func testPermissionDeniedError() throws {
            let detector = BybitErrorDetector()
            let data = TestFixtures.Bybit.errorPermissionDenied.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: URL(string: "https://api.bybit.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            do {
                try detector.detectError(data: data, response: response)
                Issue.record("Expected error to be thrown")
            } catch let error as APIDomainError {
                guard case .permissionDenied(let context) = error else {
                    Issue.record("Expected permissionDenied error")
                    return
                }
                #expect(context.apiCode == "10018")
                #expect(context.rawMessage == "Permission denied for this API")
            }
        }
        
        @Test("Detects unknown error")
        func testUnknownError() throws {
            let detector = BybitErrorDetector()
            let data = TestFixtures.Bybit.errorUnknown.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: URL(string: "https://api.bybit.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            do {
                try detector.detectError(data: data, response: response)
                Issue.record("Expected error to be thrown")
            } catch let error as APIDomainError {
                guard case .unknown(let context) = error else {
                    Issue.record("Expected unknown error")
                    return
                }
                #expect(context.apiCode == "99999")
                #expect(context.rawMessage == "Unknown error occurred")
            }
        }
        
        @Test("Does not throw on success response")
        func testSuccessResponse() throws {
            let detector = BybitErrorDetector()
            let data = TestFixtures.Bybit.successUnified.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: URL(string: "https://api.bybit.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            // Should not throw
            try detector.detectError(data: data, response: response)
        }
        
        @Test("Handles invalid JSON gracefully")
        func testInvalidJSON() throws {
            let detector = BybitErrorDetector()
            let data = TestFixtures.EdgeCases.invalidJSON.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: URL(string: "https://api.bybit.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            // Should not throw - invalid JSON is not an application error
            try detector.detectError(data: data, response: response)
        }
    }
    
    // MARK: - KuCoin Error Detector Tests
    
    @Suite("KuCoin Error Detector")
    struct KuCoinErrorDetectorTests {
        
        @Test("Detects API key not exists error")
        func testAPIKeyNotExistsError() throws {
            let detector = KucoinErrorDetector()
            let data = TestFixtures.KuCoin.errorAPIKeyNotExists.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: URL(string: "https://api.kucoin.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            do {
                try detector.detectError(data: data, response: response)
                Issue.record("Expected error to be thrown")
            } catch let error as APIDomainError {
                guard case .invalidCredentials(let context) = error else {
                    Issue.record("Expected invalidCredentials error")
                    return
                }
                #expect(context.apiCode == "400003")
                #expect(context.rawMessage == "KC-API-KEY not exists")
            }
        }
        
        @Test("Detects invalid signature error")
        func testInvalidSignatureError() throws {
            let detector = KucoinErrorDetector()
            let data = TestFixtures.KuCoin.errorInvalidSignature.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: URL(string: "https://api.kucoin.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            do {
                try detector.detectError(data: data, response: response)
                Issue.record("Expected error to be thrown")
            } catch let error as APIDomainError {
                guard case .signatureInvalid(let context) = error else {
                    Issue.record("Expected signatureInvalid error")
                    return
                }
                #expect(context.apiCode == "400005")
                #expect(context.rawMessage == "KC-API-SIGN Invalid")
            }
        }
        
        @Test("Detects permission denied error")
        func testPermissionDeniedError() throws {
            let detector = KucoinErrorDetector()
            let data = TestFixtures.KuCoin.errorPermissionDenied.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: URL(string: "https://api.kucoin.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            do {
                try detector.detectError(data: data, response: response)
                Issue.record("Expected error to be thrown")
            } catch let error as APIDomainError {
                guard case .permissionDenied(let context) = error else {
                    Issue.record("Expected permissionDenied error")
                    return
                }
                #expect(context.apiCode == "400006")
                #expect(context.rawMessage == "Permission denied")
            }
        }
        
        @Test("Detects rate limited error")
        func testRateLimitedError() throws {
            let detector = KucoinErrorDetector()
            let data = TestFixtures.KuCoin.errorRateLimited.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: URL(string: "https://api.kucoin.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            do {
                try detector.detectError(data: data, response: response)
                Issue.record("Expected error to be thrown")
            } catch let error as APIDomainError {
                guard case .rateLimited(let context) = error else {
                    Issue.record("Expected rateLimited error")
                    return
                }
                #expect(context.apiCode == "429000")
                #expect(context.rawMessage == "Too Many Requests")
            }
        }
        
        @Test("Does not throw on success response")
        func testSuccessResponse() throws {
            let detector = KucoinErrorDetector()
            let data = TestFixtures.KuCoin.successFutures.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: URL(string: "https://api.kucoin.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            // Should not throw
            try detector.detectError(data: data, response: response)
        }
    }
    
    // MARK: - Binance Error Detector Tests
    
    @Suite("Binance Error Detector")
    struct BinanceErrorDetectorTests {
        
        @Test("Detects invalid API key error")
        func testInvalidAPIKeyError() throws {
            let detector = BinanceErrorDetector()
            let data = TestFixtures.Binance.errorInvalidAPIKey.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: URL(string: "https://fapi.binance.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            do {
                try detector.detectError(data: data, response: response)
                Issue.record("Expected error to be thrown")
            } catch let error as APIDomainError {
                guard case .invalidCredentials(let context) = error else {
                    Issue.record("Expected invalidCredentials error")
                    return
                }
                #expect(context.apiCode == "-2014")
                #expect(context.rawMessage == "API-key format invalid.")
            }
        }
        
        @Test("Detects invalid signature error")
        func testInvalidSignatureError() throws {
            let detector = BinanceErrorDetector()
            let data = TestFixtures.Binance.errorInvalidSignature.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: URL(string: "https://fapi.binance.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            do {
                try detector.detectError(data: data, response: response)
                Issue.record("Expected error to be thrown")
            } catch let error as APIDomainError {
                guard case .signatureInvalid(let context) = error else {
                    Issue.record("Expected signatureInvalid error")
                    return
                }
                #expect(context.apiCode == "-1022")
                #expect(context.rawMessage == "Signature for this request is not valid.")
            }
        }
        
        @Test("Detects timestamp error")
        func testTimestampError() throws {
            let detector = BinanceErrorDetector()
            let data = TestFixtures.Binance.errorTimestamp.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: URL(string: "https://fapi.binance.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            do {
                try detector.detectError(data: data, response: response)
                Issue.record("Expected error to be thrown")
            } catch let error as APIDomainError {
                guard case .timestampOutOfRange(let context) = error else {
                    Issue.record("Expected timestampOutOfRange error")
                    return
                }
                #expect(context.apiCode == "-1021")
                #expect(context.rawMessage == "Timestamp for this request is outside of the recvWindow.")
            }
        }
        
        @Test("Detects rate limited error")
        func testRateLimitedError() throws {
            let detector = BinanceErrorDetector()
            let data = TestFixtures.Binance.errorRateLimited.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: URL(string: "https://fapi.binance.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            do {
                try detector.detectError(data: data, response: response)
                Issue.record("Expected error to be thrown")
            } catch let error as APIDomainError {
                guard case .rateLimited(let context) = error else {
                    Issue.record("Expected rateLimited error")
                    return
                }
                #expect(context.apiCode == "-1003")
                #expect(context.rawMessage == "Too much request weight used")
            }
        }
        
        @Test("Does not throw on success response")
        func testSuccessResponse() throws {
            let detector = BinanceErrorDetector()
            let data = TestFixtures.Binance.successFutures.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: URL(string: "https://fapi.binance.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            // Should not throw
            try detector.detectError(data: data, response: response)
        }
    }
    
    // MARK: - HTTP Status Error Detector Tests
    
    @Suite("HTTP Status Error Detector")
    struct HTTPStatusErrorDetectorTests {
        
        @Test("Detects HTTP 401 error")
        func testHTTP401Error() throws {
            let appDetector = BybitErrorDetector()
            let detector = HTTPStatusErrorDetector(
                exchange: .bybit,
                endpoint: "/v5/account/wallet-balance",
                appLevelDetector: appDetector
            )
            
            let data = "{}".data(using: .utf8)!
            let response = HTTPURLResponse(
                url: URL(string: "https://api.bybit.com")!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            
            #expect(throws: APIDomainError.self) {
                try detector.detectError(data: data, response: response)
            }
        }
        
        @Test("Detects HTTP 403 error")
        func testHTTP403Error() throws {
            let appDetector = BybitErrorDetector()
            let detector = HTTPStatusErrorDetector(
                exchange: .bybit,
                endpoint: "/v5/account/wallet-balance",
                appLevelDetector: appDetector
            )
            
            let data = "{}".data(using: .utf8)!
            let response = HTTPURLResponse(
                url: URL(string: "https://api.bybit.com")!,
                statusCode: 403,
                httpVersion: nil,
                headerFields: nil
            )!
            
            #expect(throws: APIDomainError.self) {
                try detector.detectError(data: data, response: response)
            }
        }
        
        @Test("Detects HTTP 429 rate limit")
        func testHTTP429RateLimit() throws {
            let appDetector = BybitErrorDetector()
            let detector = HTTPStatusErrorDetector(
                exchange: .bybit,
                endpoint: "/v5/account/wallet-balance",
                appLevelDetector: appDetector
            )
            
            let data = "{}".data(using: .utf8)!
            let response = HTTPURLResponse(
                url: URL(string: "https://api.bybit.com")!,
                statusCode: 429,
                httpVersion: nil,
                headerFields: nil
            )!
            
            do {
                try detector.detectError(data: data, response: response)
                Issue.record("Expected error to be thrown")
            } catch let error as APIDomainError {
                guard case .rateLimited = error else {
                    Issue.record("Expected rateLimited error")
                    return
                }
            }
        }
        
        @Test("Detects HTTP 500 server error")
        func testHTTP500ServerError() throws {
            let appDetector = BybitErrorDetector()
            let detector = HTTPStatusErrorDetector(
                exchange: .bybit,
                endpoint: "/v5/account/wallet-balance",
                appLevelDetector: appDetector
            )
            
            let data = "{}".data(using: .utf8)!
            let response = HTTPURLResponse(
                url: URL(string: "https://api.bybit.com")!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            
            do {
                try detector.detectError(data: data, response: response)
                Issue.record("Expected error to be thrown")
            } catch let error as APIDomainError {
                guard case .server = error else {
                    Issue.record("Expected server error")
                    return
                }
            }
        }
        
        @Test("Delegates to app-level detector for HTTP 200")
        func testDelegatesToAppLevelDetector() throws {
            let appDetector = BybitErrorDetector()
            let detector = HTTPStatusErrorDetector(
                exchange: .bybit,
                endpoint: "/v5/account/wallet-balance",
                appLevelDetector: appDetector
            )
            
            let data = TestFixtures.Bybit.errorAPIKeyExpired.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: URL(string: "https://api.bybit.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            do {
                try detector.detectError(data: data, response: response)
                Issue.record("Expected error to be thrown")
            } catch let error as APIDomainError {
                guard case .keyRevokedOrInactive = error else {
                    Issue.record("Expected keyRevokedOrInactive error from app-level detector")
                    return
                }
            }
        }
        
        @Test("Does not throw on HTTP 200 with valid response")
        func testSuccessResponse() throws {
            let appDetector = BybitErrorDetector()
            let detector = HTTPStatusErrorDetector(
                exchange: .bybit,
                endpoint: "/v5/account/wallet-balance",
                appLevelDetector: appDetector
            )
            
            let data = TestFixtures.Bybit.successUnified.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: URL(string: "https://api.bybit.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            // Should not throw
            try detector.detectError(data: data, response: response)
        }
    }
}
