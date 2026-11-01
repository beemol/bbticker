//
//  Test.swift
//  LLCore
//
//  Created by Aleh Fiodarau on 08/04/2026.
//

import Testing
@testable import bbticker

@MainActor
struct PollingStrategyTest {
    
    // to capture a ref and change it inside a closure
    class BoolRef {
        var value: Bool
        init(_ value: Bool) { self.value = value }
    }
    
    lazy var pollingStrategy: PollingStrategy<Double> = PollingStrategy(
        frequencyProvider: frequency,
        shouldContinue: shouldContinue,
        fetchHandler: fetchHandler,
        updateHandler: updateHandler,
        errorHandler: errorHandler )
    

    var frequency: () -> Double = { return 1.0 }
    var shouldContinue: () -> Bool = { true }
    var fetchHandler: () async throws -> Double = { return 1.0 }
    var updateHandler: (Double) -> Void = { _ in }
    var errorHandler: (PollingError) -> PollingStrategyAction = { _ in return .stopPolling }

    @Test("Tests if there is any delay before the first API call. It should be none.")
    mutating func testInitialDelay() async throws {
        
        let shouldProceed: BoolRef = BoolRef(true)
        
        self.shouldContinue = { shouldProceed.value }
        
        let clock = ContinuousClock()
        let startTime = clock.now
        
        await withCheckedContinuation { continuation in
            self.fetchHandler = {
                let elapsed = clock.now - startTime
                #expect(elapsed < .seconds(0.5))
                continuation.resume()
                // stop the  polling loop
                shouldProceed.value = false
                return 1.0
            }
            self.pollingStrategy.start()
        }

    }
    
    @Test("Test inflight cancellation")
    mutating func testInFlightCancellation() async throws {
        
        self.frequency = { return 3 }
        let updateWasCalled = BoolRef(false)
        
        errorHandler = { error in
            // we should not receive a CancellationError
            #expect(!(error is CancellationError))
            return PollingStrategyAction.stopPolling
        }
        
        updateHandler = { _ in
            updateWasCalled.value = true
        }
        
        await withCheckedContinuation { continuation in
            
            self.fetchHandler = {
                // Simulate a long-running network request that completes successfully
                // but doesn't have built-in cancellation checkpoints
                await withCheckedContinuation { fetchContinuation in
                    Task {
                        // Give time for cancellation to happen
                        try? await Task.sleep(for: .milliseconds(200))
                        fetchContinuation.resume() // Complete successfully regardless of cancellation
                    }
                }
                
                return 1.0
            }
            
            let strategy = self.pollingStrategy // Capture the strategy
            strategy.start()
            
            // Use Task to handle async work
            Task {
                // Give the network request time to start
                try? await Task.sleep(for: .milliseconds(100))
                strategy.stop() // Cancel the polling strategy
                
                // Give some time for processing to potentially complete
                try? await Task.sleep(for: .milliseconds(300))
                
                // Without proper cancellation handling in PollingStrategy,
                // updateHandler would be called even after stop()
                #expect(!updateWasCalled.value, "updateHandler should not be called after cancellation")
                
                continuation.resume()
            }

        }
    }

}
