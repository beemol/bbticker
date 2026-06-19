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
    
    private let reconnectionDelayInSec: Double
    
    // MARK: - Internal State
    private var pollingStrategy: PollingStrategy<WalletData>?
    private var pollingConfiguration: PollingConfiguration
    
    // MARK: - Initialization
    init(
        settingsService: any SettingsServiceProtocol,
        networkMonitor: any NetworkStoreProtocol,
        sharedDataManager: SharedDataManagerProtocol,
        pollingConfiguration: PollingConfiguration = .default,
        walletRepository: WalletRepositoryProtocol,
        reconnectionDelayInSec: Double = 30
    ) {
        self.settingsService = settingsService
        self.networkMonitor = networkMonitor
        self.sharedDataManager = sharedDataManager
        self.pollingConfiguration = pollingConfiguration
        self.walletRepository = walletRepository
        self.reconnectionDelayInSec = reconnectionDelayInSec
        
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
        
        if connectionStatus != .connected {
            connectionStatus = .connecting
        }
        
        do {
            let walletData = try await walletRepository.getWalletData(for: currentExchangeType)
            setupPollingStrategy(with: self.settingsService.state.updateFrequency)
            handleSuccessfulConnection(with: walletData)
        } catch {
            handleConnectError(error)
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
    
    private func isPermanentConnectError(_ error: Error) -> Bool {
        guard let apiError = error as? APIDomainError else {
            return true  // unknown error type - treat as fatal
        }
        
        switch apiError {
        case .network, .unknown:
            return false   // transient — retry later
        default:
            return true    // invalidCredentials, rateLimited, server, etc.
        }
    }
    
    private func transientErrorMessage(for error: Error) -> String {
        if let apiError = error as? APIDomainError, case .network = apiError {
            return apiError.userMessage
        }
        
        if let apiError = error as? APIDomainError, case .unknown = apiError {
            return "Polling Error: \(error.localizedDescription)"
        }
        
        return error.localizedDescription
    }
    
    private var reconnectTask: Task<Void, Never>?
    
    private func scheduleReconnect() {
        reconnectTask?.cancel()
        
        reconnectTask = Task { [weak self] in
            guard let self else { return }
            
            try? await Task.sleep(for: .seconds(self.reconnectionDelayInSec))
            
            guard !Task.isCancelled else { return }
            
            await self.connect()
        }
    }
    
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
            self?.handlePollingError(error) ?? .stopPolling
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

    func handlePollingError(_ error: Error) -> PollingStrategyAction {
        print("[BBClient] handlePollingError called with error: \(error)")
        
        if let apiError = error as? APIDomainError, case .network = apiError {
            authenticationError = apiError.userMessage
            $walletState.markStale()
            return .continuePolling
        } else if let apiError = error as? APIDomainError, case .unknown = apiError {
            authenticationError = "Polling Error: \(error.localizedDescription)"
            $walletState.markStale()
            pollingStrategy?.stop()
            
            scheduleReconnect()
            
            return .stopPolling
        } else {
            setDisconnectedState(errorMessage: "API Error: \(error.localizedDescription)")
            return .stopPolling
        }
    }
    
    func handleConnectError(_ error: Error) {
        print("[BBClient] handleConnectError: \(error), status: \(connectionStatus)")
        
        // Permanent failure — always end session
        if isPermanentConnectError(error) {
            setDisconnectedState(errorMessage: "API Error: \(error.localizedDescription)")
            return
        }
        
        // Active session — keep connected and retry later
        if connectionStatus == .connected {
            authenticationError = transientErrorMessage(for: error)
            $walletState.markStale()
            scheduleReconnect()
            return
        }
        
        // .connecting or .disconnected — no established session (includes onNetworkLost
        // resetting status during an in-flight first connect())
        setDisconnectedState(errorMessage: transientErrorMessage(for: error))
    }
    
    // normalizes message, setDisconnectedState, stopPolling, and optionally reconnect
    @discardableResult
    private func applyErrorAndDisconnectIfNeeded(_ error: Error) -> PollingStrategyAction {
        print("[BBClient] applyErrorAndDisconnectIfNeeded called with error: \(error)")
        
        if let apiError = error as? APIDomainError, case .network = apiError {
            authenticationError = apiError.userMessage
            $walletState.markStale()
            return .continuePolling
        } else if let apiError = error as? APIDomainError, case .unknown = apiError {
            authenticationError = "Polling Error: \(error.localizedDescription)"
            $walletState.markStale()
            pollingStrategy?.stop()
            
            // wait and try to reconnect
            Task {
                try? await Task.sleep(for: .seconds(self.reconnectionDelayInSec))
                await connect()
            }
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
        
        $walletState.markStale()
        
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
