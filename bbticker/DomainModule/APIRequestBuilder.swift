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
    static func builder(for exchange: Exchange, exchangeConfiguration: ExchangeConfiguration, creds: CredentialManagerProtocol) async -> LLAPIRequestBuilder? {
        let accountName = exchange.identifier

        guard let credentials = try? await creds.getCredentials(forAccount: accountName.rawValue) else { return nil }

        switch accountName {
        case .bybit:
            return BybitWalletAPIRequestBuilder(exchangeConfiguration: exchangeConfiguration, walletType: exchange.walletType, creds: credentials)
//        case .kucoin:
//            return KuCoinAPIRequestBuilder(exchangeConfiguration: ExchangeConfiguration, creds: credentials)
//        case .binance:
//            return BinanceAPIRequestBuilder(Exchange: Exchange, creds: credentials)
        default:
            return BybitWalletAPIRequestBuilder(exchangeConfiguration: exchangeConfiguration, walletType: exchange.walletType, creds: credentials)
        }
    }
}

struct BybitAPIKeyInfoAPIRequestBuilder: LLAPIRequestBuilder {
    let exchangeConfiguration: ExchangeConfiguration
    let creds: Credentials
    
    func createRequest() throws -> URLRequest {
        // Get the endpoint from your capabilities
        let baseURL = exchangeConfiguration.baseURL
        guard let endpointString = exchangeConfiguration.endpoint(for: .apiKeyInfo), let url = URL(string: baseURL + endpointString) else {
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
    let exchangeConfiguration: ExchangeConfiguration
    let walletType: WalletType
    let creds: Credentials
    
    func createRequest() throws -> URLRequest {
        let baseURL = exchangeConfiguration.baseURL
        guard let endpointString = exchangeConfiguration.endpoint(for: .wallet(walletType)), let url = URL(string: baseURL + endpointString) else {
            throw APIError.invalidRequest
        }
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let recvWindow = "5000"
        // Sign with accountType matching selected wallet
        // let accountTypeParam: String = (exchange.walletType == .spot) ? "SPOT" : "UNIFIED"
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

//struct KuCoinAPIRequestBuilder: LLAPIRequestBuilder {
//    
//    let exchangeConfiguration: ExchangeConfiguration
//    let walletType: WalletType
//    let creds: Credentials
//    let apiVersion: String = "3"
//    
//    func createRequest() throws -> URLRequest {
//        let urlString = exchangeConfiguration.baseURL + exchangeConfiguration.endpoint(for: .wallet(walletType))
//        
//        guard let url = URL(string: urlString) else {
//            throw APIError.invalidRequest
//        }
//        
//        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
//        let method = "GET"
//        
//        
//        // For KuCoin API v3, the signature format is: timestamp + method + endpoint + body
//        // For GET requests, body is empty
//        let signaturePayload = timestamp + method + exchangeConfiguration.endpoint(for: .wallet(walletType))
//        let signatureHex = signaturePayload.hmacSHA256(key: creds.apiSecret)
//        // Convert hex signature to base64
//        let signatureData = hexStringToData(signatureHex)
//        let signature = signatureData.base64EncodedString()
//        
//        // Handle passphrase based on API version
//        let requestPassphrase: String
//        
//        // For API v3, passphrase needs to be encrypted with HMAC-sha256 and then base64 encoded
//        if apiVersion == "3", let encryptedPassphrase = creds.passphrase?.hmacSHA256(key: creds.apiSecret) {
//            // Convert hex string to data and then base64 encode
//            let hexData = hexStringToData(encryptedPassphrase)
//            requestPassphrase = hexData.base64EncodedString()
//        } else {
//            // For older versions, passphrase needs to be base64 encoded
//            requestPassphrase = creds.passphrase?.data(using: .utf8)?.base64EncodedString() ?? creds.passphrase ?? ""
//        }
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = "GET"
//        request.setValue(creds.apiKey, forHTTPHeaderField: "KC-API-KEY")
//        request.setValue(timestamp, forHTTPHeaderField: "KC-API-TIMESTAMP")
//        request.setValue(signature, forHTTPHeaderField: "KC-API-SIGN")
//        request.setValue(requestPassphrase, forHTTPHeaderField: "KC-API-PASSPHRASE")
//        request.setValue(apiVersion, forHTTPHeaderField: "KC-API-KEY-VERSION")
//        
//        return request
//    }
//}

//struct BinanceAPIRequestBuilder: LLAPIRequestBuilder {
//    let exchange: Exchange
//    let creds: Credentials
//    
//    init(Exchange: Exchange, creds: Credentials) {
//        self.exchange = Exchange
//        self.creds = creds
//    }
//    
//    func createRequest() throws -> URLRequest {
//        // Binance USDT-M Futures account (equity) endpoint
//        // GET /fapi/v2/account with signed query: timestamp & optional recvWindow
//        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
//        let recvWindow = "5000"
//        let queryString = "timestamp=\(timestamp)&recvWindow=\(recvWindow)"
//        let signature = queryString.hmacSHA256(key: creds.apiSecret)
//        
//        let urlString = "https://testnet.binancefuture.com/fapi/v2/account?\(queryString)&signature=\(signature)"
//        //let urlString = "https://fapi.binance.com/fapi/v2/account?\(queryString)&signature=\(signature)"
//        guard let url = URL(string: urlString) else {
//            throw APIError.invalidRequest
//        }
//        var request = URLRequest(url: url)
//        request.httpMethod = "GET"
//        request.setValue(creds.apiKey, forHTTPHeaderField: "X-MBX-APIKEY")
//        return request
//    }
//}
