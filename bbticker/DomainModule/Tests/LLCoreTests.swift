//
//  LLCoreTests.swift
//  LLCoreTests
//
//  Main test file - comprehensive tests are organized in separate files:
//  - ErrorDetectorTests.swift
//  - RequestBuilderTests.swift
//  - ParserTests.swift
//  - ErrorMapperTests.swift
//  - HelpersTests.swift
//  - ModelTests.swift
//

import Testing
@testable import bbticker
@testable import LLCore

@Suite("LLCore Package Tests")
struct LLCoreTests {
    
    @Test("Package imports successfully")
    func testPackageImports() {
        // Verify that the package can be imported and basic types are accessible
        let _ = Exchange(.bybit, wallet: .unified)
        let _ = WalletData(totalEquity: 0, walletBalance: 0)
        let _ = APIError.invalidRequest
    }
}
