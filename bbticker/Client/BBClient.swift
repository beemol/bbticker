//
//  BBClient.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 03/07/2025.
//

import Foundation
import Combine
import Network
import SwiftUI
import LLCore

/*
 GET /v5/account/wallet-balance?accountType=UNIFIED&coin=BTC HTTP/1.1
 Host: api-testnet.bybit.com
 X-BAPI-SIGN: XXXXX
 X-BAPI-API-KEY: xxxxxxxxxxxxxxxxxx
 X-BAPI-TIMESTAMP: 1672125440406
 X-BAPI-RECV-WINDOW: 5000
*/

@MainActor
class BBClient: ObservableObject {
    
    @StaleTracked<WalletState>(wrappedValue: WalletState(), stale: true)
    var walletState: WalletState
    
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var authenticationError: String?

    // MARK: - Dependencies (Testable)
    private var settingsService: any SettingsServiceProtocol
    private let networkMonitor: any NetworkStoreProtocol
    private let sharedDataManager: SharedDataManagerProtocol
    
    private let walletRepository: WalletRepositoryProtocol
    
    // MARK: - Internal State
    private var pollingStrategy: PollingStrategy<WalletData>?
    private var pollingConfiguration: PollingConfiguration
    
    // MARK: - Initialization
    init(
        settingsService: any SettingsServiceProtocol,
        networkMonitor: any NetworkStoreProtocol,
        sharedDataManager: SharedDataManagerProtocol,
        pollingConfiguration: PollingConfiguration = .default,
        walletRepository: WalletRepositoryProtocol
    ) {
        self.settingsService = settingsService
        self.networkMonitor = networkMonitor
        self.sharedDataManager = sharedDataManager
        
        self.pollingConfiguration = pollingConfiguration
        
        self.walletRepository = walletRepository
        
        setupNetworkMonitoring()
    }
    
    // keep for tests
    var isConnected: Bool {
        return connectionStatus == .connected
    }
    
    // Expose network state for UI components
    var isNetworkConnected: Bool {
        return networkMonitor.state.isConnected
    }
    
    private var currentExchangeType: ExchangeType {
        return settingsService.state.exchangeType
    }
    
    // MARK: - Connection Management
    func connect() async {
        await AnalyticsManager.shared.track(.connectionAttempt)
        connectionStatus = .connecting
        
        do {
            let walletData = try await walletRepository.getWalletData(for: currentExchangeType)
            setupPollingStrategy(with: self.settingsService.state.updateFrequency)
            handleSuccessfulConnection(with: walletData)
        } catch {
            applyErrorAndDisconnectIfNeeded(error)
        }
    }

    func disconnect() {
        Task {
            await AnalyticsManager.shared.track(.disconnection(error: "none"))
        }
        
        pollingStrategy?.stop()
        
        setDisconnectedState()
    }
    
    deinit {
        networkTask?.cancel()
    }
    
    // MARK: - Private Methods
    
    private func setupPollingStrategy(with updateFrequency: Double) {
        pollingStrategy?.stop()
        pollingStrategy = .init(frequencyProvider: { [weak self] in
            return self?.settingsService.state.updateFrequency ?? 1.0
        },
                                shouldContinue: { [weak self] in
            self?.connectionStatus == .connected
        },
                                fetchHandler: { [weak self] in
            guard let self = self else { throw NSError(domain: "TestError", code: 500, userInfo: nil) }
            
            return try await self.walletRepository.getWalletData(for: currentExchangeType)
        }, updateHandler: { [weak self] walletData in
            self?.applyWalletData(walletData)
        }, errorHandler: { [weak self] error in
            self?.applyErrorAndDisconnectIfNeeded(error) ?? .stopPolling
        }, config: self.pollingConfiguration)
    }
    
    // applies wallet data to published properties, sets values + widget
    private func applyWalletData(_ walletData: WalletData) {
        let newWalletState = WalletState(equity: walletData.totalEquity,
                                         balance: walletData.walletBalance,
                                         maintenanceMarginPercentage: walletData.maintenanceMarginPercentage)
        walletState = newWalletState
        
        authenticationError = nil
        
        // Update widget data
        sharedDataManager.updateWidgetData(
            totalEquity: String(walletData.totalEquity),
            walletBalance: String(walletData.walletBalance),
            connectionStatus: "Connected"
        )
    }

    
    // normalizes message, setDisconnectedState, stopPolling, and optionally reconnect
    @discardableResult
    private func applyErrorAndDisconnectIfNeeded(_ error: Error) -> PollingStrategyAction {
        print("[BBClient] applyErrorAndDisconnectIfNeeded called with error: \(error)")
        
        if let apiError = error as? APIDomainError, case .network = apiError {
            //print("Network error detected: \(apiError)")
            authenticationError = apiError.userMessage
            return .continuePolling
        } else if let apiError = error as? APIDomainError, case .unknown = apiError {
            //print("Unknown error detected (max attempts): \(apiError)")
            setDisconnectedState(errorMessage: "Polling Error: \(error.localizedDescription)")
            return .stopPolling
        } else {
            //print("Other API error detected: \(error)")
            setDisconnectedState(errorMessage: "API Error: \(error.localizedDescription)")
            return .stopPolling
        }
    }
    
    private func handleSuccessfulConnection(with walletData: WalletData) {
        print("[BBClient] connection successful -> Total Equity: \(walletData.totalEquity), Wallet Balance (USDT): \(walletData.walletBalance)")
        
        Task {
            await AnalyticsManager.shared.track(.connectionSuccess)
        }
        
        connectionStatus = .connected
        
        applyWalletData(walletData)
        
        // Only start polling AFTER successful connection
        pollingStrategy?.start()
    }
    
    private func setDisconnectedState(errorMessage: String? = nil) {
        print("[BBClient]  setDisconnectedState \(errorMessage ?? "no data")")
        connectionStatus = .disconnected
        authenticationError = errorMessage
        
        // reset state
        $walletState.markStale()
        //walletState.reset()
        
        // Track connection loss if there was an error
        if let error = errorMessage {
            Task {
                await AnalyticsManager.shared.track(.disconnection(error: error))
            }
        }
        
        // Update widget data
        sharedDataManager.updateWidgetData(
            totalEquity: "n/a",
            walletBalance: "n/a",
            connectionStatus: "Disconnected"
        )
    }
    
    private var networkTask: Task<Void, Never>?
    
    private func setupNetworkMonitoring() {
        networkTask = Task { [weak self] in
            guard let self = self else { return }
            
            for await isConnected in self.networkMonitor.statusStream {
                if isConnected {
                    self.onNetworkRestored()
                } else {
                    self.onNetworkLost()
                }
            }
        }
    }
    
    // MARK: - Network Event Handlers

    private func onNetworkLost() {
        pollingStrategy?.stop()
        setDisconnectedState(errorMessage: "Network connection lost")
    }
    
    private func onNetworkRestored() {
        guard !isConnected else { return }
        
        Task { [weak self] in
            await self?.connect()
        }
    }
}
