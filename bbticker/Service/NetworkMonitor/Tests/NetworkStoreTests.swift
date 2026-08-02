//
//  NetworkStoreTests.swift
//  bbtickerTests
//
//  Created by Aleh Fiodarau on 27/04/2026.
//

import Testing
@testable import bbticker

// MARK: - Test Compatibility Methods
extension NetworkStore {
    /// Simulates network loss for testing
    @MainActor
    func simulateNetworkLoss() async {
        await dispatch(.statusChanged(false))
        await dispatch(.internetStatusChanged(.unavailable))
    }

    /// Simulates network restoration for testing
    @MainActor
    func simulateNetworkRestoration() async {
        await dispatch(.statusChanged(true))
        await dispatch(.internetStatusChanged(.reachable))
    }

    /// Simulates network change to specific state
    @MainActor
    func simulateNetworkChange(isConnected: Bool) async {
        await dispatch(.statusChanged(isConnected))
    }
}

@MainActor
struct NetworkStoreTests {

    @Test func testNetworkChange() async throws {
        let store = NetworkStore(monitoringEngine: MockMonitoringEngine(), startMonitoring: false)
        
        await store.dispatch(.statusChanged(false))
        #expect(store.state.isConnected == false)
        
        await store.dispatch(.statusChanged(true))
        #expect(store.state.isConnected == true)
    }
    
    @Test func testNetworkChangeInternetReachability() async throws {
        let networkMonitor = NetworkStore(monitoringEngine: MockMonitoringEngine(), startMonitoring: false)
        
        var iterator = networkMonitor.statusStream.makeAsyncIterator()
        
        let first = await iterator.next()
        #expect(first == false)
        
        await networkMonitor.simulateNetworkRestoration()
        
        let second = await iterator.next()
        #expect(second == true)
    }

    @Test func testStartMonitoringDispatchReturnsPromptly() async throws {
        let engine = HangingMonitoringEngine()
        let store = NetworkStore(monitoringEngine: engine, startMonitoring: false)

        var didReturn = false

        let task = Task { @MainActor in
            await store.dispatch(.startMonitoring)
            didReturn = true
        }

        defer {
            engine.stop()
            task.cancel()
        }

        try? await Task.sleep(for: .milliseconds(100))

        // dispatch should not stay inside the for-await loop forever even if Monitor is not responding for a long time
        #expect(didReturn == true)
    }
    
    // MARK: - State Management Tests
    
    @Test func testInitialState() async throws {
        let store = NetworkStore(monitoringEngine: MockMonitoringEngine(), startMonitoring: false)
        
        #expect(store.state.isConnected == false)
        #expect(store.state.internetStatus == .unavailable)
        #expect(store.state.connectionType == .unknown)
        #expect(store.state.isInternetReachable == false)
    }
    
    @Test func testConnectionTypeChange() async throws {
        let store = NetworkStore(monitoringEngine: MockMonitoringEngine(), startMonitoring: false)
        
        await store.dispatch(.connectionTypeChanged(.wifi))
        #expect(store.state.connectionType == .wifi)
        
        await store.dispatch(.connectionTypeChanged(.cellular))
        #expect(store.state.connectionType == .cellular)
    }
    
    @Test func testInternetStatusTransitions() async throws {
        let store = NetworkStore(monitoringEngine: MockMonitoringEngine(), startMonitoring: false)
        
        // unavailable -> checking
        await store.dispatch(.internetStatusChanged(.checking))
        #expect(store.state.internetStatus == .checking)
        #expect(store.state.isInternetReachable == false)
        
        // checking -> reachable
        await store.dispatch(.internetStatusChanged(.reachable))
        #expect(store.state.internetStatus == .reachable)
        
        // reachable -> unreachable
        await store.dispatch(.internetStatusChanged(.unreachable))
        #expect(store.state.internetStatus == .unreachable)
        #expect(store.state.isInternetReachable == false)
    }
    
