//
//  SiriManager.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 15/09/2026.
//

import Foundation
import AppIntents

#if !os(macOS)
@MainActor
final class SiriManager: Sendable {
    static let shared = SiriManager()
    
    enum SetupResult: Equatable {
        case success
        case failure(String)
    }
    
    private init() {}
    
    @discardableResult
    func setupModernSiri() async -> SetupResult {
        BalanceShortcutsProvider.updateAppShortcutParameters()
        
        do {
            let intent = GetBalanceIntent()
            try await intent.donate()
            
            AppLog.siri.info("Siri App Shortcut parameters updated and GetBalanceIntent donated successfully")
            Task.detached {
                await AnalyticsManager.shared.track(.other(msg: "siri_shortcut_setup_success"))
            }
            return .success
        } catch {
            let errorMsg = error.localizedDescription
            AppLog.siri.error("Failed to donate GetBalanceIntent: \(errorMsg)")
            Task.detached {
                await AnalyticsManager.shared.track(.unexpectedError(context: "siri_setup", description: errorMsg))
            }
            return .failure(errorMsg)
        }
    }
}
#endif
