import WidgetKit
import SwiftUI

struct BybitWidgetEntry: TimelineEntry {
    let date: Date
    let totalEquity: String
    let walletBalance: String
    let connectionStatus: String
    let lastUpdate: Date
    
    init(date: Date, totalEquity: String, walletBalance: String, connectionStatus: String, lastUpdate: Date) {
        self.date = date
        self.totalEquity = totalEquity
        self.walletBalance = walletBalance
        self.connectionStatus = connectionStatus
        self.lastUpdate = lastUpdate
    }
} 