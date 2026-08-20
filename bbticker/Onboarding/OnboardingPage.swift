//
//  OnboardingPage.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 20/08/2026.
//

import SwiftUI

/// The five pages of the first-run tutorial, in order.
enum OnboardingPage: Int, CaseIterable, Identifiable {
    case welcome, features, security, setup, getStarted

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .welcome:    "Your crypto portfolio at a glance"
        case .features:   "Everything you need to watch your risk"
        case .security:   "Read-only access. Always."
        case .setup:      "Create your read-only API key"
        case .getStarted: "You're ready to go"
        }
    }

    var subtitle: String {
        switch self {
        case .welcome:    "BBTicker shows your Bybit balance right in the menu bar — no browser needed."
        case .features:   "Live equity, margin risk dot, secure Keychain storage, and more."
        case .security:   "Keys are stored encrypted in the macOS Keychain and can never trade or withdraw."
        case .setup:      "On bybit.com go to Account → API Management and create a read-only wallet key."
        case .getStarted: "Open Settings to paste your API key and secret. That's it."
        }
    }

    var systemImage: String {
        switch self {
        case .welcome:    "chart.line.uptrend.xyaxis"
        case .features:   "square.grid.2x2"
        case .security:   "lock.shield"
        case .setup:      "key"
        case .getStarted: "checkmark.circle"
        }
    }

    var accentColor: Color {
        switch self {
        case .welcome:    .green
        case .features:   .orange
        case .security:   .blue
        case .setup:      .purple
        case .getStarted: .green
        }
    }
}
