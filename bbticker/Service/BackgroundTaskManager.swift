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

class BackgroundTaskManager: ObservableObject {
    private let backgroundTaskIdentifier = getBundleIdentifier() + ".background-fetch"
    
    @Published var lastBackgroundFetch: Date?
    @Published var backgroundFetchCount: Int = 0
    
    private let apiService: APIServiceProtocol
    
    init(apiService: APIServiceProtocol) {
        self.apiService = apiService
        
        registerBackgroundTasks()
    }
    
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil) { task in
            self.handleBackgroundFetch(task: task as! BGAppRefreshTask)
        }
    }
    
    func scheduleBackgroundTasks() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes minimum
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background fetch scheduled successfully")
        } catch {
            print("Could not schedule background fetch: \(error)")
        }
    }
    
    private func handleBackgroundFetch(task: BGAppRefreshTask) {
        print("Background fetch started")
        
        // Schedule the next background fetch
        scheduleBackgroundTasks()
        
        // Set up task expiration
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // Perform the background fetch
        performBackgroundDataFetch { success in
            DispatchQueue.main.async {
                self.lastBackgroundFetch = Date()
                self.backgroundFetchCount += 1
            }
            task.setTaskCompleted(success: success)
        }
    }
    
    private func performBackgroundDataFetch(completion: @escaping (Bool) -> Void) {
        fetchBalanceInBackground() { success in
            completion(success)
        }
    }
    
    private func fetchBalanceInBackground(completion: @escaping (Bool) -> Void) {
        Task {
            do {
                let walletData = try await apiService.fetchWalletBalanceForCurrentExchange()
                
                // Store the data for when app becomes active
                UserDefaults.standard.set(walletData.totalEquity, forKey: "background_total_equity")
                UserDefaults.standard.set(walletData.walletBalance, forKey: "background_wallet_balance")
                UserDefaults.standard.set(Date(), forKey: "background_last_update")
                
                print("[Background] Updated -> Total Equity: \(walletData.totalEquity), Wallet Balance (USDT): \(walletData.walletBalance)")
                completion(true)
            } catch {
                print("Background API Error: \(error.localizedDescription)")
                completion(false)
            }
        }
    }
    
    func getBackgroundData() -> (totalEquity: String, walletBalance: String, lastUpdate: Date?)? {
        guard let totalEquity = UserDefaults.standard.string(forKey: "background_total_equity"),
              let walletBalance = UserDefaults.standard.string(forKey: "background_wallet_balance"),
              let lastUpdate = UserDefaults.standard.object(forKey: "background_last_update") as? Date else {
            return nil
        }
        
        return (totalEquity, walletBalance, lastUpdate)
    }
}

#endif
