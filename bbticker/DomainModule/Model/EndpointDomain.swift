//
//  EndpointDomain.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 10/6/26.
//

import LLCore

public struct WalletEndpoint: Endpoint {
    public typealias Output = WalletData
    public let walletType: WalletType
    public var id: EndpointID { .wallet(walletType) }

    public func path(for exchange: any ExchangeType) -> String {
        exchange.getEndpointString(for: id)
    }

    public init(_ walletType: WalletType) {
        self.walletType = walletType
    }
}

public struct APIKeyInfoEndpoint: Endpoint {
    public typealias Output = ApiKeyInfoData
    public var id: EndpointID { .apiKeyInfo }

    public func path(for exchange: any ExchangeType) -> String {
        exchange.getEndpointString(for: id)
    }

    public init() {}
}
