//
//  WalletState.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 01/12/2025.
//

import Foundation
import LLCore

@Observable
final class WalletState {
    var equity: Double
    var balance: Double
    var maintenanceMarginPercentage: Double
    
    init(equity: Double = 0,
         balance: Double = 0,
         maintenanceMarginPercentage: Double = 0) {
        self.equity = equity
        self.balance = balance
        self.maintenanceMarginPercentage = maintenanceMarginPercentage
    }
    
    @available(*, deprecated, message: "deprecated. rely on staleness of data")
    func reset() {
        equity = 0
        balance = 0
        maintenanceMarginPercentage = 0
    }
}

import SwiftUI

extension WalletState {
    // MARK: - Maintenance Margin Helper
    /// Returns color based on maintenance margin level
    /// - Red when MM is above 50% of total equity (high risk)
    /// - Yellow when MM is between 30-50% (warning)
    /// - Green when MM is below 30% (safe)
    /// - Gray when disconnected or data unavailable
    var maintenanceMarginColor: Color {
        // Color coding based on risk level
        if maintenanceMarginPercentage >= 70.0 {
            return .red      // High risk - approaching liquidation
        } else if maintenanceMarginPercentage >= 50.0 {
            return .yellow   // Warning - monitor closely
        } else {
            return .green    // Safe - healthy margin level
        }
    }
}
