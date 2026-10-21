//
//  HTTPStatusErrorDetector.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 20/11/2025.
//


//  Composite error detector that handles both HTTP status errors and application-level errors.
//  This provides a flat, sequential error checking pipeline:
//  1. Check HTTP status codes (401, 403, 500, etc.)
//  2. Check application-level errors in response body (even with HTTP 200)

import Foundation
import LLCore
import LLApiService

/// Composite error detector that checks HTTP status first, then delegates to app-level detector
struct HTTPStatusErrorDetector: LLDomainErrorDetector {
    let exchange: ExchangeIdentifier
    let endpoint: String
    let appLevelDetector: LLDomainErrorDetector?
    
    init(exchange: ExchangeIdentifier, endpoint: String, appLevelDetector: LLDomainErrorDetector?) {
        self.exchange = exchange
        self.endpoint = endpoint
        self.appLevelDetector = appLevelDetector
    }
    
    func detectError(data: Data, response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            // This should never happen for REST API calls
            // If we get here, it means we're not using HTTP/HTTPS protocol
            let context = APIErrorContext(
                exchange: exchange,
                httpStatus: nil,
                apiCode: nil,
                requestId: nil,
                endpoint: endpoint,
                rawMessage: "Response is not HTTPURLResponse (unexpected protocol)"
            )
            throw APIDomainError.unknown(context: context)
        }
        
        // Step 1: Check HTTP status codes (non-200 responses)
        if httpResponse.statusCode != 200 {
            print("HTTPStatusErrorDetector: HTTP error - Status: \(httpResponse.statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("HTTPStatusErrorDetector: Error response body: \(responseString)")
            }
            
            // Map HTTP error to domain error
            if let domainError = APIErrorMapper.mapHTTPResponse(
                exchange: exchange,
                endpoint: endpoint,
                data: data,
                response: httpResponse
            ) {
                throw domainError
            }
            
            // Fallback if mapper returns nil
            let context = APIErrorContext(
                exchange: exchange,
                httpStatus: httpResponse.statusCode,
                apiCode: nil,
                requestId: nil,
                endpoint: endpoint,
                rawMessage: "HTTP \(httpResponse.statusCode)"
            )
            throw APIDomainError.unknown(context: context)
        }
        
        // Step 2: Check for application-level errors (even with HTTP 200)
        // Examples: Bybit returns HTTP 200 with {"retCode": 33004, "retMsg": "API key expired"}
        try appLevelDetector?.detectError(data: data, response: response)
    }
}

