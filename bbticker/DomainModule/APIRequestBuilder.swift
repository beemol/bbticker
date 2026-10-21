//
//  APIRequestBuilder.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 10/7/26.
//

import Foundation
import LLCore
import LLApiService

@MainActor
struct APIRequestBuilderFactory {
    static func builder(for exchangeType: ExchangeType, creds: CredentialManagerProtocol) async -> LLAPIRequestBuilder? {
        let accountName = exchangeType.identifier

        guard let credentials = try? await creds.getCredentials(forAccount: accountName.rawValue) else { return nil }

        switch accountName {
        case .bybit:
            return BybitWalletAPIRequestBuilder(exchangeType: exchangeType, creds: credentials)
        case .kucoin:
            return KuCoinAPIRequestBuilder(exchangeType: exchangeType, creds: credentials)
        case .binance:
            return BinanceAPIRequestBuilder(exchangeType: exchangeType, creds: credentials)
        default:
            return BybitWalletAPIRequestBuilder(exchangeType: exchangeType, creds: credentials)
        }
    }
}

struct BybitAPIKeyInfoAPIRequestBuilder: LLAPIRequestBuilder {
    let exchangeType: ExchangeType
    let creds: Credentials
    
    func createRequest() throws -> URLRequest {
        // Get the endpoint from your capabilities
        let urlString = exchangeType.baseURL + APIKeyInfoEndpoint().path(for: exchangeType)
        guard let url = URL(string: urlString) else {
            throw APIError.invalidRequest
        }
        
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let recvWindow = "5000"
        
        // For API key info endpoint, no query params needed
        // Signature is: timestamp + apiKey + recvWindow
        let signaturePayload = timestamp + creds.apiKey + recvWindow
        let signature = signaturePayload.hmacSHA256(key: creds.apiSecret)
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(creds.apiKey, forHTTPHeaderField: "X-BAPI-API-KEY")
        request.setValue(timestamp, forHTTPHeaderField: "X-BAPI-TIMESTAMP")
        request.setValue(recvWindow, forHTTPHeaderField: "X-BAPI-RECV-WINDOW")
        request.setValue(signature, forHTTPHeaderField: "X-BAPI-SIGN")
        
        return request
    }
}

// MARK: concrete implementations
struct BybitWalletAPIRequestBuilder: LLAPIRequestBuilder {
    let exchangeType: ExchangeType
    let creds: Credentials
    
    init(exchangeType: ExchangeType, creds: Credentials) {
        self.exchangeType = exchangeType
        self.creds = creds
    }
    
    func createRequest() throws -> URLRequest {
        // Use endpoint as-is; it already contains the accountType query for spot/unified
        let walletType = exchangeType.walletType
        let urlString = exchangeType.baseURL + WalletEndpoint(walletType).path(for: exchangeType)
        guard let url = URL(string: urlString) else {
            throw APIError.invalidRequest
        }
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let recvWindow = "5000"
        // Sign with accountType matching selected wallet
        // let accountTypeParam: String = (exchangeType.walletType == .spot) ? "SPOT" : "UNIFIED"
        let accountTypeParam: String = "UNIFIED"
        let queryString = "accountType=\(accountTypeParam)"
        let signaturePayload = timestamp + creds.apiKey + recvWindow + queryString
        let signature = signaturePayload.hmacSHA256(key: creds.apiSecret)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(creds.apiKey, forHTTPHeaderField: "X-BAPI-API-KEY")
        request.setValue(timestamp, forHTTPHeaderField: "X-BAPI-TIMESTAMP")
        request.setValue(recvWindow, forHTTPHeaderField: "X-BAPI-RECV-WINDOW")
        request.setValue(signature, forHTTPHeaderField: "X-BAPI-SIGN")
        return request
    }
}

struct KuCoinAPIRequestBuilder: LLAPIRequestBuilder {
    
    let exchangeType: ExchangeType
    let creds: Credentials
    let apiVersion: String = "3"
    
    init(exchangeType: ExchangeType, creds: Credentials) {
        self.exchangeType = exchangeType
        self.creds = creds
    }
    
    func createRequest() throws -> URLRequest {
        let walletType = exchangeType.walletType
        let endpoint = WalletEndpoint(walletType).path(for: exchangeType)
        let urlString = exchangeType.baseURL + endpoint
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidRequest
        }
        
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let method = "GET"
        
        
        // For KuCoin API v3, the signature format is: timestamp + method + endpoint + body
        // For GET requests, body is empty
        let signaturePayload = timestamp + method + endpoint
        let signatureHex = signaturePayload.hmacSHA256(key: creds.apiSecret)
        // Convert hex signature to base64
        let signatureData = hexStringToData(signatureHex)
        let signature = signatureData.base64EncodedString()
        
        // Handle passphrase based on API version
        let requestPassphrase: String
        
        // For API v3, passphrase needs to be encrypted with HMAC-sha256 and then base64 encoded
        if apiVersion == "3", let encryptedPassphrase = creds.passphrase?.hmacSHA256(key: creds.apiSecret) {
            // Convert hex string to data and then base64 encode
            let hexData = hexStringToData(encryptedPassphrase)
            requestPassphrase = hexData.base64EncodedString()
        } else {
            // For older versions, passphrase needs to be base64 encoded
            requestPassphrase = creds.passphrase?.data(using: .utf8)?.base64EncodedString() ?? creds.passphrase ?? ""
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(creds.apiKey, forHTTPHeaderField: "KC-API-KEY")
        request.setValue(timestamp, forHTTPHeaderField: "KC-API-TIMESTAMP")
        request.setValue(signature, forHTTPHeaderField: "KC-API-SIGN")
        request.setValue(requestPassphrase, forHTTPHeaderField: "KC-API-PASSPHRASE")
        request.setValue(apiVersion, forHTTPHeaderField: "KC-API-KEY-VERSION")
        
        return request
    }
}

struct BinanceAPIRequestBuilder: LLAPIRequestBuilder {
    let exchangeType: ExchangeType
    let creds: Credentials
    
    init(exchangeType: ExchangeType, creds: Credentials) {
        self.exchangeType = exchangeType
        self.creds = creds
    }
    
    func createRequest() throws -> URLRequest {
        // Binance USDT-M Futures account (equity) endpoint
        // GET /fapi/v2/account with signed query: timestamp & optional recvWindow
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let recvWindow = "5000"
        let queryString = "timestamp=\(timestamp)&recvWindow=\(recvWindow)"
        let signature = queryString.hmacSHA256(key: creds.apiSecret)
        
        let urlString = "https://testnet.binancefuture.com/fapi/v2/account?\(queryString)&signature=\(signature)"
        //let urlString = "https://fapi.binance.com/fapi/v2/account?\(queryString)&signature=\(signature)"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidRequest
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(creds.apiKey, forHTTPHeaderField: "X-MBX-APIKEY")
        return request
    }
}
