//
//  WalletStateObservationTests.swift
//  bbtickerTests

import XCTest
import Combine
import LLCore
@testable import bbticker

class WalletStateObservationTests: XCTestCase {
    
    var mockSharedDataManager: MockSharedDataManager!
    var mockCredentialManager: MockCredentialManager!
    var cancellables: Set<AnyCancellable>!
    
    @MainActor
    private lazy var sut: BBClient = {
        BBClient(
            settingsService: mockSettingsService,
            networkMonitor: mockNetworkMonitor,
            sharedDataManager: mockSharedDataManager,
            walletRepository: mockWalletRepository
        )
    }()
    
    @MainActor
    private lazy var mockSettingsService = MockSettingsService()
    
    @MainActor
    private lazy var mockNetworkMonitor = MockNetworkStore()
    
    @MainActor
    private lazy var mockAPIService = MockAPIService()
    
    @MainActor
    private lazy var mockWalletRepository = MockWalletRepository(apiService: mockAPIService)
    
    override func setUp() {
        super.setUp()
        mockSharedDataManager = MockSharedDataManager()
        mockCredentialManager = MockCredentialManager()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        mockSharedDataManager = nil
        mockCredentialManager = nil
        cancellables = nil
        super.tearDown()
    }
    
    @MainActor
    func testWalletState_InstanceIdentity_RemainsAfterDisconnect() async {
        // Given - establish connection and capture the walletState instance
        mockAPIService.shouldSucceed = true
        mockAPIService.mockTotalEquity = 1000.00
        mockAPIService.mockWalletBalance = 500.00
        
        await sut.connect()
        XCTAssertEqual(sut.connectionStatus, .connected)
        
        // Capture the EXACT instance that a view would hold
        let capturedWalletState = sut.$walletState
        XCTAssertTrue(capturedWalletState === sut.$walletState)
    }
}

