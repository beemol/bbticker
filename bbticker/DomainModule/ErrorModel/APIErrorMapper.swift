//
//  APIErrorMapper.swift
//  bbticker
//
//  Maps HTTP responses and exchange-specific error payloads to APIDomainError.
//

import Foundation
import LLCore

public struct APIErrorMapper {
    public struct ParsedErrorBody {
        public let code: String?
        public let message: String?
        public let requestId: String?
        
        public init(code: String?, message: String?, requestId: String?) {
            self.code = code
            self.message = message
            self.requestId = requestId
        }
    }

    /// Maps a transport/network error into domain error when no HTTP response is available.
    public static func mapNetworkError(_ error: Error, exchange: ExchangeIdentifier, endpoint: String?) -> APIDomainError {
        let context = APIErrorContext(exchange: exchange, httpStatus: nil, apiCode: nil, requestId: nil, endpoint: endpoint, rawMessage: error.localizedDescription)
        return .network(context: context)
    }

    /// Maps an HTTP response + body into a domain error; returns nil for status 200.
    public static func mapHTTPResponse(exchange: ExchangeIdentifier, endpoint: String?, data: Data, response: HTTPURLResponse) -> APIDomainError? {
        let status = response.statusCode
        guard status != 200 else { return nil }

        // Parse a light-weight representation of the error body
        let body = parseErrorBody(exchange: exchange, data: data)

        // First, apply generic HTTP status mapping
        if status == 401 {
            if let mapped = ExchangeAPIErrorRegistry.map(exchange: exchange, httpStatus: status, code: body.code, message: body.message, endpoint: endpoint) {
                return mapped
            }
            let ctx = APIErrorContext(exchange: exchange, httpStatus: status, apiCode: body.code, requestId: body.requestId, endpoint: endpoint, rawMessage: body.message)
            return .invalidCredentials(context: ctx)
        }
        if status == 403 {
            if let mapped = ExchangeAPIErrorRegistry.map(exchange: exchange, httpStatus: status, code: body.code, message: body.message, endpoint: endpoint) {
                return mapped
            }
            let ctx = APIErrorContext(exchange: exchange, httpStatus: status, apiCode: body.code, requestId: body.requestId, endpoint: endpoint, rawMessage: body.message)
            return .permissionDenied(context: ctx)
        }
        if status == 429 {
            let ctx = APIErrorContext(exchange: exchange, httpStatus: status, apiCode: body.code, requestId: body.requestId, endpoint: endpoint, rawMessage: body.message)
            return .rateLimited(context: ctx)
        }
        if (500...599).contains(status) {
            // Try to detect maintenance via message hint
            let lower = (body.message ?? "").lowercased()
            let isMaintenance = lower.contains("mainten") || lower.contains("unavailable")
            let ctx = APIErrorContext(exchange: exchange, httpStatus: status, apiCode: body.code, requestId: body.requestId, endpoint: endpoint, rawMessage: body.message)
            return isMaintenance ? .maintenance(context: ctx) : .server(context: ctx)
        }

        // Next, try exchange-specific mapping via error code/message
        if let mapped = ExchangeAPIErrorRegistry.map(exchange: exchange, httpStatus: status, code: body.code, message: body.message, endpoint: endpoint) {
            return mapped
        }

        // Fallback - unknown
        let ctx = APIErrorContext(exchange: exchange, httpStatus: status, apiCode: body.code, requestId: body.requestId, endpoint: endpoint, rawMessage: body.message)
        return .unknown(context: ctx)
    }

    /// Parses a minimal error body for known exchanges without throwing.
    private static func parseErrorBody(exchange: ExchangeIdentifier, data: Data) -> ParsedErrorBody {
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return ParsedErrorBody(code: nil, message: nil, requestId: nil)
        }

        switch exchange {
        case .binance:
            let codeAny = json["code"]
            let codeString: String?
            if let codeInt = codeAny as? Int { codeString = String(codeInt) }
            else if let codeStr = codeAny as? String { codeString = codeStr }
            else { codeString = nil }
            let msg = json["msg"] as? String ?? json["message"] as? String
            return ParsedErrorBody(code: codeString, message: msg, requestId: nil)

        case .bybit:
            let retCodeAny = json["retCode"]
            let codeString: String?
            if let codeInt = retCodeAny as? Int { codeString = String(codeInt) }
            else if let codeStr = retCodeAny as? String { codeString = codeStr }
            else { codeString = nil }
            let msg = json["retMsg"] as? String ?? json["message"] as? String
            let requestId = json["req_id"] as? String ?? json["requestId"] as? String
            return ParsedErrorBody(code: codeString, message: msg, requestId: requestId)

        case .kucoin:
            let codeString = json["code"] as? String
            let msg = json["msg"] as? String ?? json["message"] as? String
            let requestId = json["requestId"] as? String
            return ParsedErrorBody(code: codeString, message: msg, requestId: requestId)
            
        default:
            return ParsedErrorBody(code: nil, message: nil, requestId: nil)
        }
    }
}


