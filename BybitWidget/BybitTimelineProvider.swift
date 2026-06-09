import WidgetKit
import SwiftUI

struct BybitTimelineProvider: TimelineProvider {
    typealias Entry = BybitWidgetEntry
    
    func placeholder(in context: Context) -> BybitWidgetEntry {
        BybitWidgetEntry(
            date: Date(),
            totalEquity: formatCurrencyValue("0.00"),
            walletBalance: formatCurrencyValue("0.00"),
            connectionStatus: "Disconnected",
            lastUpdate: Date()
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (BybitWidgetEntry) -> ()) {
        let entry = BybitWidgetEntry(
            date: Date(),
            totalEquity: formatCurrencyValue("1234.56"),
            walletBalance: formatCurrencyValue("789.01"),
            connectionStatus: "Connected",
            lastUpdate: Date()
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<BybitWidgetEntry>) -> ()) {
        // Get data from shared container
        let sharedDefaults = UserDefaults(suiteName: "group.com.bbticker.widget")
        
        let rawTotalEquity = sharedDefaults?.string(forKey: "widget_total_equity") ?? "0.00"
        let rawWalletBalance = sharedDefaults?.string(forKey: "widget_wallet_balance") ?? "0.00"
        let connectionStatus = sharedDefaults?.string(forKey: "widget_connection_status") ?? "Disconnected"
        let lastUpdate = sharedDefaults?.object(forKey: "widget_last_update") as? Date ?? Date()
        
        // Format values with 2 decimal places
        let totalEquity = formatCurrencyValue(rawTotalEquity)
        let walletBalance = formatCurrencyValue(rawWalletBalance)
        
        let entry = BybitWidgetEntry(
            date: Date(),
            totalEquity: totalEquity,
            walletBalance: walletBalance,
            connectionStatus: connectionStatus,
            lastUpdate: lastUpdate
        )
        
        // Update every 30 seconds
        let nextUpdate = Calendar.current.date(byAdding: .second, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
    
    private func formatCurrencyValue(_ value: String) -> String {
        if let doubleValue = Double(value) {
            return String(format: "%.2f", doubleValue)
        }
        return value
    }
} 