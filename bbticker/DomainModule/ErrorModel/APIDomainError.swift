//
//  APIDomainError.swift
//  LLCore
//
//  Introduces a unified domain error for REST API failures with localized messaging keys.
//

import Foundation
import LLCore

public enum APIError: Error {
    case invalidRequest
    case noData
    case parseError
    
    public var localizedDescription: String {
        switch self {
        case .invalidRequest:
            return "Invalid API request"
        case .noData:
            return "No data received from API"
        case .parseError:
            return "Failed to parse API response"
        }
    }
}

/// High-level API error taxonomy for user-facing messaging.
public enum APIDomainError: Error, Equatable {
    case invalidCredentials(context: APIErrorContext)
    case permissionDenied(context: APIErrorContext)
    case ipNotAllowed(context: APIErrorContext)
    case keyRevokedOrInactive(context: APIErrorContext)
    case signatureInvalid(context: APIErrorContext)
    case timestampOutOfRange(context: APIErrorContext)
    case missingOrInvalidParams(context: APIErrorContext)
    case rateLimited(context: APIErrorContext)
    case maintenance(context: APIErrorContext)
    case server(context: APIErrorContext)
    case network(context: APIErrorContext)
    case unknown(context: APIErrorContext)
}

/// Additional metadata for diagnostics and analytics (no secrets).
public struct APIErrorContext: Equatable, Sendable {
    public let exchange: ExchangeIdentifier
    public let httpStatus: Int?
    public let apiCode: String?
    public let requestId: String?
    public let endpoint: String?
    public let rawMessage: String?

    public init(
        exchange: ExchangeIdentifier,
        httpStatus: Int? = nil,
        apiCode: String? = nil,
        requestId: String? = nil,
        endpoint: String? = nil,
        rawMessage: String? = nil
    ) {
        self.exchange = exchange
        self.httpStatus = httpStatus
        self.apiCode = apiCode
        self.requestId = requestId
        self.endpoint = endpoint
        self.rawMessage = rawMessage
    }
}

public extension APIDomainError {
    /// Localizable message keys for each error case; UI layer can look up strings.
    var messageKey: String {
        switch self {
        case .invalidCredentials: return "api.invalidCredentials.message"
        case .permissionDenied: return "api.permissionDenied.message"
        case .ipNotAllowed: return "api.ipNotAllowed.message"
        case .keyRevokedOrInactive: return "api.keyRevokedOrInactive.message"
        case .signatureInvalid: return "api.signatureInvalid.message"
        case .timestampOutOfRange: return "api.timestampOutOfRange.message"
        case .missingOrInvalidParams: return "api.missingOrInvalidParams.message"
        case .rateLimited: return "api.rateLimited.message"
        case .maintenance: return "api.maintenance.message"
        case .server: return "api.server.message"
        case .network: return "api.network.message"
        case .unknown: return "api.unknown.message"
        }
    }

    /// Exposes the attached context for presentation/analytics.
    var context: APIErrorContext {
        switch self {
        case .invalidCredentials(let c),
             .permissionDenied(let c),
             .ipNotAllowed(let c),
             .keyRevokedOrInactive(let c),
             .signatureInvalid(let c),
             .timestampOutOfRange(let c),
             .missingOrInvalidParams(let c),
             .rateLimited(let c),
             .maintenance(let c),
             .server(let c),
             .network(let c),
             .unknown(let c):
            return c
        }
    }
}

public extension APIDomainError {
    /// Human-readable, concise, and actionable message for display.
    /// Replace with proper localization lookup using `messageKey` when strings are added.
    var userMessage: String {
        let exchangeName = context.exchange.rawValue.capitalized
        switch self {
        case .invalidCredentials:
            return "\(exchangeName) rejected your credentials. Re-enter API key and secret."
        case .permissionDenied:
            return "Your key lacks required permissions. Update key or create a new one."
        case .ipNotAllowed:
            return "Your API key is restricted by IP. Add this device’s IP."
        case .keyRevokedOrInactive:
            return "Your API key is inactive or revoked. Create a new key and update it."
        case .signatureInvalid:
            return "Invalid request signature. Verify secret and passphrase."
        case .timestampOutOfRange:
            return "Your device time is out of sync. Enable Set Automatically."
        case .missingOrInvalidParams:
            return "The request had missing or invalid parameters. Please try again."
        case .rateLimited:
            return "Rate limit reached. Wait a moment, then retry."
        case .maintenance:
            return "\(exchangeName) is under maintenance. Try again later."
        case .server:
            return "\(exchangeName) server error. Try again later."
        case .network:
            return "No network or unstable connection. Check your internet."
        case .unknown(let ctx):
            if let requestId = ctx.requestId, !requestId.isEmpty {
                return "Unexpected error. Retry or contact support with ID \(requestId)."
            }
            return "Unexpected error. Please try again."
        }
    }
}
