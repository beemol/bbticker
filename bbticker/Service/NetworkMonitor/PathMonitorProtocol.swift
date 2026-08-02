//
//  PathMonitorProtocol.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 20/04/2026.
//

import Foundation
import Network

@MainActor @preconcurrency
protocol PathMonitorProtocol: AnyObject, Sendable {  // AnyObject for reference semantics
    var pathUpdateHandler: (@Sendable (_ newPath: NetworkPathWrapper) -> Void)? { get set }
    
    func start(queue: DispatchQueue)
    func cancel()
}

@preconcurrency
final class ProductionPathMonitor: PathMonitorProtocol {
    private let monitor: NWPathMonitor
    
    var pathUpdateHandler: (@Sendable (NetworkPathWrapper) -> Void)? {
        didSet {
            monitor.pathUpdateHandler = { [weak self] rawPath in
                Task { @MainActor [weak self] in
                    let wrapped = NetworkPathWrapper(rawValue: rawPath)
                    self?.pathUpdateHandler?(wrapped)
                }
            }
        }
    }
    
    func start(queue: DispatchQueue) {
        monitor.start(queue: queue)
    }
    
    func cancel() {
        monitor.cancel()
    }
    
    init() {
        self.monitor = NWPathMonitor()
    }
}

struct NetworkPathWrapper: Equatable {
    let status: NWPath.Status
    let isExpensive: Bool

    // Production initializer to map from Apple's NWPath
    init(rawValue: NWPath) {
        self.status = rawValue.status
        self.isExpensive = rawValue.isExpensive
    }

    // Testing initializer to create any state programmatically
    init(status: NWPath.Status, isExpensive: Bool = false) {
        self.status = status
        self.isExpensive = isExpensive
    }
}

// MARK: - Mock Implementation for Testing
final class MockPathMonitor: PathMonitorProtocol {
    var pathUpdateHandler: (@Sendable (NetworkPathWrapper) -> Void)?
    
    // Test control properties
    private(set) var isStarted = false
    private(set) var isCancelled = false
    private(set) var startQueue: DispatchQueue?
    
    func start(queue: DispatchQueue) {
        isStarted = true
        startQueue = queue
    }
    
    func cancel() {
        isCancelled = true
    }
    
    func simulateNetworkChange(newPath: NetworkPathWrapper) {
        pathUpdateHandler?(newPath)
    }
    
    func simulateNetworkChange(connected: Bool) {
        var newPath: NetworkPathWrapper
        
        if connected {
            newPath = NetworkPathWrapper(status: .satisfied, isExpensive: false)
        } else {
            newPath = NetworkPathWrapper(status: .unsatisfied, isExpensive: false)
        }
        
        pathUpdateHandler?(newPath)
    }
}
