//
//  NetworkStore.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 20/04/2026.
//

import SwiftUI
import Combine
import Network

//extension NWPathMonitor: PathMonitorProtocol {
//}

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
    private let pathMonitor: ProductionPathMonitor = ProductionPathMonitor()
    private var statusContinuation: AsyncStream<Bool>.Continuation?
    
    @MainActor
    init() {
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
    }
    
    @MainActor
    func dispatch(_ action: NetworkAction) async {
        let (newState, effect) = reducer(state, action)
        state = newState
        
        statusContinuation?.yield(newState.isConnected)
        
        if let effect = effect, case let .execute(effectClosure) = effect {
            if let stream = effectClosure(pathMonitor) {
                for await action in stream {
                    await dispatch(action)
                }
            }
        }
    }
}


struct NetworkState {
    var isConnected: Bool = false
    var connectionType: NetworkStore.ConnectionType = .unknown
}

enum NetworkAction: Equatable {
    case statusChanged(Bool)
    case connectionTypeChanged(NetworkStore.ConnectionType)
    case startMonitoring
    case stopMonitioring
}

enum NetworkEffect {
    case execute((_ pathMonitor: ProductionPathMonitor) -> AsyncStream<NetworkAction>?)
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
            return (newState, .execute({ monitor in
                
                return AsyncStream<NetworkAction> { continuation in
                    monitor.pathUpdateHandler = { path in
                        let isConnected = path.status == .satisfied
                        continuation.yield(.statusChanged(isConnected))
                    }
                    monitor.start(queue: DispatchQueue(label: "NetworkStore"))
                    
                    continuation.onTermination = { _ in
                        monitor.cancel()
                    }
                }
            }))
        // not really needed
        case .stopMonitioring:
            return (newState, .execute({ monitor in
                monitor.cancel()
                return nil
            }))
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