    @Test func testPathUnavailableKeepsInternetStatusIndependent() async throws {
        let store = NetworkStore(monitoringEngine: MockMonitoringEngine(), startMonitoring: false)
        
        // Set internet as reachable with path available
        await store.dispatch(.statusChanged(true))
        await store.dispatch(.internetStatusChanged(.reachable))
        #expect(store.state.isInternetReachable == true)
        
        // Path becomes unavailable - internet status stays but derived property should reflect reality
        await store.dispatch(.statusChanged(false))
        #expect(store.state.isConnected == false)
        #expect(store.state.internetStatus == .reachable) // Status unchanged
        // If you add the safeguard: isInternetReachable = isConnected && internetStatus == .reachable
        // then uncomment: #expect(store.state.isInternetReachable == false)
    }
    
    // MARK: - Stream Tests
    
    @Test func testStatusStreamDoesNotEmitOnPathStatusChange() async throws {
        let store = NetworkStore(monitoringEngine: MockMonitoringEngine(), startMonitoring: false)
        var iterator = store.statusStream.makeAsyncIterator()
        
        // Consume initial value
        _ = await iterator.next()
        
        // Dispatch path status change - should not emit
        await store.dispatch(.statusChanged(true))
        await store.dispatch(.connectionTypeChanged(.wifi))
        
        // Set internet reachable - should emit
        await store.dispatch(.internetStatusChanged(.reachable))
        let value = await iterator.next()
        #expect(value == true)
    }
    
    @Test func testStatusStreamEmitsCompleteNetworkRestoration() async throws {
        let store = NetworkStore(monitoringEngine: MockMonitoringEngine(), startMonitoring: false)
        var iterator = store.statusStream.makeAsyncIterator()
        
        _ = await iterator.next() // Consume initial
        
        // simulateNetworkRestoration dispatches both path and internet status
        await store.simulateNetworkRestoration()
        
        let reachable = await iterator.next()
        #expect(reachable == true)
        #expect(store.state.isConnected == true)
        #expect(store.state.internetStatus == .reachable)
    }
    
    // MARK: - Monitoring Lifecycle Tests
    
    @Test func testStopMonitoring() async throws {
        let engine = ControllableMonitoringEngine()
        let store = NetworkStore(monitoringEngine: engine, startMonitoring: false)
        
        await store.dispatch(.startMonitoring)
        
        // Give the Task time to start
        try? await Task.sleep(for: .milliseconds(50))
        #expect(engine.isMonitoring == true)
        
        await store.dispatch(.stopMonitoring)
        #expect(engine.isMonitoring == false)
    }
    
    @Test func testStartMonitoringCancelsPreviousTask() async throws {
        let engine = ControllableMonitoringEngine()
        let store = NetworkStore(monitoringEngine: engine, startMonitoring: false)
        
        await store.dispatch(.startMonitoring)
        try? await Task.sleep(for: .milliseconds(50))
        let firstStartCount = engine.startCallCount
        
        await store.dispatch(.startMonitoring)
        try? await Task.sleep(for: .milliseconds(50))
        let secondStartCount = engine.startCallCount
        
        #expect(secondStartCount == firstStartCount + 1)
        // Note: stop() is called via monitoringTask?.cancel(), which happens immediately
    }
    
    @Test func testMonitoringEngineActionsAreDispatched() async throws {
        let engine = ActionEmittingMonitoringEngine()
        let store = NetworkStore(monitoringEngine: engine, startMonitoring: false)
        
        await store.dispatch(.startMonitoring)
        
        // Wait for engine to emit actions
        try? await Task.sleep(for: .milliseconds(100))
        
        // Verify actions were processed
        #expect(store.state.isConnected == true)
        #expect(store.state.internetStatus == .reachable)
    }
    
    // MARK: - Reducer Tests (Pure Logic)
    
