//
//  InternetReachabilityServiceTests.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 11/21/26.
//

import Testing
import LLApiService
import Foundation
@testable import bbticker

final class SessionMock: URLSessionProtocol, @unchecked Sendable {
    private var results: [Result<(Data, URLResponse), Error>]

    init(results: [Result<(Data, URLResponse), Error>]) {
        self.results = results
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        guard !results.isEmpty else {
            throw URLError(.badServerResponse)
        }
        let result = results.removeFirst()
        return try result.get()
    }
}

@MainActor
final class BlockingSessionMock: URLSessionProtocol {
    private(set) var wasCancelled = false

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            try await Task.sleep(for: .seconds(10))
            return (Data([1]), URLResponse())
        } catch is CancellationError {
            wasCancelled = true
            throw CancellationError()
        }
    }
}

@MainActor
struct InternetReachabilityServiceTests {
    
    @Test func testThrowingURLSession() async {
        let falingSession = SessionMock(results: [.failure(URLError(.unknown))])
        let service = InternetReachabilityService(urlSession: falingSession)

        defer { service.stop() }
        
        let stream = try? service.run()
        
        var result: Bool?
        
        Task { @MainActor in
            var iter = stream?.makeAsyncIterator()
            result = await iter?.next()
        }
        
        try? await Task.sleep(for: .milliseconds(100))
        
        #expect(result == false)
    }
    
    @Test func givingTwoValuesExpectToConsiderTheLatest() async {
        // async stream buffers all the values by default
        // we need to consider only the recent one
        let response = URLResponse()
        let session = SessionMock(results: [.success((Data([1]), response)),
                                                  .failure(URLError(.unknown))])
        let service = InternetReachabilityService(period: 0.01, urlSession: session)

        defer { service.stop() }
        
        let stream = try? service.run()
        
        // Allow probe 1 and probe 2 to emit before reading.
        try? await Task.sleep(for: .milliseconds(300))
        
        var iter = stream?.makeAsyncIterator()
        let result = await iter?.next()
        
        #expect(result == false)
    }
    
    @Test func givingTwoValuesStopAfterTheFirstExpectNoSecondInReturn() async  {
        let session = SessionMock(results: [.success((Data([1]), URLResponse())),
                                                  .failure(URLError(.unknown))])
        
        let service = InternetReachabilityService(period: 0.1, urlSession: session)
        
        let stream = try? service.run()
        
        // Allow probe 1 to emit before cancellation
        try? await Task.sleep(for: .milliseconds(50))
        
        service.stop()
        
        try? await Task.sleep(for: .milliseconds(100))
        
        var iter = stream?.makeAsyncIterator()
        let result = await iter?.next()
        
        #expect(result == true)
    }
    
    @Test func givingBlockingServiceExpectProperCancellation() async {
        let session = BlockingSessionMock()
        let service = InternetReachabilityService(period: 0.1, urlSession: session)
        
        do {
            _ = try service.run()

            try await Task.sleep(for: .milliseconds(50))
            
            service.stop()
            
            try await Task.sleep(for: .milliseconds(50))
            
            #expect(session.wasCancelled)
        } catch {
            #expect(session.wasCancelled)
        }
    }
}
