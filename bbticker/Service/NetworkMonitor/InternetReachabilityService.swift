//
//  InternetReachabilityService.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 04/07/2026.
//

import Foundation

@MainActor
protocol InternetReachabilityServiceProtocol: Sendable {
    func run(withUrlString: String) throws -> AsyncStream<Bool>
    func run() throws -> AsyncStream<Bool>
    
    func stop()
}

final class InternetReachabilityService: InternetReachabilityServiceProtocol {
    private var continuation: AsyncStream<Bool>.Continuation?
    
    private let period: TimeInterval
    private var timer: Timer?
    private let urlSession: URLSession = URLSession.shared
    
    init(period: TimeInterval = 1) {
        self.period = period
    }
    
    @MainActor
    deinit {
        timer?.invalidate()
        timer = nil
    }
    
    func run() throws -> AsyncStream<Bool> {
        try run(withUrlString: "https://www.google.com")
    }
    
    func run(withUrlString: String) throws -> AsyncStream<Bool> {
        guard let url = URL(string: withUrlString) else {
            throw URLError(.badURL)
        }
        
        let (stream, continuation) = AsyncStream<Bool>.makeStream()
        let statusStream = stream
        self.continuation = continuation

        // emmit initial value
        probe(url: url)
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: period, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.probe(url: url)
            }

        }
        
        return statusStream
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil

        // Finish the continuation to allow the for await loop to exit
        continuation?.finish()
    }
    
    private func probe(url: URL) {
        Task { @MainActor [weak self] in
            let data = try await self?.urlSession.data(from: url)
            self?.continuation?.yield(data?.0.isEmpty == false)
        }
    }
}
