//
//  InternetReachabilityService.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 04/07/2026.
//

import Foundation
import LLApiService

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
    private let urlSession: URLSessionProtocol
    private var task: Task<Void, Never>?
    
    init(period: TimeInterval = 1,
         urlSession: URLSessionProtocol = URLSession.shared)
    {
        self.period = period
        self.urlSession = urlSession
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
        
        let (stream, continuation) = AsyncStream<Bool>.makeStream(of: Bool.self, bufferingPolicy: .bufferingNewest(1))
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
        
        task?.cancel()
        task = nil

        // Finish the continuation to allow the for await loop to exit
        continuation?.finish()
        continuation = nil
    }
    
    private func probe(url: URL) {
        task = Task { @MainActor [weak self] in
            let request = URLRequest(url: url)
            
            do {
                let data = try await self?.urlSession.data(for: request)
                
                guard !Task.isCancelled else { return }
                self?.continuation?.yield(data?.0.isEmpty == false)
            } catch {
                guard !Task.isCancelled else { return }
                self?.continuation?.yield(false)
            }
        }
    }
}
