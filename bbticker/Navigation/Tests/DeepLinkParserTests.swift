//
//  DeepLinkParserTests.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 9/29/26.
//

import Testing
@testable import bbticker
import Foundation

struct DeepLinkParserTests {
    
    @Test func test_validBybitCompletionURL_returnsCompletionRoute() {
        let url = URL(string: "bbticker://connect/bybit/complete")!

        #expect(DeepLinkParser.parse(url) == .bybitConnectionCompleted)
    }
    
    @Test func test_wrongHost_returnsNil() {
        let url = URL(string: "bbticker://unexpected/bybit/complete")!

        #expect(DeepLinkParser.parse(url) == nil)
    }

    @Test func test_wrongPath_returnsNil() {
        let url = URL(string: "bbticker://connect/bybit/start")!

        #expect(DeepLinkParser.parse(url) == nil)
    }
}
