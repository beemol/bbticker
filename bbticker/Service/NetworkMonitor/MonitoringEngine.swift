//
//  MonitoringEngineProtocol.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 7/27/26.
//

import Foundation

@MainActor
protocol MonitoringEngineProtocol: Sendable {
    func start() -> AsyncStream<NetworkAction>
    func stop()
}

final class MonitoringEngine: MonitoringEngineProtocol {
    private let reachability: InternetReachabilityServiceProtocol
    private let pathMonitor: PathMonitorProtocol
    
    init(reachability: InternetReachabilityServiceProtocol = InternetReachabilityService(),
         pathMonitor: PathMonitorProtocol = ProductionPathMonitor()) {
        self.reachability = reachability
        self.pathMonitor = pathMonitor
    }
    
    func start() -> AsyncStream<NetworkAction> {
        makeMonitoringStream(monitor: pathMonitor, reachability: reachability)
    }
    
    func stop() {
        Task { @MainActor in
            await stopMonitoring(monitor: pathMonitor, reachability: reachability)
        }
    }
    
    private let monitoringQueue = DispatchQueue(label: "NetworkStore")
    
    func makeMonitoringStream(monitor: PathMonitorProtocol,
                                     reachability: InternetReachabilityServiceProtocol) -> AsyncStream<NetworkAction> {
        return AsyncStream<NetworkAction> { continuation in
            monitor.pathUpdateHandler = { path in
                Task { @MainActor in
                    await self.handlePathUpdate(path, continuation: continuation, reachability: reachability)
                }
            }
            monitor.start(queue: monitoringQueue)

            continuation.onTermination = { _ in
                Task { @MainActor in
                    await self.stopMonitoring(monitor: monitor, reachability: reachability)
                }
            }
        }
    }
    
    func handlePathUpdate(_ path: NetworkPathWrapper,
                                 continuation: AsyncStream<NetworkAction>.Continuation,
                                 reachability: InternetReachabilityServiceProtocol) async {
        reachability.stop()
        
        guard path.status == .satisfied, let reachabilityStream = try? reachability.run() else {
            continuation.yield(.statusChanged(false))
            continuation.yield(.internetStatusChanged(.unavailable))
            return
        }
        
        continuation.yield(.statusChanged(true))
        continuation.yield(.internetStatusChanged(.checking))
        
        for await reachability in reachabilityStream {
            let internetStatus: InternetStatus = reachability == true ? .reachable : .unreachable
            continuation.yield(.internetStatusChanged(internetStatus))
        }
    }
    
    func stopMonitoring(monitor: PathMonitorProtocol, reachability: InternetReachabilityServiceProtocol) async {
        reachability.stop()
        monitor.cancel()
    }
}
