//
//  MockNetworkStore.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 8/1/26.
//

@testable import bbticker

@MainActor
class MockNetworkStore: NetworkStoreProtocol {
    var state: bbticker.NetworkState {
        realStore.state
    }
    
    var statusStream: AsyncStream<Bool> {
        realStore.statusStream
    }
    
    private let realStore: NetworkStore
    
    init() {
        realStore = NetworkStore(monitoringEngine: MockMonitoringEngine(), startMonitoring: true)
    }
    
    @MainActor
    var isConnected: Bool {
        get {
            self.realStore.state.isInternetReachable
        }
        set {
            Task { @MainActor in
                let status: InternetStatus = newValue ? .reachable : .unreachable
                await self.realStore.dispatch(.statusChanged(newValue))
                await self.realStore.dispatch(.internetStatusChanged(status))
            }
        }
    }
    
    @MainActor
    func simulateNetworkLoss() async {
        await realStore.simulateNetworkLoss()
    }
    
    @MainActor
    func simulateNetworkRestore() async {
        await realStore.simulateNetworkRestoration()
    }
}

@MainActor
final class MockMonitoringEngine: MonitoringEngineProtocol {
    func start() -> AsyncStream<NetworkAction> {
        AsyncStream { _ in }  // Empty stream - emits nothing
    }
    
    func stop() {}
}

@MainActor
final class HangingMonitoringEngine: MonitoringEngineProtocol {
    private var continuation: AsyncStream<NetworkAction>.Continuation?

    func start() -> AsyncStream<NetworkAction> {
        AsyncStream { continuation in
            self.continuation = continuation
        }
    }

    func stop() {
        continuation?.finish()
        continuation = nil
    }
}
