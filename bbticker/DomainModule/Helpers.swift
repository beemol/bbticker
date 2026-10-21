//
//  Helpers.swift
//  LLCore
//
//  Created by Aleh Fiodarau on 24/11/2025.
//

import Foundation
import CommonCrypto

// Helper function to convert hex string to Data
public func hexStringToData(_ hexString: String) -> Data {
    let len = hexString.count / 2
    var data = Data(capacity: len)
    for i in 0..<len {
        let j = hexString.index(hexString.startIndex, offsetBy: i * 2)
        let k = hexString.index(j, offsetBy: 2)
        let bytes = hexString[j..<k]
        if var num = UInt8(bytes, radix: 16) {
            data.append(&num, count: 1)
        }
    }
    return data
}


public extension String {
    func hmacSHA256(key: String) -> String {
        guard let keyData = key.data(using: .utf8),
              let messageData = self.data(using: .utf8) else {
            return ""
        }

        let keyBytes = keyData.withUnsafeBytes { $0.baseAddress!.assumingMemoryBound(to: UInt8.self) }
        let messageBytes = messageData.withUnsafeBytes { $0.baseAddress!.assumingMemoryBound(to: UInt8.self) }

        var hmac = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), keyBytes, keyData.count, messageBytes, messageData.count, &hmac)

        let hmacData = Data(hmac)
        return hmacData.map { String(format: "%02hhx", $0) }.joined()
    }
}
