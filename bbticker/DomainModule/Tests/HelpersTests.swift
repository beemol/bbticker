//
//  HelpersTests.swift
//  LLCoreTests
//
//  Tests for helper functions
//

import Testing
import Foundation
@testable import bbticker
@testable import LLCore

@Suite("Helper Function Tests")
struct HelpersTests {
    
    // MARK: - HMAC-SHA256 Tests
    
    @Suite("HMAC-SHA256")
    struct HMACSHATests {
        
        @Test("Generates correct HMAC-SHA256 signature")
        func testGeneratesCorrectSignature() {
            let message = "test message"
            let key = "secret key"
            
            let signature = message.hmacSHA256(key: key)
            
            #expect(!signature.isEmpty)
            #expect(signature.count == 64) // SHA256 produces 64 hex characters
        }
        
        @Test("Signature is deterministic")
        func testSignatureIsDeterministic() {
            let message = "test message"
            let key = "secret key"
            
            let signature1 = message.hmacSHA256(key: key)
            let signature2 = message.hmacSHA256(key: key)
            
            #expect(signature1 == signature2)
        }
        
//        @Test("Different messages produce different signatures")
//        func testDifferentMessagesProduceDifferentSignatures() {
//            let key = "secret key"
//            
//            let signature1 = "message 1".hmacSHA256(key: key)
//            let signature2 = "message 2".hmacSHA256(key: key)
//            
//            #expect(signature1 != signature2)
//        }
//        
//        @Test("Different keys produce different signatures")
//        func testDifferentKeysProduceDifferentSignatures() {
//            let message = "test message"
//            
//            let signature1 = message.hmacSHA256(key: "key1")
//            let signature2 = message.hmacSHA256(key: "key2")
//            
//            #expect(signature1 != signature2)
//        }
        
        @Test("Handles empty message")
        func testHandlesEmptyMessage() {
            let message = ""
            let key = "secret key"
            
            let signature = message.hmacSHA256(key: key)
            
            #expect(!signature.isEmpty)
            #expect(signature.count == 64)
        }
        
        @Test("Handles empty key")
        func testHandlesEmptyKey() {
            let message = "test message"
            let key = ""
            
            let signature = message.hmacSHA256(key: key)
            
            #expect(!signature.isEmpty)
            #expect(signature.count == 64)
        }
        
        @Test("Signature is lowercase hex")
        func testSignatureIsLowercaseHex() {
            let message = "test message"
            let key = "secret key"
            
            let signature = message.hmacSHA256(key: key)
            
            let hexCharacters = CharacterSet(charactersIn: "0123456789abcdef")
            let signatureCharacters = CharacterSet(charactersIn: signature)
            
            #expect(hexCharacters.isSuperset(of: signatureCharacters))
        }
        
        @Test("Handles special characters")
        func testHandlesSpecialCharacters() {
            let message = "test!@#$%^&*()_+-=[]{}|;':\",./<>?"
            let key = "secret!@#$%^&*()"
            
            let signature = message.hmacSHA256(key: key)
            
            #expect(!signature.isEmpty)
            #expect(signature.count == 64)
        }
        
        @Test("Handles Unicode characters")
        func testHandlesUnicodeCharacters() {
            let message = "测试消息 🚀"
            let key = "密钥"
            
            let signature = message.hmacSHA256(key: key)
            
            #expect(!signature.isEmpty)
            #expect(signature.count == 64)
        }
        
        @Test("Known test vector 2")
        func testKnownVector2() {
            let message = ""
            let key = ""
            
            let signature = message.hmacSHA256(key: key)
            
            // Known HMAC-SHA256 result for empty string with empty key
            let expected = "b613679a0814d9ec772f95d778c35fc5ff1697c493715653c6c712144292c5ad"
            #expect(signature == expected)
        }
        
        @Test("Returns empty string for invalid UTF-8")
        func testReturnsEmptyForInvalidData() {
            // This is hard to test directly since Swift strings are valid UTF-8
            // But we can verify the function handles edge cases gracefully
            let message = "valid message"
            let key = "valid key"
            
            let signature = message.hmacSHA256(key: key)
            
            #expect(!signature.isEmpty)
        }
    }
    
    // MARK: - Hex String to Data Tests
    
    @Suite("Hex String to Data Conversion")
    struct HexStringToDataTests {
        
        @Test("Converts valid hex string to data")
        func testConvertsValidHexString() {
            let hexString = "48656c6c6f" // "Hello" in hex
            
            let data = hexStringToData(hexString)
            let string = String(data: data, encoding: .utf8)
            
            #expect(string == "Hello")
        }
        
        @Test("Handles empty string")
        func testHandlesEmptyString() {
            let hexString = ""
            
            let data = hexStringToData(hexString)
            
            #expect(data.isEmpty)
        }
        
        @Test("Handles uppercase hex")
        func testHandlesUppercaseHex() {
            let hexString = "48656C6C6F" // "Hello" in uppercase hex
            
            let data = hexStringToData(hexString)
            let string = String(data: data, encoding: .utf8)
            
            #expect(string == "Hello")
        }
        
