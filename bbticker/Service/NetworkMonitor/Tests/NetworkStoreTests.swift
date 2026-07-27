//
//  NetworkStoreTests.swift
//  bbtickerTests
//
//  Created by Aleh Fiodarau on 27/04/2026.
//

import Testing
@testable import bbticker

@MainActor
struct NetworkStoreTests {

    @Test func testNetworkChange() async throws {
        let store = NetworkStore()
        
        await store.dispatch(.statusChanged(false))
        #expect(store.state.isConnected == false)
        
        await store.dispatch(.statusChanged(true))
        #expect(store.state.isConnected == true)
    }
    
    @Test func testNetworkChangeStream() async throws {
        let store = NetworkStore(monitoringEngine: MonitoringEngine(), startMonitoring: false)
        
        var states: [Bool] = []
        
        let task = Task {
            for await isConnected in store.statusStream {
                states.append(isConnected)
                if states.count >= 2 { break }
            }
        }
        
        await store.dispatch(.statusChanged(false))
        await task.value
        
        #expect(states == [false, false])
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
}

@MainActor
private final class HangingMonitoringEngine: MonitoringEngineProtocol {
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
