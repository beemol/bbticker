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
        let store = NetworkStore(startMonitoring: false)
        
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

}
