//
//  ExchangeIdentifierDomain.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 10/9/26.
//

import LLCore

public extension ExchangeIdentifier {
    
    // Known exchanges - compiler-checked
    static let bybit = ExchangeIdentifier(rawValue: "bybit")
    static let kucoin = ExchangeIdentifier(rawValue: "kucoin")
    static let binance = ExchangeIdentifier(rawValue: "binance")
}
