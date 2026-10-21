//
//  WalletData.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 10/7/26.
//

import Foundation
import Combine
import Network
import SwiftUI

// MARK: Public data models

/// Wallet data model - only created when data is valid
/// If parsing fails, parsers return nil instead of creating invalid WalletData
public struct WalletData: Sendable {
    /// Total equity value (in currency units, e.g., USDT)
    public let totalEquity: Double
    /// Wallet balance (in currency units, e.g., USDT)
    public let walletBalance: Double
    /// Absolute maintenance margin value (in currency units, e.g., USDT)
    /// Value of 0 means no maintenance margin or not applicable (e.g., spot accounts)
    public let maintenanceMargin: Double
    
    public init(totalEquity: Double, walletBalance: Double, maintenanceMargin: Double = 0) {
        self.totalEquity = totalEquity
        self.walletBalance = walletBalance
        self.maintenanceMargin = max(0, maintenanceMargin) // Ensure non-negative
    }
    
    /// Calculates the maintenance margin as a percentage of total equity
    /// Returns 0 if total equity is zero (avoids division by zero)
    /// Formula: (maintenanceMargin / totalEquity) × 100
    public var maintenanceMarginPercentage: Double {
        guard totalEquity > 0 else {
            return 0
        }
        return (maintenanceMargin / totalEquity) * 100.0
    }
    
    /// Returns the maintenance margin percentage formatted as a string with specified decimal places
    /// - Parameter decimalPlaces: Number of decimal places (default: 2)
    /// - Returns: Formatted percentage string (e.g., "5.00%")
    public func maintenanceMarginPercentageFormatted(decimalPlaces: Int = 2) -> String {
        return String(format: "%.\(decimalPlaces)f%%", maintenanceMarginPercentage)
    }
}
