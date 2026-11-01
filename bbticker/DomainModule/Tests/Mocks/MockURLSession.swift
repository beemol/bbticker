//
//  MockURLSession.swift
//  LLCoreTests
//
//  Created for testing purposes
//

import Foundation
import LLApiService

/// Mock URL session for testing network requests
public actor MockedURLSession: URLSessionProtocol {
    public var mockData: Data?
    public var mockResponse: URLResponse?
    public var mockError: Error?
    public var capturedRequest: URLRequest?
    
    public init() {}
    
    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        capturedRequest = request
        
        if let error = mockError {
            throw error
        }
        
        guard let data = mockData, let response = mockResponse else {
            throw URLError(.badServerResponse)
        }
        
        return (data, response)
    }
    
    /// Helper to setup a mock response
    public func setupResponse(data: String, statusCode: Int, url: String = "https://api.test.com") {
        self.mockData = data.data(using: .utf8)
        self.mockResponse = HTTPURLResponse(
            url: URL(string: url)!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )
        self.mockError = nil
    }
    
    /// Helper to setup a mock error
    public func setupError(_ error: Error) {
        self.mockError = error
        self.mockData = nil
        self.mockResponse = nil
    }
    
    /// Reset all mock data
    public func reset() {
        mockData = nil
        mockResponse = nil
        mockError = nil
        capturedRequest = nil
    }
}

