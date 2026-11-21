//
//  ExchangeRegistryDomain.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 10/9/26.
//

import LLCore
import LLApiService

extension ExchangeRegistry {}

class RegistryHelper {
    func defaultCapabilitiesForBybit() -> ExchangeCapabilities {
        ExchangeCapabilities(
            urls: [
                .production: "https://api.bybit.com",
                .testnet: "https://api-testnet.bybit.com",
                .demo: "https://api-demo.bybit.com"
            ],
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
            endpoints: [
                .wallet(.unified): "/api/v1/accounts",
                .wallet(.spot): "/api/v1/accounts?type=main",
                .wallet(.futures): "/api/v1/account-overview?currency=USDT",
                .apiKeyInfo: "/api/v1/user-info/all-sub-users"
            ]
        )
    }
    
    func getBybitRegistry() -> ExchangeRegistry {
        
        let bybitParserFactory: @Sendable (EndpointID) -> any LLResponseParserProtocol = { endpointType in
            switch endpointType {
            case .wallet(_):
                return BybitUnifiedWalletDataParser()
            case .apiKeyInfo:
                return ByBitApiKeyInfoParser()
            }
        }
        
        let bybitRequestBuilderFactory: @Sendable (ExchangeConfiguration, Credentials, EndpointID) -> LLAPIRequestBuilder = { config, creds, endpointType in
            switch endpointType {
            case .wallet(let walletType):
                return BybitWalletAPIRequestBuilder(exchangeConfiguration: config, walletType: walletType, creds: creds)
            case .apiKeyInfo:
                return BybitAPIKeyInfoAPIRequestBuilder(exchangeConfiguration: config, creds: creds)
            }
        }
        
        return ExchangeRegistry(capabilities: [.bybit: defaultCapabilitiesForBybit()],
                             parserFactories: [.bybit: bybitParserFactory],
                              errorDetectors: [.bybit: BybitErrorDetector()],
                     requestBuilderFactories: [.bybit: bybitRequestBuilderFactory])
    }
}
