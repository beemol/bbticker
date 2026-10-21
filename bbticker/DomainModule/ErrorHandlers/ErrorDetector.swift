//
//  ErrorDetector.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 20/11/2025.
//

import Foundation
import LLCore
import LLApiService

/// Detects application-level errors in response body even when HTTP status is 200
/// Different exchanges have different error response formats
struct AplicationErrorDetectorFactory {
    static func build(for exchangeName: ExchangeIdentifier) -> LLDomainErrorDetector? {

        switch exchangeName {
        case .bybit:
            return BybitErrorDetector()
        case .kucoin:
            return KucoinErrorDetector()
        case .binance:
            return BinanceErrorDetector()
        default:
            return nil
        }
    }
}

public struct BybitErrorDetector: LLDomainErrorDetector {
    public init() {}
    
    public func detectError(data: Data, response: URLResponse) throws {
        let exchange: ExchangeIdentifier = .bybit
        let endpoint: String = (response as? HTTPURLResponse)?.url?.absoluteString ?? "Bybit Endpoint"
        
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            // Can't parse JSON - no application error detected, let parser handle invalid JSON
            return
        }
        
        // Bybit format: {"retCode":33004,"retMsg":"Your api key has expired.","result":{},"retExtInfo":{},"time":1759564016973}
        if let retCode = json["retCode"] as? Int, retCode != 0,
           let retMsg = json["retMsg"] as? String {
            
            let context = APIErrorContext(
                exchange: exchange,
                httpStatus: 200,
                apiCode: String(retCode),
                requestId: nil,
                endpoint: endpoint,
                rawMessage: retMsg
            )
            
            // Map Bybit error codes to domain errors
            switch retCode {
            case 10003, 33004: // API key expired/invalid
                throw APIDomainError.keyRevokedOrInactive(context: context)
            case 10004, 10005: // Invalid signature
                throw APIDomainError.signatureInvalid(context: context)
            case 10006: // IP not whitelisted
                throw APIDomainError.ipNotAllowed(context: context)
            case 10018, 10019: // Permission denied
                throw APIDomainError.permissionDenied(context: context)
            case 10016: // Too many requests
                throw APIDomainError.rateLimited(context: context)
            default:
                throw APIDomainError.unknown(context: context)
            }
        }
    }
}

public struct KucoinErrorDetector: LLDomainErrorDetector {
    public init() {}
    
    public func detectError(data: Data, response: URLResponse) throws {
        let exchange: ExchangeIdentifier = .kucoin
        let endpoint: String = (response as? HTTPURLResponse)?.url?.absoluteString ?? "Kucoin Endpoint"
        
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            // Can't parse JSON - no application error detected, let parser handle invalid JSON
            return
        }
        
        // KuCoin format: {"code":"400003","msg":"KC-API-KEY not exists"}
        if let code = json["code"] as? String, code != "200000",
           let msg = json["msg"] as? String {
            
            let context = APIErrorContext(
                exchange: exchange,
                httpStatus: 200,
                apiCode: code,
                requestId: nil,
                endpoint: endpoint,
                rawMessage: msg
            )
            
            // Map KuCoin error codes to domain errors
            switch code {
            case "400003", "400004": // API key issues
                throw APIDomainError.invalidCredentials(context: context)
            case "400005": // Invalid signature
                throw APIDomainError.signatureInvalid(context: context)
            case "400006": // Permission denied
                throw APIDomainError.permissionDenied(context: context)
            case "429000": // Too many requests
                throw APIDomainError.rateLimited(context: context)
            default:
                throw APIDomainError.unknown(context: context)
            }
        }
    }
}

struct BinanceErrorDetector: LLDomainErrorDetector {
    func detectError(data: Data, response: URLResponse) throws {
        let exchange: ExchangeIdentifier = .binance
        let endpoint: String = (response as? HTTPURLResponse)?.url?.absoluteString ?? "Binance Endpoint"
        
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            // Can't parse JSON - no application error detected, let parser handle invalid JSON
            return
        }
        
        // Binance format: {"code":-1022,"msg":"Signature for this request is not valid."}
        if let code = json["code"] as? Int, code != 0,
           let msg = json["msg"] as? String {
            
            let context = APIErrorContext(
                exchange: exchange,
                httpStatus: 200,
                apiCode: String(code),
                requestId: nil,
                endpoint: endpoint,
                rawMessage: msg
            )
            
            // Map Binance error codes to domain errors
            switch code {
            case -2014, -2015: // API key issues
                throw APIDomainError.invalidCredentials(context: context)
            case -1022: // Invalid signature
                throw APIDomainError.signatureInvalid(context: context)
            case -1021: // Timestamp issues
                throw APIDomainError.timestampOutOfRange(context: context)
            case -1003: // Too many requests
                throw APIDomainError.rateLimited(context: context)
            default:
                throw APIDomainError.unknown(context: context)
            }
        }
    }
}
