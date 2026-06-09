//
//  GeneralHelper.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 06/09/2025.
//

import Foundation
import SwiftUI
import LLCore

func getAppName() -> String {
    return Bundle.main.localizedInfoDictionary?["CFBundleName"] as? String ?? "BTicker"
}

func getBundleIdentifier() -> String {
    return Bundle.main.bundleIdentifier ?? "com.afiodarau." + getAppName()
}

extension Exchange {
    var displayColor: Color {
        switch identifier {
        case .bybit:
            return Color.orange
        case .kucoin:
            return Color.mint
        case .binance:
            return Color.yellow
        default:
            return Color.primary
        }
    }
}

#if canImport(FirebaseCore)
import FirebaseCore
#endif
enum FirebaseBootstrap {
    static var isConfigured: Bool {
        #if canImport(FirebaseCore)
            FirebaseApp.app() != nil
        #else
            false
        #endif
    }
}
