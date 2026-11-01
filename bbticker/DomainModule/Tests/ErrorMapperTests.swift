//
//  ErrorMapperTests.swift
//  LLCoreTests
//
//  Tests for error mapping functionality
//

import Testing
import Foundation
@testable import bbticker
@testable import LLCore

@Suite("Error Mapper Tests")
struct ErrorMapperTests {
    
    // MARK: - HTTP Response Mapping Tests
    
    @Suite("HTTP Response Mapping")
    struct HTTPResponseMappingTests {
        
        @Test("Maps HTTP 401 to invalidCredentials")
        func testMapsHTTP401() {
            let data = "{}".data(using: .utf8)!
            let response = HTTPURLResponse(
                url: URL(string: "https://api.bybit.com")!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            
            let error = APIErrorMapper.mapHTTPResponse(
                exchange: .bybit,
                endpoint: "/test",
                data: data,
                response: response
            )
            
            #expect(error != nil)
            guard case .invalidCredentials(let context) = error else {
                Issue.record("Expected invalidCredentials error")
                return
            }
            #expect(context.httpStatus == 401)
        }
        
        @Test("Maps HTTP 403 to permissionDenied")
        func testMapsHTTP403() {
            let data = "{}".data(using: .utf8)!
            let response = HTTPURLResponse(
                url: URL(string: "https://api.bybit.com")!,
                statusCode: 403,
                httpVersion: nil,
                headerFields: nil
            )!
            
            let error = APIErrorMapper.mapHTTPResponse(
                exchange: .bybit,
                endpoint: "/test",
                data: data,
                response: response
            )
            
            #expect(error != nil)
            guard case .permissionDenied(let context) = error else {
                Issue.record("Expected permissionDenied error")
                return
            }
            #expect(context.httpStatus == 403)
        }
        
        @Test("Maps HTTP 429 to rateLimited")
        func testMapsHTTP429() {
            let data = "{}".data(using: .utf8)!
            let response = HTTPURLResponse(
                url: URL(string: "https://api.bybit.com")!,
                statusCode: 429,
                httpVersion: nil,
                headerFields: nil
            )!
            
            let error = APIErrorMapper.mapHTTPResponse(
                exchange: .bybit,
                endpoint: "/test",
                data: data,
                response: response
            )
            
            #expect(error != nil)
            guard case .rateLimited(let context) = error else {
                Issue.record("Expected rateLimited error")
                return
            }
            #expect(context.httpStatus == 429)
        }
        
        @Test("Maps HTTP 500 to server error")
        func testMapsHTTP500() {
            let data = "{}".data(using: .utf8)!
            let response = HTTPURLResponse(
                url: URL(string: "https://api.bybit.com")!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            
            let error = APIErrorMapper.mapHTTPResponse(
                exchange: .bybit,
                endpoint: "/test",
                data: data,
                response: response
            )
            
            #expect(error != nil)
            guard case .server(let context) = error else {
                Issue.record("Expected server error")
                return
            }
            #expect(context.httpStatus == 500)
        }
        
        @Test("Maps HTTP 503 with maintenance message to maintenance")
        func testMapsHTTP503Maintenance() {
            let data = """
            {
                "message": "System under maintenance"
            }
            """.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: URL(string: "https://api.bybit.com")!,
                statusCode: 503,
                httpVersion: nil,
                headerFields: nil
            )!
            
            let error = APIErrorMapper.mapHTTPResponse(
                exchange: .bybit,
                endpoint: "/test",
                data: data,
                response: response
            )
            
            #expect(error != nil)
            guard case .maintenance(let context) = error else {
                Issue.record("Expected maintenance error")
                return
            }
            #expect(context.httpStatus == 503)
            #expect(context.rawMessage?.lowercased().contains("maintenance") == true)
        }
        
        @Test("Returns nil for HTTP 200")
        func testReturnsNilForHTTP200() {
            let data = "{}".data(using: .utf8)!
            let response = HTTPURLResponse(
                url: URL(string: "https://api.bybit.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            let error = APIErrorMapper.mapHTTPResponse(
                exchange: .bybit,
                endpoint: "/test",
                data: data,
                response: response
            )
            
            #expect(error == nil)
        }
        
        @Test("Maps unknown HTTP status to unknown error")
        func testMapsUnknownStatus() {
            let data = "{}".data(using: .utf8)!
            let response = HTTPURLResponse(
                url: URL(string: "https://api.bybit.com")!,
                statusCode: 418, // I'm a teapot
                httpVersion: nil,
                headerFields: nil
            )!
            
            let error = APIErrorMapper.mapHTTPResponse(
                exchange: .bybit,
                endpoint: "/test",
                data: data,
                response: response
            )
            
            #expect(error != nil)
            guard case .unknown(let context) = error else {
                Issue.record("Expected unknown error")
                return
            }
            #expect(context.httpStatus == 418)
        }
    }
    
    // MARK: - Network Error Mapping Tests
    
    @Suite("Network Error Mapping")
    struct NetworkErrorMappingTests {
        
        @Test("Maps network error")
        func testMapsNetworkError() {
            let networkError = URLError(.notConnectedToInternet)
            
            let error = APIErrorMapper.mapNetworkError(
                networkError,
                exchange: .bybit,
                endpoint: "/test"
            )
            
            guard case .network(let context) = error else {
                Issue.record("Expected network error")
                return
            }
            #expect(context.httpStatus == nil)
            #expect(context.endpoint == "/test")
            #expect(context.rawMessage != nil)
        }
        
        @Test("Includes error description in context")
        func testIncludesErrorDescription() {
            let networkError = URLError(.timedOut)
            
            let error = APIErrorMapper.mapNetworkError(
                networkError,
                exchange: .bybit,
                endpoint: "/test"
            )
            
            guard case .network(let context) = error else {
                Issue.record("Expected network error")
                return
            }
            #expect(context.rawMessage?.isEmpty == false)
        }
    }
    
    // MARK: - Error Body Parsing Tests
    
    @Suite("Error Body Parsing")
    struct ErrorBodyParsingTests {
        
        @Test("Parses Bybit error body")
        func testParsesBybitErrorBody() {
            let data = """
            {
                "retCode": 10004,
                "retMsg": "Invalid signature",
                "req_id": "test-request-id"
            }
            """.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: URL(string: "https://api.bybit.com")!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            
            let error = APIErrorMapper.mapHTTPResponse(
                exchange: .bybit,
                endpoint: "/test",
                data: data,
                response: response
            )
            
            #expect(error != nil)
            let context = error?.context
            #expect(context?.apiCode == "10004")
            #expect(context?.rawMessage == "Invalid signature")
        }
        
        @Test("Parses KuCoin error body")
        func testParsesKuCoinErrorBody() {
            let data = """
            {
                "code": "400005",
                "msg": "KC-API-SIGN Invalid",
                "requestId": "test-request-id"
            }
            """.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: URL(string: "https://api.kucoin.com")!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            
            let error = APIErrorMapper.mapHTTPResponse(
                exchange: .kucoin,
                endpoint: "/test",
                data: data,
                response: response
            )
            
            #expect(error != nil)
            let context = error?.context
            #expect(context?.apiCode == "400005")
            #expect(context?.rawMessage == "KC-API-SIGN Invalid")
            #expect(context?.requestId == "test-request-id")
        }
        
        @Test("Parses Binance error body with integer code")
        func testParsesBinanceErrorBodyWithIntCode() {
            let data = """
            {
                "code": -1022,
                "msg": "Signature for this request is not valid."
            }
            """.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: URL(string: "https://fapi.binance.com")!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            
            let error = APIErrorMapper.mapHTTPResponse(
                exchange: .binance,
                endpoint: "/test",
                data: data,
                response: response
            )
            
            #expect(error != nil)
            let context = error?.context
            #expect(context?.apiCode == "-1022")
            #expect(context?.rawMessage == "Signature for this request is not valid.")
        }
        
        @Test("Handles invalid JSON in error body")
        func testHandlesInvalidJSON() {
            let data = "{ invalid json".data(using: .utf8)!
            let response = HTTPURLResponse(
                url: URL(string: "https://api.bybit.com")!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            
            let error = APIErrorMapper.mapHTTPResponse(
                exchange: .bybit,
                endpoint: "/test",
                data: data,
                response: response
            )
            
            #expect(error != nil)
            // Should still return an error even with invalid JSON
            guard case .server = error else {
                Issue.record("Expected server error")
                return
            }
        }
    }
    
    // MARK: - Exchange-Specific Registry Tests
    
    @Suite("Exchange API Error Registry")
    struct ExchangeAPIErrorRegistryTests {
        
        @Test("Maps Binance signature error")
        func testMapsBinanceSignatureError() {
            let error = ExchangeAPIErrorRegistry.map(
                exchange: .binance,
                httpStatus: 401,
                code: "-1022",
                message: "Signature invalid",
                endpoint: "/test"
            )
            
            #expect(error != nil)
            guard case .signatureInvalid = error else {
                Issue.record("Expected signatureInvalid error")
                return
            }
        }
        
        @Test("Maps Binance timestamp error")
        func testMapsBinanceTimestampError() {
            let error = ExchangeAPIErrorRegistry.map(
                exchange: .binance,
                httpStatus: 401,
                code: "-1021",
                message: "Timestamp out of range",
                endpoint: "/test"
            )
            
            #expect(error != nil)
            guard case .timestampOutOfRange = error else {
                Issue.record("Expected timestampOutOfRange error")
                return
            }
        }
        
        @Test("Maps Bybit IP not allowed error")
        func testMapsBybitIPNotAllowedError() {
            let error = ExchangeAPIErrorRegistry.map(
                exchange: .bybit,
                httpStatus: 403,
                code: "10018",
                message: "IP not allowed",
                endpoint: "/test"
            )
            
            #expect(error != nil)
            guard case .ipNotAllowed = error else {
                Issue.record("Expected ipNotAllowed error")
                return
            }
        }
        
        @Test("Maps KuCoin invalid credentials error")
        func testMapsKuCoinInvalidCredentialsError() {
            let error = ExchangeAPIErrorRegistry.map(
                exchange: .kucoin,
                httpStatus: 401,
                code: "401001",
                message: "Invalid credentials",
                endpoint: "/test"
            )
            
            #expect(error != nil)
            guard case .invalidCredentials = error else {
                Issue.record("Expected invalidCredentials error")
                return
            }
        }
        
        @Test("Returns nil for unknown error codes")
        func testReturnsNilForUnknownCodes() {
            let error = ExchangeAPIErrorRegistry.map(
                exchange: .bybit,
                httpStatus: 400,
                code: "99999",
                message: "Unknown error",
                endpoint: "/test"
            )
            
            #expect(error == nil)
        }
        
        @Test("Handles nil error code")
        func testHandlesNilErrorCode() {
            let error = ExchangeAPIErrorRegistry.map(
                exchange: .bybit,
                httpStatus: 400,
                code: nil,
                message: "Some error",
                endpoint: "/test"
            )
            
            #expect(error == nil)
        }
    }
    
    // MARK: - Context Tests
    
    @Suite("Error Context")
    struct ErrorContextTests {
        
        @Test("Context includes all fields")
        func testContextIncludesAllFields() {
            let data = """
            {
                "retCode": 10004,
                "retMsg": "Invalid signature",
                "req_id": "test-request-id"
            }
            """.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: URL(string: "https://api.bybit.com/test")!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            
            let error = APIErrorMapper.mapHTTPResponse(
                exchange: .bybit,
                endpoint: "/test",
                data: data,
                response: response
            )
            
            #expect(error != nil)
            let context = error?.context
            #expect(context?.exchange == .bybit)
            #expect(context?.httpStatus == 401)
            #expect(context?.apiCode == "10004")
            #expect(context?.endpoint == "/test")
            #expect(context?.rawMessage == "Invalid signature")
        }
        
        @Test("Context is equatable")
        func testContextEquatable() {
            let context1 = APIErrorContext(
                exchange: .bybit,
                httpStatus: 401,
                apiCode: "10004",
                requestId: "test-id",
                endpoint: "/test",
                rawMessage: "Error"
            )
            
            let context2 = APIErrorContext(
                exchange: .bybit,
                httpStatus: 401,
                apiCode: "10004",
                requestId: "test-id",
                endpoint: "/test",
                rawMessage: "Error"
            )
            
            #expect(context1 == context2)
        }
        
        @Test("Context is sendable")
        func testContextSendable() {
            let context = APIErrorContext(
                exchange: .bybit,
                httpStatus: 401,
                apiCode: "10004",
                requestId: nil,
                endpoint: "/test",
                rawMessage: "Error"
            )
            
            // Should compile without warnings about Sendable
            Task {
                let _ = context
            }
        }
    }
}
