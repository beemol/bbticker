//
//  AppLog.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 09/08/2026.
//

import Foundation
import os

enum AppLog {
    private static let subsystem = getBundleIdentifier()

    static let api          = Logger(subsystem: subsystem, category: "API")
    static let client       = Logger(subsystem: subsystem, category: "Client")
    static let websocket    = Logger(subsystem: subsystem, category: "WebSocket")
    static let keychain     = Logger(subsystem: subsystem, category: "Keychain")
    static let settings     = Logger(subsystem: subsystem, category: "Settings")
    static let iap          = Logger(subsystem: subsystem, category: "IAP")
    static let remoteConfig = Logger(subsystem: subsystem, category: "RemoteConfig")
    static let donation     = Logger(subsystem: subsystem, category: "Donation")
    static let service      = Logger(subsystem: subsystem, category: "Service")
    static let background   = Logger(subsystem: subsystem, category: "Background")
    static let siri         = Logger(subsystem: subsystem, category: "Siri")
}
