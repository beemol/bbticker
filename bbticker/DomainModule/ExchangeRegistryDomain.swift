//
//  ExchangeRegistryDomain.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 10/9/26.
//

import LLCore

extension ExchangeRegistry {
    // MARK: - Default Registrations
    func registerBybitDefaults() {
        setCapabilities(defaultCapabilitiesForBybit(), for: .bybit)
        
        registerParserFactory({ endpointType in
            switch endpointType {
            case .wallet(_):
                return BybitUnifiedWalletDataParser()
            case .apiKeyInfo:
                return ByBitApiKeyInfoParser()
            }
        }, for: .bybit)
        
        registerErrorDetector(BybitErrorDetector(), for: .bybit)
        
        registerRequestBuilderFactory({ config, creds, endpointType in
            switch endpointType {
            case .wallet(_):
                return BybitWalletAPIRequestBuilder(exchangeType: config, creds: creds)
            case .apiKeyInfo:
                return BybitAPIKeyInfoAPIRequestBuilder(exchangeType: config, creds: creds)
            }
        }, for: .bybit)
    }
    
    func registerKuCoinDefaults() {
        setCapabilities(defaultCapabilitiesForKucoin(), for: .kucoin)
        
        registerParserFactory({ endpointType in
            switch endpointType {
            case .wallet(let walletType):
                return KuCoinWalletDataParser(walletType: walletType)
            case .apiKeyInfo:
                // TODO:
                return KuCoinWalletDataParser() // temporary fallback
            }
        }, for: .kucoin)
        
        registerErrorDetector(KucoinErrorDetector(), for: .kucoin)
        
        registerRequestBuilderFactory({ config, creds, endpointType in
            KuCoinAPIRequestBuilder(exchangeType: config, creds: creds)
        }, for: .kucoin)
    }
    
    // helpers
    func defaultCapabilitiesForBybit() -> ExchangeCapabilities {
        ExchangeCapabilities(
            urls: [
                .production: "https://api.bybit.com",
                .testnet: "https://api-testnet.bybit.com",
                .demo: "https://api-demo.bybit.com"
            ],
//            walletEndpoints: [
//                .unified: "/v5/account/wallet-balance?accountType=UNIFIED",
//                .spot: "/v5/account/wallet-balance?accountType=SPOT",
//                .futures: "/v5/account/wallet-balance?accountType=CONTRACT"
//            ],
            endpoints: [
                .wallet(.unified): "/v5/account/wallet-balance?accountType=UNIFIED",
                .wallet(.spot): "/v5/account/wallet-balance?accountType=SPOT",
                .wallet(.futures): "/v5/account/wallet-balance?accountType=CONTRACT",
                .apiKeyInfo: "/v5/user/query-api"
            ]
        )
    }
    
    func defaultCapabilitiesForKucoin() -> ExchangeCapabilities {
        ExchangeCapabilities(
            urls: [
                .production: "https://api-futures.kucoin.com",
                .testnet: "https://api-sandbox-futures.kucoin.com",
                .demo: "https://api-sandbox-futures.kucoin.com"
            ],
//            walletEndpoints: [
//                .futures: "/api/v1/account-overview?currency=USDT",
//                .spot: "/api/v1/accounts?type=main",
//                .unified: "/api/v1/accounts",
//            ],
            endpoints: [
                .wallet(.unified): "/api/v1/accounts",
                .wallet(.spot): "/api/v1/accounts?type=main",
                .wallet(.futures): "/api/v1/account-overview?currency=USDT",
                .apiKeyInfo: "/api/v1/user-info/all-sub-users"
            ]
        )
    }
}
