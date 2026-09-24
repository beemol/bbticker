//
//  BackgroundTaskManager.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 03/07/2025.
//

import Foundation
import BackgroundTasks

import LLApiService

#if !os(macOS)

@MainActor
class BackgroundTaskManager: ObservableObject {
    private let backgroundTaskIdentifier = getBundleIdentifier() + ".background-fetch"
    
    @Published var lastBackgroundFetch: Date?
    @Published var backgroundFetchCount: Int = 0
    
    private let apiService: APIServiceProtocol
    private let notificationService: NotificationService
    
    init(apiService: APIServiceProtocol, notificationService: NotificationService = .shared) {
        self.apiService = apiService
        self.notificationService = notificationService
        
        registerBackgroundTasks()
    }
    
    func registerBackgroundTasks() {
        let registered = BGTaskScheduler.shared.register(
            forTaskWithIdentifier: backgroundTaskIdentifier,
            using: .main
        ) { [weak self] task in
            guard let self = self, let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            self.handleBackgroundFetch(task: refreshTask)
        }
        AppLog.background.info("Registered BGTask '\(self.backgroundTaskIdentifier)': \(registered)")
    }
    
    func scheduleBackgroundTasks() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60) // 1 hour
        
        do {
            try BGTaskScheduler.shared.submit(request)
            AppLog.background.info("Successfully submitted BGTask '\(self.backgroundTaskIdentifier)' with earliestBeginDate in 1 hour")
        } catch {
            AppLog.background.error("Could not schedule background fetch: \(error)")
        }
    }
    
    private func handleBackgroundFetch(task: BGAppRefreshTask) {
        AppLog.background.info("BGTaskScheduler fired task '\(self.backgroundTaskIdentifier)'")
        
        // Schedule the next background fetch
        scheduleBackgroundTasks()
        
        var fetchTask: Task<Void, Never>?
        
        // Set up task expiration immediately and synchronously
        task.expirationHandler = {
            AppLog.background.warning("BGTask expired before completing")
            fetchTask?.cancel()
            task.setTaskCompleted(success: false)
        }
        
        // Perform the background fetch on MainActor
        fetchTask = Task { @MainActor in
            let success = await self.performBackgroundDataFetch()
            self.lastBackgroundFetch = Date()
            self.backgroundFetchCount += 1
            task.setTaskCompleted(success: success)
        }
    }
    
    private func performBackgroundDataFetch() async -> Bool {
        do {
            let walletData = try await apiService.fetchWalletBalanceForCurrentExchange()
            
            // Store the data for when app becomes active
            UserDefaults.standard.set(walletData.totalEquity, forKey: "background_total_equity")
            UserDefaults.standard.set(walletData.walletBalance, forKey: "background_wallet_balance")
            UserDefaults.standard.set(Date(), forKey: "background_last_update")
            
            // Notify the user with the fresh balance, if enabled in Settings
            let notificationsEnabled = UserDefaults.standard.bool(forKey: SettingsService.StorageKey.balanceNotificationsEnabled)
            if notificationsEnabled {
                AppLog.background.info("Notifications enabled; posting balance notification for equity: \(walletData.totalEquity)")
                notificationService.postBalanceNotification(totalEquity: walletData.totalEquity)
            } else {
                AppLog.background.info("Balance notifications toggle is OFF; skipping notification")
            }
            
            AppLog.background.info("Updated -> Total Equity: \(walletData.totalEquity), Wallet Balance (USDT): \(walletData.walletBalance)")
            return true
        } catch {
            AppLog.background.error("Background API Error: \(error.localizedDescription)")
            return false
        }
    }
    
    func getSavedBackgroundData() -> (totalEquity: String, walletBalance: String, lastUpdate: Date?)? {
        guard let totalEquity = UserDefaults.standard.string(forKey: "background_total_equity"),
              let walletBalance = UserDefaults.standard.string(forKey: "background_wallet_balance"),
              let lastUpdate = UserDefaults.standard.object(forKey: "background_last_update") as? Date else {
            return nil
        }
        
        return (totalEquity, walletBalance, lastUpdate)
    }
}

#endif
