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
    
    @MainActor
    init(reachability: InternetReachabilityServiceProtocol = InternetReachabilityService(),
         pathMonitor: PathMonitorProtocol = ProductionPathMonitor())
    {
        
        self.reachability = reachability
        self.pathMonitor = pathMonitor
        
        let (stream, continuation) = AsyncStream<Bool>.makeStream()
        statusStream = stream
        statusContinuation = continuation
        
        Task {
            await dispatch(.startMonitoring)
        }
    }
    
    // for tests usage only
    @MainActor
    internal init(startMonitoring: Bool) {
        let (stream, continuation) = AsyncStream<Bool>.makeStream()
        statusStream = stream
        statusContinuation = continuation

        reachability = InternetReachabilityService()
        pathMonitor = ProductionPathMonitor()
        
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
        reachability.stop()
        pathMonitor.cancel()
    }
    
    @MainActor
    func dispatch(_ action: NetworkAction) async {
        let (newState, effect) = reducer(state, action)
        state = newState
        
        statusContinuation?.yield(newState.isConnected)
        
        if let effect = effect, case let .execute(effectClosure) = effect {
            if let stream = effectClosure(pathMonitor, reachability) {
                for await action in stream {
                    await dispatch(action)
                }
            }
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
    case execute((_ pathMonitor: PathMonitorProtocol, _ rechabilityService: InternetReachabilityServiceProtocol) -> AsyncStream<NetworkAction>?)
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
            return (newState, .execute(makeMonitoringStream))
        // not really needed
        case .stopMonitoring:
            return (newState, .execute({ monitor, rechabilityService in
                stopMonitoring(monitor: monitor, reachability: rechabilityService)
                return nil
            }))
        }
    }
}

private extension NetworkReducer {
    static func makeMonitoringStream(monitor: PathMonitorProtocol,
                                     reachability: InternetReachabilityServiceProtocol) -> AsyncStream<NetworkAction> {
        return AsyncStream<NetworkAction> { continuation in
            monitor.pathUpdateHandler = { path in
                handlePathUpdate(path, continuation: continuation, reachability: reachability)
            }
            monitor.start(queue: DispatchQueue(label: "NetworkStore"))

            continuation.onTermination = { _ in
                stopMonitoring(monitor: monitor, reachability: reachability)
            }
        }
    }
    
    static func handlePathUpdate(_ path: NetworkPathWrapper,
                                 continuation: AsyncStream<NetworkAction>.Continuation,
                                 reachability: InternetReachabilityServiceProtocol) {
        Task { @MainActor in
            reachability.stop()
            
            guard path.status == .satisfied, let reachabilityStream = try? reachability.run() else {
                continuation.yield(.statusChanged(false))
                return
            }
            
            for await reachability in reachabilityStream {
                continuation.yield(.statusChanged(reachability))
            }
        }
    }
    
    static func stopMonitoring(monitor: PathMonitorProtocol, reachability: InternetReachabilityServiceProtocol) {
        Task { @MainActor in
            reachability.stop()
            monitor.cancel()
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
