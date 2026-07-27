//
//  NetworkStore.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 20/04/2026.
//

import SwiftUI
import Combine
import Network

@MainActor
protocol NetworkStoreProtocol {
    var statusStream: AsyncStream<Bool> { get }
    var state: NetworkState { get }
}

@Observable
final class NetworkStore: NetworkStoreProtocol {
    let statusStream: AsyncStream<Bool>
    
    // UDF section
    private(set) var state = NetworkState()
    private let reducer: (NetworkState, NetworkAction) -> (NetworkState, NetworkEffect?) = NetworkReducer.reduce
    
    // Internal network monitor
    private let reachability: InternetReachabilityServiceProtocol
    private let pathMonitor: PathMonitorProtocol
    private var statusContinuation: AsyncStream<Bool>.Continuation?
    private let monitoringEngine: MonitoringEngineProtocol
    
    private var monitoringTask: Task<Void, Never>?
    
    @MainActor
    init(reachability: InternetReachabilityServiceProtocol = InternetReachabilityService(),
         pathMonitor: PathMonitorProtocol = ProductionPathMonitor())
    {
        
        self.reachability = reachability
        self.pathMonitor = pathMonitor
        self.monitoringEngine = MonitoringEngine(reachability: reachability, pathMonitor: pathMonitor)
        
        let (stream, continuation) = AsyncStream<Bool>.makeStream()
        statusStream = stream
        statusContinuation = continuation
        
        Task {
            await dispatch(.startMonitoring)
        }
    }
    
    // for tests usage only
    @MainActor
    internal init(monitoringEngine: MonitoringEngineProtocol, startMonitoring: Bool) {
        let (stream, continuation) = AsyncStream<Bool>.makeStream()
        statusStream = stream
        statusContinuation = continuation

        reachability = InternetReachabilityService()
        pathMonitor = ProductionPathMonitor()
        
        self.monitoringEngine = monitoringEngine
        
        if startMonitoring {
            Task {
                await dispatch(.startMonitoring)
            }
        } else {
            // push initial state to prevent tests from hanging
            statusContinuation?.yield(state.isConnected)
        }
    }

    @MainActor
    deinit {
        statusContinuation?.finish()
        monitoringEngine.stop()
    }
    
    @MainActor
    func dispatch(_ action: NetworkAction) async {
        let (newState, effect) = reducer(state, action)
        state = newState
        
        statusContinuation?.yield(newState.isConnected)
        
        switch effect {
        case .startMonitoring:
            monitoringTask?.cancel()
            monitoringTask = nil
            
            monitoringTask = Task { [weak self] in
                guard let self else { return }
                
                let stream = monitoringEngine.start()
                for await action in stream {
                    await dispatch(action)
                }
            }
        case .stopMonitoring:
            monitoringTask?.cancel()
            monitoringTask = nil
            
            monitoringEngine.stop()
        case nil: break
        }
    }
}

enum InternetStatus: Equatable { case unavailable, checking, reachable, unreachable }

struct NetworkState {
    var internetStatus: InternetStatus = .unavailable
    var isConnected: Bool = false
    var connectionType: NetworkStore.ConnectionType = .unknown
    
    var isInternetReachable: Bool { internetStatus == .reachable }
}

enum NetworkAction: Equatable {
    case statusChanged(Bool)
    case connectionTypeChanged(NetworkStore.ConnectionType)
    case startMonitoring
    case stopMonitoring
}

enum NetworkEffect {
    case startMonitoring
    case stopMonitoring
}

enum NetworkReducer {
    static func reduce(_ state: NetworkState, _ action: NetworkAction) -> (NetworkState, NetworkEffect?) {
        var newState = state
        
        switch action {
        case .statusChanged(let connected):
            newState.isConnected = connected
            return (newState, nil)
        case .connectionTypeChanged(let type):
            newState.connectionType = type
            return (newState, nil)
        case .startMonitoring:
            return (newState, .startMonitoring)
        // not really needed
        case .stopMonitoring:
            return (newState, .stopMonitoring)
        }
    }
}

extension NetworkStore {
    enum ConnectionType: String {
        case wifi = "WiFi"
        case cellular = "Cellular"
        case ethernet = "Ethernet"
        case unknown = "Unknown"
        
        var imageName: String {
            switch self {
            case .wifi: "wifi"
            case .cellular: "cellularbar"
            case .ethernet: "network"
            default: "wifi"
            }
        }
    }
    
    // MARK: - Test Compatibility Methods
    // These methods provide the same API as the old NetworkMonitor for existing tests
    
    /// Simulates network loss for testing - maintains compatibility with existing tests
    @MainActor
    func simulateNetworkLoss() async {
        await dispatch(.statusChanged(false))
    }
    
    /// Simulates network restoration for testing - maintains compatibility with existing tests
    @MainActor
    func simulateNetworkRestoration() async {
        await dispatch(.statusChanged(true))
    }
    
    /// Simulates network change to specific state - maintains compatibility with existing tests
    @MainActor
    func simulateNetworkChange(isConnected: Bool) async {
        await dispatch(.statusChanged(isConnected))
    }
}
