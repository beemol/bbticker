//
//  ApiKeyInfoData.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 10/6/26.
//

import Foundation

/// Response data for API key information endpoint
public struct ApiKeyInfoData: Sendable, Equatable {
    public let expiredAt: Date?
    public let deadlineDay: Int?
    public let createdAt: Date
    public let ips: [String]?
    public let note: String?
    public let readOnly: Int?
    public let apiKey: String?
    public let type: Int?
    
    public init(
        expiredAt: Date? = nil,
        deadlineDay: Int? = nil,
        createdAt: Date,
        ips: [String]? = nil,
        note: String? = nil,
        readOnly: Int? = nil,
        apiKey: String? = nil,
        type: Int? = nil
    ) {
        self.expiredAt = expiredAt
        self.deadlineDay = deadlineDay
        self.createdAt = createdAt
        self.ips = ips
        self.note = note
        self.readOnly = readOnly
        self.apiKey = apiKey
        self.type = type
    }
}
