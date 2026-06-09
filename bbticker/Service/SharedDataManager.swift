import Foundation
import WidgetKit

@MainActor
protocol SharedDataManagerProtocol {
    func updateWidgetData(totalEquity: String, walletBalance: String, connectionStatus: String)
    func setWidgetEnabled(_ enabled: Bool)
    func isWidgetEnabled() -> Bool
    func setWidgetRefreshInterval(_ interval: Double)
    func getWidgetRefreshInterval() -> Double
}

class SharedDataManager: SharedDataManagerProtocol {
    static let shared = SharedDataManager()
    
    private let sharedDefaults: UserDefaults?
    private var lastWidgetUpdate: Date = Date.distantPast
    private let minimumUpdateInterval: TimeInterval = 30.0 // 30 seconds minimum between updates
    
    private init() {
        self.sharedDefaults = UserDefaults(suiteName: "group.com.\(getAppName()).widget")
    }
    
    // MARK: - Widget Data Management
    
    func updateWidgetData(totalEquity: String, walletBalance: String, connectionStatus: String) {
        let now = Date()
        
        // Check if enough time has passed since last update
        if now.timeIntervalSince(lastWidgetUpdate) < minimumUpdateInterval {
            // Just update the data without triggering widget refresh
            sharedDefaults?.set(totalEquity, forKey: "widget_total_equity")
            sharedDefaults?.set(walletBalance, forKey: "widget_wallet_balance")
            sharedDefaults?.set(connectionStatus, forKey: "widget_connection_status")
            sharedDefaults?.set(now, forKey: "widget_last_update")
            return
        }
        
        // Update data and trigger widget refresh
        sharedDefaults?.set(totalEquity, forKey: "widget_total_equity")
        sharedDefaults?.set(walletBalance, forKey: "widget_wallet_balance")
        sharedDefaults?.set(connectionStatus, forKey: "widget_connection_status")
        sharedDefaults?.set(now, forKey: "widget_last_update")
        
        lastWidgetUpdate = now
        
        // Trigger widget refresh
        #if !os(macOS)
        WidgetCenter.shared.reloadTimelines(ofKind: "BybitWidget")
        #endif
        
        //print("[Widget] Updated data - Total Equity: \(totalEquity), Wallet Balance: \(walletBalance), Status: \(connectionStatus)")
    }
    
    func getWidgetData() -> (totalEquity: String, walletBalance: String, connectionStatus: String, lastUpdate: Date?)? {
        guard let totalEquity = sharedDefaults?.string(forKey: "widget_total_equity"),
              let walletBalance = sharedDefaults?.string(forKey: "widget_wallet_balance"),
              let connectionStatus = sharedDefaults?.string(forKey: "widget_connection_status") else {
            return nil
        }
        
        let lastUpdate = sharedDefaults?.object(forKey: "widget_last_update") as? Date
        
        return (totalEquity, walletBalance, connectionStatus, lastUpdate)
    }
    
    func clearWidgetData() {
        sharedDefaults?.removeObject(forKey: "widget_total_equity")
        sharedDefaults?.removeObject(forKey: "widget_wallet_balance")
        sharedDefaults?.removeObject(forKey: "widget_connection_status")
        sharedDefaults?.removeObject(forKey: "widget_last_update")
        
        // print("[Widget] Cleared widget data")
    }
    
    // MARK: - Widget Configuration
    
    func setWidgetEnabled(_ enabled: Bool) {
        sharedDefaults?.set(enabled, forKey: "widget_enabled")
    }
    
    func isWidgetEnabled() -> Bool {
        return sharedDefaults?.bool(forKey: "widget_enabled") ?? false
    }
    
    func setWidgetRefreshInterval(_ minutes: Double) {
        sharedDefaults?.set(minutes, forKey: "widget_refresh_interval")
    }
    
    func getWidgetRefreshInterval() -> Double {
        return sharedDefaults?.double(forKey: "widget_refresh_interval") ?? 5.0
    }
} 
