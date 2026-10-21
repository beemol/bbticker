//
//  ByBitApiKeyInfoParser.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 10/9/26.
//

import Foundation
import LLCore
import LLApiService

public struct ByBitApiKeyInfoParser: LLResponseParserProtocol {
    public typealias Output = ApiKeyInfoData
    
    public init() {}
    
    public func parse(data: Data) throws -> ApiKeyInfoData {
        let decoder = JSONDecoder()
        
        // ByBit uses ISO8601 format for dates or empty string "1970-01-01T00:00:00Z" for null
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Check for ByBit's "null date" format
            if dateString == "1970-01-01T00:00:00Z" || dateString.isEmpty {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Cannot decode date string: \(dateString)"
                )
            }
            
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            
            guard let date = formatter.date(from: dateString) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Cannot decode date string: \(dateString)"
                )
            }
            return date
        }
        
        let response = try decoder.decode(ByBitResponse.self, from: data)
        
        guard response.retCode == 0 else {
            throw APIError.parseError
        }
        
        return ApiKeyInfoData(
            expiredAt: response.result.expiredAt,
            deadlineDay: response.result.deadlineDay,
            createdAt: response.result.createdAt ?? Date(),
            ips: response.result.ips,
            note: response.result.note,
            readOnly: response.result.readOnly,
            apiKey: response.result.apiKey,
            type: response.result.type
        )
    }
}

// MARK: - ByBit Response Models
private struct ByBitResponse: Decodable {
    let retCode: Int
    let retMsg: String
    let result: ResultData
    let time: Int64
}

private struct ResultData: Decodable {
    let expiredAt: Date?
    let deadlineDay: Int?
    let createdAt: Date?
    let ips: [String]?
    let note: String?
    let readOnly: Int?
    let apiKey: String?
    let type: Int?
}
