//
//  NetworkMonitor.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 03/07/2025.
//

import Foundation
import Network
import Combine

// MARK: - Protocols for Testable Dependencies

@available(*, deprecated, renamed: "NetworkStore", message: "Use NetworkStore instead")
@MainActor
protocol NetworkMonitorProtocol: ObservableObject {
    var isConnected: Bool { get }
    var isConnectedPublisher: AnyPublisher<Bool, Never> { get }
}

extension NetworkMonitor: NetworkMonitorProtocol {
    var isConnectedPublisher: AnyPublisher<Bool, Never> {
        $isConnected.eraseToAnyPublisher()
    }
}

@available(*, deprecated, renamed: "NetworkStore", message: "Use NetworkStore instead")
@MainActor
class NetworkMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isConnected = false
    @Published var connectionType: ConnectionType = .unknown
    
    enum ConnectionType: String {
        case wifi = "WiFi"
        case cellular = "Cellular"
        case ethernet = "Ethernet"
        case unknown = "Unknown"
    }
    
    init() {
        startMonitoring()
    }
    
    deinit {
        monitor.cancel()
    }
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            
            DispatchQueue.main.async {
                self.isConnected = path.status == .satisfied
                self.connectionType = self.getConnectionType(path)
            }
        }
        monitor.start(queue: queue)
    }
    
    private func getConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else {
            return .unknown
        }
    }
} 