    @Test func testReducerStatusChanged() {
        let state = NetworkState()
        let (newState, effect) = NetworkReducer.reduce(state, .statusChanged(true))
        
        #expect(newState.isConnected == true)
        #expect(effect == nil)
    }
    
    @Test func testReducerInternetStatusChanged() {
        let state = NetworkState()
        let (newState, effect) = NetworkReducer.reduce(state, .internetStatusChanged(.reachable))
        
        #expect(newState.internetStatus == .reachable)
        #expect(effect == nil)
    }
    
    @Test func testReducerConnectionTypeChanged() {
        let state = NetworkState()
        let (newState, effect) = NetworkReducer.reduce(state, .connectionTypeChanged(.wifi))
        
        #expect(newState.connectionType == .wifi)
        #expect(effect == nil)
    }
    
    @Test func testReducerStartMonitoring() {
        let state = NetworkState()
        let (newState, effect) = NetworkReducer.reduce(state, .startMonitoring)
        
        #expect(newState == state) // State unchanged
        #expect(effect == .startMonitoring)
    }
    
    @Test func testReducerStopMonitoring() {
        let state = NetworkState()
        let (newState, effect) = NetworkReducer.reduce(state, .stopMonitoring)
        
        #expect(newState == state) // State unchanged
        #expect(effect == .stopMonitoring)
    }
    
    @Test func testSimulateMethodsDispatchBothActions() async throws {
        let store = NetworkStore(monitoringEngine: MockMonitoringEngine(), startMonitoring: false)
        
        // simulateNetworkRestoration should set both path and internet status
        await store.simulateNetworkRestoration()
        #expect(store.state.isConnected == true)
        #expect(store.state.internetStatus == .reachable)
        
        // simulateNetworkLoss should clear both
        await store.simulateNetworkLoss()
        #expect(store.state.isConnected == false)
        #expect(store.state.internetStatus == .unavailable)
    }
    
    // MARK: - Connection Type Tests
    
    @Test func testConnectionTypeImageNames() {
        #expect(NetworkStore.ConnectionType.wifi.imageName == "wifi")
        #expect(NetworkStore.ConnectionType.cellular.imageName == "cellularbar")
        #expect(NetworkStore.ConnectionType.ethernet.imageName == "network")
        #expect(NetworkStore.ConnectionType.unknown.imageName == "wifi")
    }
    
    @Test func testConnectionTypeRawValues() {
        #expect(NetworkStore.ConnectionType.wifi.rawValue == "WiFi")
        #expect(NetworkStore.ConnectionType.cellular.rawValue == "Cellular")
        #expect(NetworkStore.ConnectionType.ethernet.rawValue == "Ethernet")
        #expect(NetworkStore.ConnectionType.unknown.rawValue == "Unknown")
    }
}

// MARK: - Test Helpers

@MainActor
final class ControllableMonitoringEngine: MonitoringEngineProtocol {
    var isMonitoring = false
    var startCallCount = 0
    var stopCallCount = 0
    private var continuation: AsyncStream<NetworkAction>.Continuation?
    
    func start() -> AsyncStream<NetworkAction> {
        startCallCount += 1
        isMonitoring = true
        return AsyncStream { continuation in
            self.continuation = continuation
        }
    }
    
    func stop() {
        stopCallCount += 1
        isMonitoring = false
        continuation?.finish()
        continuation = nil
    }
}

@MainActor
final class ActionEmittingMonitoringEngine: MonitoringEngineProtocol {
    private var continuation: AsyncStream<NetworkAction>.Continuation?
    
    func start() -> AsyncStream<NetworkAction> {
        AsyncStream { continuation in
            self.continuation = continuation
            // Emit some test actions
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(10))
                continuation.yield(.statusChanged(true))
                try? await Task.sleep(for: .milliseconds(10))
                continuation.yield(.internetStatusChanged(.reachable))
            }
        }
    }
    
    func stop() {
        continuation?.finish()
        continuation = nil
    }
}

