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
protocol NetworkStoreProtocol: AnyObject {
    var state: NetworkState { get }
    
    var statusStream: AsyncStream<Bool> { get }
}

@Observable
final class NetworkStore: NetworkStoreProtocol {
    private(set) var statusStream: AsyncStream<Bool>
    private var reachabilityContinuation: AsyncStream<Bool>.Continuation?

    // UDF section
    private(set) var state = NetworkState()
    private let reducer: (NetworkState, NetworkAction) -> (NetworkState, NetworkEffect?) = NetworkReducer.reduce
    
    // Internal network monitor
    private let reachability: InternetReachabilityServiceProtocol
    private let pathMonitor: PathMonitorProtocol
    private let monitoringEngine: MonitoringEngineProtocol
    
    private var monitoringTask: Task<Void, Never>?
    
    /// monitoringEngine and startMonitoring can be used for testing purposes
    @MainActor
    init(reachability: InternetReachabilityServiceProtocol = InternetReachabilityService(),
         pathMonitor: PathMonitorProtocol = ProductionPathMonitor(),
         monitoringEngine: MonitoringEngineProtocol? = nil,
         startMonitoring: Bool = true)
    {
        
        self.reachability = reachability
        self.pathMonitor = pathMonitor
        self.monitoringEngine = monitoringEngine ?? MonitoringEngine(reachability: reachability, pathMonitor: pathMonitor)
        
        let (stream, continuation) = AsyncStream<Bool>.makeStream()
        statusStream = stream
        reachabilityContinuation = continuation
        
        reachabilityContinuation?.onTermination = { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.reachabilityContinuation = nil
            }
        }
        
        if startMonitoring {
            Task {
                await dispatch(.startMonitoring)
            }
        } else {
            // push initial state to prevent tests from hanging
            reachabilityContinuation?.yield(state.isInternetReachable)
        }
    }

    @MainActor
    deinit {
        reachabilityContinuation?.finish()
        monitoringEngine.stop()
    }
    
    @MainActor
    func dispatch(_ action: NetworkAction) async {
        let (newState, effect) = reducer(state, action)
        
        if state != newState {
            if state.isInternetReachable != newState.isInternetReachable {
                reachabilityContinuation?.yield(newState.isInternetReachable)
            }
            
            state = newState
        }
        
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

struct NetworkState: Equatable {
    // TODO: keeping for BC, replace with isPathAvaillble naming
    var isConnected: Bool = false // isPathAvaillble, i.e NWPath.status == .satisfied
    
    var internetStatus: InternetStatus = .unavailable
    var connectionType: NetworkStore.ConnectionType = .unknown
    
    var isInternetReachable: Bool {
        isConnected && internetStatus == .reachable
    }
}

enum NetworkAction: Equatable {
    case statusChanged(Bool) // NWPath.status
    case internetStatusChanged(InternetStatus)
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
        case .internetStatusChanged(let status):
            newState.internetStatus = status
            return (newState, nil)
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
}