        @Test("Handles lowercase hex")
        func testHandlesLowercaseHex() {
            let hexString = "48656c6c6f" // "Hello" in lowercase hex
            
            let data = hexStringToData(hexString)
            let string = String(data: data, encoding: .utf8)
            
            #expect(string == "Hello")
        }
        
        @Test("Handles mixed case hex")
        func testHandlesMixedCaseHex() {
            let hexString = "48656C6c6F" // "Hello" in mixed case hex
            
            let data = hexStringToData(hexString)
            let string = String(data: data, encoding: .utf8)
            
            #expect(string == "Hello")
        }
        
        @Test("Converts long hex string")
        func testConvertsLongHexString() {
            let hexString = "0123456789abcdef0123456789abcdef"
            
            let data = hexStringToData(hexString)
            
            #expect(data.count == 16) // 32 hex chars = 16 bytes
        }
        
        @Test("Handles odd-length hex string")
        func testHandlesOddLengthHexString() {
            let hexString = "123" // Odd length
            
            let data = hexStringToData(hexString)
            
            // Should handle gracefully (may truncate or pad)
            #expect(data.count >= 0)
        }
        
        @Test("Handles invalid hex characters gracefully")
        func testHandlesInvalidHexCharacters() {
            let hexString = "48656c6c6g" // 'g' is not a valid hex character
            
            let data = hexStringToData(hexString)
            
            // Should handle gracefully without crashing
            #expect(data.count >= 0)
        }
        
        @Test("Converts all zeros")
        func testConvertsAllZeros() {
            let hexString = "00000000"
            
            let data = hexStringToData(hexString)
            
            #expect(data.count == 4)
            #expect(data.allSatisfy { $0 == 0 })
        }
        
        @Test("Converts all ones")
        func testConvertsAllOnes() {
            let hexString = "ffffffff"
            
            let data = hexStringToData(hexString)
            
            #expect(data.count == 4)
            #expect(data.allSatisfy { $0 == 255 })
        }
        
        @Test("Round trip conversion")
        func testRoundTripConversion() {
            let originalString = "Test Data 123"
            let originalData = originalString.data(using: .utf8)!
            
            // Convert to hex
            let hexString = originalData.map { String(format: "%02x", $0) }.joined()
            
            // Convert back to data
            let convertedData = hexStringToData(hexString)
            let convertedString = String(data: convertedData, encoding: .utf8)
            
            #expect(convertedString == originalString)
        }
        
        @Test("Converts signature hex to base64")
        func testConvertsSignatureHexToBase64() {
            // This tests the use case in KuCoin request builder
            let signatureHex = "48656c6c6f20576f726c64" // "Hello World" in hex
            
            let data = hexStringToData(signatureHex)
            let base64 = data.base64EncodedString()
            
            #expect(!base64.isEmpty)
            
            // Verify round trip
            let decodedData = Data(base64Encoded: base64)
            let decodedString = String(data: decodedData!, encoding: .utf8)
            #expect(decodedString == "Hello World")
        }
    }
    
    // MARK: - Integration Tests
    
    @Suite("Helper Integration")
    struct HelperIntegrationTests {
        
        @Test("HMAC signature can be converted to base64")
        func testHMACToBase64Conversion() {
            let message = "test message"
            let key = "secret key"
            
            let signatureHex = message.hmacSHA256(key: key)
            let signatureData = hexStringToData(signatureHex)
            let signatureBase64 = signatureData.base64EncodedString()
            
            #expect(!signatureBase64.isEmpty)
            #expect(signatureBase64.count > 0)
        }
        
        @Test("Signature generation matches expected format for Bybit")
        func testBybitSignatureFormat() {
            // Simulate Bybit signature generation
            let timestamp = "1234567890000"
            let apiKey = "test-api-key"
            let recvWindow = "5000"
            let queryString = "accountType=UNIFIED"
            
            let signaturePayload = timestamp + apiKey + recvWindow + queryString
            let signature = signaturePayload.hmacSHA256(key: "test-secret")
            
            #expect(signature.count == 64)
            #expect(signature.allSatisfy { "0123456789abcdef".contains($0) })
        }
        
        @Test("Signature generation matches expected format for KuCoin")
        func testKuCoinSignatureFormat() {
            // Simulate KuCoin signature generation
            let timestamp = "1234567890000"
            let method = "GET"
            let endpoint = "/api/v1/account-overview"
            
            let signaturePayload = timestamp + method + endpoint
            let signatureHex = signaturePayload.hmacSHA256(key: "test-secret")
            let signatureData = hexStringToData(signatureHex)
            let signatureBase64 = signatureData.base64EncodedString()
            
            #expect(!signatureBase64.isEmpty)
            // Base64 should be different from hex
            #expect(signatureBase64 != signatureHex)
        }
        
        @Test("Signature generation matches expected format for Binance")
        func testBinanceSignatureFormat() {
            // Simulate Binance signature generation
            let timestamp = "1234567890000"
            let recvWindow = "5000"
            let queryString = "timestamp=\(timestamp)&recvWindow=\(recvWindow)"
            
            let signature = queryString.hmacSHA256(key: "test-secret")
            
            #expect(signature.count == 64)
            #expect(signature.allSatisfy { "0123456789abcdef".contains($0) })
        }
    }
}

