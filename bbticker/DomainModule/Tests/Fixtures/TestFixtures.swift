//
//  TestFixtures.swift
//  LLCoreTests
//
//  JSON response fixtures for testing
//

import Foundation
@testable import LLCore

public enum TestFixtures {
    
    // MARK: - Bybit Fixtures
    
    public enum Bybit {
        public static let successUnified = """
        {
            "retCode": 0,
            "retMsg": "OK",
            "result": {
                "totalEquity": "1000.00",
                "totalWalletBalance": "900.00",
                "totalMaintenanceMargin": "50.00"
            },
            "retExtInfo": {},
            "time": 1759564016973
        }
        """
        
        public static let successSpot = """
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
        
        public static let errorAPIKeyExpired = """
        {
            "retCode": 33004,
            "retMsg": "Your api key has expired.",
            "result": {},
            "retExtInfo": {},
            "time": 1759564016973
        }
        """
        
        public static let errorInvalidSignature = """
        {
            "retCode": 10004,
            "retMsg": "Invalid signature",
            "result": {},
            "retExtInfo": {},
            "time": 1759564016973
        }
        """
        
        public static let errorIPNotAllowed = """
        {
            "retCode": 10006,
            "retMsg": "IP address not in whitelist",
            "result": {},
            "retExtInfo": {},
            "time": 1759564016973
        }
        """
        
        public static let errorRateLimited = """
        {
            "retCode": 10016,
            "retMsg": "Too many requests",
            "result": {},
            "retExtInfo": {},
            "time": 1759564016973
        }
        """
        
        public static let errorPermissionDenied = """
        {
            "retCode": 10018,
            "retMsg": "Permission denied for this API",
            "result": {},
            "retExtInfo": {},
            "time": 1759564016973
        }
        """
        
        public static let errorUnknown = """
        {
            "retCode": 99999,
            "retMsg": "Unknown error occurred",
            "result": {},
            "retExtInfo": {},
            "time": 1759564016973
        }
        """
    }
    
    // MARK: - KuCoin Fixtures
    
    public enum KuCoin {
        public static let successFutures = """
        {
            "code": "200000",
            "data": {
                "accountEquity": 1000.50,
                "availableBalance": 950.25,
                "marginBalance": 75.50,
                "currency": "USDT"
            }
        }
        """
        
        public static let successSpot = """
        {
            "code": "200000",
            "data": [
                {
                    "id": "123456",
                    "currency": "USDT",
                    "type": "main",
                    "balance": "1000.00",
                    "available": "950.00",
                    "holds": "50.00"
                },
                {
                    "id": "123457",
                    "currency": "BTC",
                    "type": "trade",
                    "balance": "0.5",
                    "available": "0.5",
                    "holds": "0.0"
                }
            ]
        }
        """
        
        public static let errorAPIKeyNotExists = """
        {
            "code": "400003",
            "msg": "KC-API-KEY not exists"
        }
        """
        
        public static let errorInvalidSignature = """
        {
            "code": "400005",
            "msg": "KC-API-SIGN Invalid"
        }
        """
        
        public static let errorPermissionDenied = """
        {
            "code": "400006",
            "msg": "Permission denied"
        }
        """
        
        public static let errorRateLimited = """
        {
            "code": "429000",
            "msg": "Too Many Requests"
        }
        """
    }
    
    // MARK: - Binance Fixtures
    
    public enum Binance {
        public static let successFutures = """
        {
            "totalMarginBalance": "1234.56789",
            "totalWalletBalance": "1200.00000",
            "totalMaintMargin": "100.00000",
            "availableBalance": "1100.00000"
        }
        """
        
        public static let errorInvalidAPIKey = """
        {
            "code": -2014,
            "msg": "API-key format invalid."
        }
        """
        
        public static let errorInvalidSignature = """
        {
            "code": -1022,
            "msg": "Signature for this request is not valid."
        }
        """
        
        public static let errorTimestamp = """
        {
            "code": -1021,
            "msg": "Timestamp for this request is outside of the recvWindow."
        }
        """
        
        public static let errorRateLimited = """
        {
            "code": -1003,
            "msg": "Too much request weight used"
        }
        """
    }
    
    // MARK: - Invalid/Edge Cases
    
    public enum EdgeCases {
        public static let invalidJSON = "{ invalid json"
        public static let emptyResponse = ""
        public static let emptyObject = "{}"
        public static let emptyArray = "[]"
    }
    
    // MARK: - Test Credentials
    
    public enum TestCredentials {
        public static let bybit = Credentials(
            apiKey: "test-bybit-key",
            apiSecret: "test-bybit-secret",
            passphrase: nil
        )
        
        public static let kucoin = Credentials(
            apiKey: "test-kucoin-key",
            apiSecret: "test-kucoin-secret",
            passphrase: "test-passphrase"
        )
        
        public static let binance = Credentials(
            apiKey: "test-binance-key",
            apiSecret: "test-binance-secret",
            passphrase: nil
        )
    }
}

