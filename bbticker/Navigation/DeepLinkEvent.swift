//
//  DeepLinkRouter.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 9/28/26.
//

import Foundation

enum DeepLinkEvent: Sendable {
    case bybitConnectionCompleted
}

enum DeepLinkParser {
    static func parse(_ url: URL) -> DeepLinkEvent? {
        guard url.scheme == "bbticker",
              url.host == "connect"
        else {
            return nil
        }

        let components = url.pathComponents

        guard components.count == 3,
              components[1] == "bybit",
              components[2] == "complete"
        else {
            return nil
        }

        return .bybitConnectionCompleted
    }
}

enum RouteResolver {
    static func resolve(_ event: DeepLinkEvent) -> AppRoute {
        switch event {
        case .bybitConnectionCompleted:
            return .settings(section: .apiCredentials)
        }
    }
}
