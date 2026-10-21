//
//  PollingStrategy.swift
//
//  Created by Aleh Fiodarau on 29/11/2025.
//

import Foundation

public enum PollingError {
    case maxAttemptsReached
    case general(Error)
    
    init(_ error: Error) {
        self = .general(error)
    }
}

public enum PollingStrategyAction {
    case continuePolling       // Keep retrying (for API errors)
    case stopPolling           // Stop polling (for network errors)
}

public struct PollingConfiguration: Sendable {
    let maxReconnectionAttempts: Int
    let initialRetryDelay: Double
    
    public static let `default` = PollingConfiguration(
        maxReconnectionAttempts: 5,
        initialRetryDelay: 1.0
    )
    
    public static let fastRetry = PollingConfiguration(
        maxReconnectionAttempts: 5,
        initialRetryDelay: 0.01
    )
}

@MainActor
final public class PollingStrategy<Output: Sendable> {
    public typealias FrequencyProvider = () -> Double
    public typealias FetchHandler = () async throws -> Output
    public typealias UpdateHandler = (Output) -> Void
    public typealias ErrorHandler = (PollingError) -> PollingStrategyAction
    
    private let getFrequency: FrequencyProvider
    private let fetchHandler: FetchHandler
    private let updateHandler: UpdateHandler
    private let errorHandler: ErrorHandler
    
    private var config: PollingConfiguration
    
    // query closure to check if connection is in proper state (i.e. .connected)
    private let shouldContinue: () -> Bool
    
    private var pollingTask: Task<Void, Never>?
    
    public init(frequencyProvider: @escaping FrequencyProvider,
         shouldContinue: @escaping () -> Bool,
         fetchHandler: @escaping FetchHandler,
         updateHandler: @escaping UpdateHandler,
         errorHandler: @escaping ErrorHandler,
         config: PollingConfiguration = .default)
    {
        self.getFrequency = frequencyProvider
        self.shouldContinue = shouldContinue
        self.fetchHandler = fetchHandler
        self.updateHandler = updateHandler
        self.errorHandler = errorHandler
        
        self.config = config
    }
    
    @available(macOS 13.0, iOS 16.0, *)
    public func start<C: Clock>(clock: C = ContinuousClock()) where C.Duration == Duration {
        
        var reconnectionAttempts = 0
        var currentDelay = config.initialRetryDelay
        
        pollingTask = Task {
            while !Task.isCancelled && shouldContinue() {
                
                do {
                    let data = try await fetchHandler()
                    
                    // cancel any inFlight API calls
                    // fetchHandler method (or mock in tests) needs to have a suspenssion point for cooperative cancellation to work
                    try Task.checkCancellation()
                    
                    updateHandler(data)

                    // reset reconnection state
                    reconnectionAttempts = 0
                    
                    
                    // wait before making another API call
                    try? await clock.sleep(for: .seconds(getFrequency()))
                } catch {
                    if error is CancellationError {
                        print("[PollingStrategy] Cancelled")
                        return
                    }
                    
                    if errorHandler(PollingError(error)) == .stopPolling {
                        stop()
                        return
                    }
                    
                    guard reconnectionAttempts < config.maxReconnectionAttempts else {
                        // Max attempts reached, stop polling
                        // also we need to inform client that we stoped polling
                        _ = errorHandler(PollingError.maxAttemptsReached)
                        
                        stop()
                        
                        break
                    }
                    reconnectionAttempts += 1
                    currentDelay *= 2
                    
                    // Wait with exponential backoff before next attempt
                    try? await clock.sleep(for: .seconds(currentDelay))
                }
            }
        }
    }
    
    public func stop() {
        pollingTask?.cancel()
        pollingTask = nil
    }
}
