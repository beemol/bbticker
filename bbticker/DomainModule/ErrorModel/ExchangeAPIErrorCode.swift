//
//  ExchangeAPIErrorCode.swift
//  LLCore
//
//  Per-exchange API error code registries mapping to APIDomainError categories.
//

import Foundation
import LLCore

public struct ExchangeAPIErrorRegistry {
    /// Returns a domain error case for a given exchange and code/message context if known.
    public static func map(exchange: ExchangeIdentifier, httpStatus: Int?, code: String?, message: String?, endpoint: String?) -> APIDomainError? {
        let normalizedCode = code?.trimmingCharacters(in: .whitespacesAndNewlines)
        let context = APIErrorContext(exchange: exchange, httpStatus: httpStatus, apiCode: normalizedCode, requestId: nil, endpoint: endpoint, rawMessage: message)

        switch exchange {
        case .binance:
            // Binance codes are Ints in JSON but treat as string here for uniformity
            switch normalizedCode {
            case "-2015", "-2014": return .invalidCredentials(context: context)
            case "-1022": return .signatureInvalid(context: context)
            case "-1021": return .timestampOutOfRange(context: context)
            case "-1003": return .rateLimited(context: context)
            case .some(let c) where c == "418" && (httpStatus == 418 || httpStatus == 429):
                return .rateLimited(context: context)
            default: break
            }

        case .bybit:
            // Bybit: retCode integers
            switch normalizedCode {
            case "10006": return .invalidCredentials(context: context)
            case "10005": return .permissionDenied(context: context)
            case "10004": return .signatureInvalid(context: context)
            case "10002": return .timestampOutOfRange(context: context)
            case "10018": return .ipNotAllowed(context: context)
            default: break
            }

        case .kucoin:
            // KuCoin: string codes
            switch normalizedCode {
            case "401001": return .invalidCredentials(context: context)
            case "401002": return .invalidCredentials(context: context) // passphrase
            case "401003": return .signatureInvalid(context: context)
            case "401004": return .timestampOutOfRange(context: context)
            case "403005": return .ipNotAllowed(context: context)
            case "429000": return .rateLimited(context: context)
            default: break
            }
            
        default: return nil
        }

        return nil
    }
}


