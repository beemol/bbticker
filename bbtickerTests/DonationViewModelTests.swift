import XCTest
import SwiftUI
@testable import bbticker

// MARK: - DonationViewModel Tests

@MainActor
class DonationViewModelTests: XCTestCase {
    
    let mockRemoteConfigManager = Mocks.MockRemoteConfigManager()
    
    @MainActor
    lazy var viewModel: DonationViewModel = {
        DonationViewModel(remoteConfigManager: mockRemoteConfigManager)
    }()
    
    func testInitialState() {
        // Given/When - ViewModel is initialized in setUp
        
        // Then
        XCTAssertTrue(viewModel.wallets.isEmpty)
        XCTAssertTrue(viewModel.isLoading)
        XCTAssertNil(viewModel.copiedAddress)
    }
    
    // MARK: - Wallet Configuration Loading Tests
    
    func testLoadWalletConfiguration_Success() {
        // Given
        let testJSON = """
        {
          "wallet_address": "0xTEST_WALLET_ADDRESS",
          "networks": [
            {
              "id": "mantle",
              "networkName": "Mantle Network: $0.0 fee",
              "gasToken": "MNT",
              "supportedCurrencies": ["USDT", "ETH", "MNT", "USDC"]
            },
            {
              "id": "arbitrumOne",
              "networkName": "Arbitrum One",
              "gasToken": "ETH",
              "supportedCurrencies": ["USDT: $0.0 fee", "ETH: $0.13 fee", "ARB"]
            }
          ]
        }
        """
        
        mockRemoteConfigManager.setDonationConfig(testJSON)
        
        // When
        viewModel.loadWalletConfiguration()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.wallets.count, 2)
        
        // Verify all wallets use the same address
        XCTAssertTrue(viewModel.wallets.allSatisfy { $0.address == "0xTEST_WALLET_ADDRESS" })
        
        // Verify order is preserved (mantle first, arbitrumOne second)
        XCTAssertEqual(viewModel.wallets[0].id, "mantle")
        XCTAssertEqual(viewModel.wallets[1].id, "arbitrumOne")
        
        // Verify network details
        let mantleWallet = viewModel.wallets[0]
        XCTAssertEqual(mantleWallet.networkName, "Mantle Network: $0.0 fee")
        XCTAssertEqual(mantleWallet.currencies, ["USDT", "ETH", "MNT", "USDC"])
        
        let arbitrumWallet = viewModel.wallets[1]
        XCTAssertEqual(arbitrumWallet.networkName, "Arbitrum One")
        XCTAssertEqual(arbitrumWallet.currencies, ["USDT: $0.0 fee", "ETH: $0.13 fee", "ARB"])
    }
    
    func testLoadWalletConfiguration_OrderPreservation() {
        // Given - Test that order is preserved when networks are in different order
        let testJSON = """
        {
          "wallet_address": "0xORDER_TEST_ADDRESS",
          "networks": [
            {
              "id": "arbitrumOne",
              "networkName": "Arbitrum One",
              "gasToken": "ETH",
              "supportedCurrencies": ["USDT", "ETH"]
            },
            {
              "id": "mantle",
              "networkName": "Mantle Network: $0.0 fee",
              "gasToken": "MNT",
              "supportedCurrencies": ["USDT", "MNT"]
            }
          ]
        }
        """
        
        mockRemoteConfigManager.setDonationConfig(testJSON)
        
        // When
        viewModel.loadWalletConfiguration()
        
        // Then
        XCTAssertEqual(viewModel.wallets.count, 2)
        
        // Verify order is preserved (arbitrumOne first, mantle second - as specified in JSON)
        XCTAssertEqual(viewModel.wallets[0].id, "arbitrumOne")
        XCTAssertEqual(viewModel.wallets[1].id, "mantle")
        XCTAssertEqual(viewModel.wallets[0].networkName, "Arbitrum One")
        XCTAssertEqual(viewModel.wallets[1].networkName, "Mantle Network: $0.0 fee")
    }
    
//    func testLoadWalletConfiguration_NoConfigAvailable() {
//        // Given - No config available (nil)
//        mockRemoteConfigManager.setDonationConfig("")
//        
//        // When
//        viewModel.loadWalletConfiguration()
//        
//        // Then
//        XCTAssertFalse(viewModel.isLoading)
//        XCTAssertEqual(viewModel.wallets.count, 2) // Should use fallback wallets
//        
//        // Verify fallback order (mantle first, arbitrumOne second)
//        XCTAssertEqual(viewModel.wallets[0].id, "mantle")
//        //XCTAssertEqual(viewModel.wallets[1].id, "arbitrumOne")
//        XCTAssertTrue(viewModel.wallets.contains { $0.networkName == "Mantle Network: $0.0 fee" })
//        XCTAssertTrue(viewModel.wallets.contains { $0.networkName == "Arbitrum One" })
//        
//        // All fallback wallets should use the same address
//        XCTAssertTrue(viewModel.wallets.allSatisfy { $0.address == "0xd537463b7b25e0e6559b4f33b094f355b9a7a983" })
//    }
    
//    func testLoadWalletConfiguration_InvalidJSON() {
//        // Given
//        let invalidJSON = "{ invalid json structure"
//        mockRemoteConfigManager.setDonationConfig(invalidJSON)
//        
//        // When
//        viewModel.loadWalletConfiguration()
//        
//        // Then
//        XCTAssertFalse(viewModel.isLoading)
//        //XCTAssertEqual(viewModel.wallets.count, 2) // Should use fallback wallets
//    }
//    
//    func testLoadWalletConfiguration_EmptyNetworks() {
//        // Given
//        let emptyNetworksJSON = """
//        {
//          "wallet_address": "0xTEST_ADDRESS",
//          "networks": []
//        }
//        """
//        mockRemoteConfigManager.setDonationConfig(emptyNetworksJSON)
//        
//        // When
//        viewModel.loadWalletConfiguration()
//        
//        // Then
//        XCTAssertFalse(viewModel.isLoading)
//        //XCTAssertEqual(viewModel.wallets.count, 2) // Should use fallback wallets
//    }
//    
//    func testLoadWalletConfiguration_EmptyJSONString() {
//        // Given
//        mockRemoteConfigManager.setDonationConfig("")
//        
//        // When
//        viewModel.loadWalletConfiguration()
//        
//        // Then
//        XCTAssertFalse(viewModel.isLoading)
//        XCTAssertEqual(viewModel.wallets.count, 2) // Should use fallback wallets
//    }
//    
//    func testLoadWalletConfiguration_NilConfig() {
//        // Given
//        mockRemoteConfigManager.donationWalletConfig = nil
//        
//        // When
//        viewModel.loadWalletConfiguration()
//        
//        // Then
//        XCTAssertFalse(viewModel.isLoading)
//        XCTAssertEqual(viewModel.wallets.count, 2) // Should use fallback wallets
//    }
    
    // MARK: - Clipboard Tests
    
    func testCopyToClipboard_WalletAddress() {
        // Given
        let testAddress = "0xTEST_WALLET_ADDRESS_123"
        let walletId = "wallet"
        
        // When
        viewModel.copyToClipboard(address: testAddress, walletId: walletId)
        
        // Then
        XCTAssertEqual(viewModel.copiedAddress, walletId)
        
        // Test that copied state clears after delay
        let expectation = XCTestExpectation(description: "Copied state cleared")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.1) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 4.0)
        XCTAssertNil(viewModel.copiedAddress)
    }
    
    func testCopyToClipboard_MultipleAddresses() {
        // Given
        let firstAddress = "0xFIRST_ADDRESS"
        let secondAddress = "0xSECOND_ADDRESS"
        let firstWalletId = "first_wallet"
        let secondWalletId = "second_wallet"
        
        // When
        viewModel.copyToClipboard(address: firstAddress, walletId: firstWalletId)
        XCTAssertEqual(viewModel.copiedAddress, firstWalletId)
        
        // Copy second address before first clears
        viewModel.copyToClipboard(address: secondAddress, walletId: secondWalletId)
        
        // Then
        XCTAssertEqual(viewModel.copiedAddress, secondWalletId)
    }
    
    func testCopyToClipboard_WalletCopyFlow() {
        // Given - Simulate the new UI flow where user copies the main wallet address
        let walletAddress = "0xMAIN_WALLET_ADDRESS"
        
        // When
        viewModel.copyToClipboard(address: walletAddress, walletId: "wallet")
        
        // Then
        XCTAssertEqual(viewModel.copiedAddress, "wallet")
    }
    
    // MARK: - Instructions Tests
    
    func testLoadWalletConfiguration_WithInstructions() {
        // Given
        let testJSON = """
        {
          "wallet_address": "0xTEST_WALLET",
          "networks": [
            {
              "id": "mantle",
              "networkName": "Mantle Network: $0.0 fee",
              "gasToken": "MNT",
              "supportedCurrencies": ["USDT"]
            }
          ],
          "instructions": {
            "instructionsTitle": "Custom Instructions:",
            "donationSteps": [
              {"stepNumber": 1, "description": "Custom step 1"},
              {"stepNumber": 2, "description": "Custom step 2"}
            ],
            "confirmationMessage": "Custom confirmation message"
          }
        }
        """
        
        mockRemoteConfigManager.setDonationConfig(testJSON)
        
        // When
        viewModel.loadWalletConfiguration()
        
        // Then
        XCTAssertNotNil(viewModel.instructions)
        XCTAssertEqual(viewModel.instructions?.instructionsTitle, "Custom Instructions:")
        XCTAssertEqual(viewModel.instructions?.donationSteps.count, 2)
        XCTAssertEqual(viewModel.instructions?.donationSteps[0].description, "Custom step 1")
        XCTAssertEqual(viewModel.instructions?.confirmationMessage, "Custom confirmation message")
    }
    
    func testLoadWalletConfiguration_WithoutInstructions_UsesFallback() {
        // Given
        let testJSON = """
        {
          "wallet_address": "0xTEST_WALLET",
          "networks": [
            {
              "id": "mantle",
              "networkName": "Mantle Network",
              "gasToken": "MNT",
              "supportedCurrencies": ["USDT"]
            }
          ]
        }
        """
        
        mockRemoteConfigManager.setDonationConfig(testJSON)
        
        // When
        viewModel.loadWalletConfiguration()
        
        // Then
        XCTAssertNotNil(viewModel.instructions)
        XCTAssertEqual(viewModel.instructions?.instructionsTitle, "For Bybit Users:")
        XCTAssertEqual(viewModel.instructions?.donationSteps.count, 6)
    }
    
    // MARK: - Fee Information Tests
    
    func testWalletConfiguration_WithFeeInformation() {
        // Given
        let testJSON = """
        {
          "wallet_address": "0xTEST_WALLET",
          "networks": [
            {
              "id": "mantle",
              "networkName": "Mantle Network: $0.0 fee",
              "gasToken": "MNT",
              "supportedCurrencies": ["USDT", "ETH", "MNT", "USDC"]
            },
            {
              "id": "arbitrumOne",
              "networkName": "Arbitrum One",
              "gasToken": "ETH",
              "supportedCurrencies": ["USDT: $0.0 fee", "ETH: $0.13 fee", "ARB", "USDC: $1.0 fee"]
            }
          ]
        }
        """
        
        mockRemoteConfigManager.setDonationConfig(testJSON)
        
        // When
        viewModel.loadWalletConfiguration()
        
        // Then
        // Verify fee information in network names
        let mantleWallet = viewModel.wallets.first { $0.id == "mantle" }
        XCTAssertTrue(mantleWallet?.networkName.contains("$0.0 fee") == true)
        
        // Verify fee information in currencies
        let arbitrumWallet = viewModel.wallets.first { $0.id == "arbitrumOne" }
        XCTAssertTrue(arbitrumWallet?.currencies.contains("USDT: $0.0 fee") == true)
        XCTAssertTrue(arbitrumWallet?.currencies.contains("ETH: $0.13 fee") == true)
        XCTAssertTrue(arbitrumWallet?.currencies.contains("USDC: $1.0 fee") == true)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteWorkflow() {
        // Given
        let testJSON = """
        {
          "wallet_address": "0xINTEGRATION_TEST_ADDRESS",
          "networks": [
            {
              "id": "mantle",
              "networkName": "Mantle Network: $0.0 fee",
              "gasToken": "MNT",
              "supportedCurrencies": ["USDT", "ETH"]
            }
          ]
        }
        """
        
        mockRemoteConfigManager.setDonationConfig(testJSON)
        
        // When - Load configuration
        viewModel.loadWalletConfiguration()
        
        // Copy the main wallet address (new UI behavior)
        viewModel.copyToClipboard(address: "0xINTEGRATION_TEST_ADDRESS", walletId: "wallet")
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.wallets.count, 1)
        XCTAssertEqual(viewModel.wallets[0].networkName, "Mantle Network: $0.0 fee")
        XCTAssertEqual(viewModel.wallets[0].address, "0xINTEGRATION_TEST_ADDRESS")
        XCTAssertEqual(viewModel.copiedAddress, "wallet")
    }
    
    func testSingleWalletAddressFlow() {
        // Given
        let testJSON = """
        {
          "wallet_address": "0xSINGLE_WALLET_ADDRESS",
          "networks": [
            {
              "id": "mantle",
              "networkName": "Mantle Network: $0.0 fee",
              "gasToken": "MNT",
              "supportedCurrencies": ["USDT", "ETH"]
            },
            {
              "id": "arbitrumOne",
              "networkName": "Arbitrum One",
              "gasToken": "ETH",
              "supportedCurrencies": ["USDT: $0.0 fee", "ETH: $0.13 fee"]
            }
          ]
        }
        """
        
        mockRemoteConfigManager.setDonationConfig(testJSON)
        
        // When
        viewModel.loadWalletConfiguration()
        
        // Then
        // Verify all networks use the same address (UI displays one address for all networks)
        XCTAssertTrue(viewModel.wallets.allSatisfy { $0.address == "0xSINGLE_WALLET_ADDRESS" })
        XCTAssertEqual(viewModel.wallets.count, 2)
        
        // Test copying the main wallet address (new UI behavior)
        viewModel.copyToClipboard(address: "0xSINGLE_WALLET_ADDRESS", walletId: "wallet")
        XCTAssertEqual(viewModel.copiedAddress, "wallet")
    }
}

// MARK: - Model Tests (These don't depend on RemoteConfig)

extension DonationViewModelTests {
    
    func testNetworkItem_Codable() {
        // Given
        let networkItem = NetworkItem(
            id: "test_network",
            networkName: "Test Network: $0.5 fee",
            gasToken: "TEST",
            supportedCurrencies: ["USDT: $0.0 fee", "TEST: $1.0 fee"]
        )
        
        // When
        do {
            let jsonData = try JSONEncoder().encode(networkItem)
            let decodedItem = try JSONDecoder().decode(NetworkItem.self, from: jsonData)
            
            // Then
            XCTAssertEqual(decodedItem.id, networkItem.id)
            XCTAssertEqual(decodedItem.networkName, networkItem.networkName)
            XCTAssertEqual(decodedItem.gasToken, networkItem.gasToken)
            XCTAssertEqual(decodedItem.supportedCurrencies, networkItem.supportedCurrencies)
        } catch {
            XCTFail("Failed to encode/decode NetworkItem: \(error)")
        }
    }
    
    func testDonationStep_Codable() {
        // Given
        let donationStep = DonationStep(
            stepNumber: 1,
            description: "Go to Assets → Withdraw."
        )
        
        // When
        do {
            let jsonData = try JSONEncoder().encode(donationStep)
            let decodedStep = try JSONDecoder().decode(DonationStep.self, from: jsonData)
            
            // Then
            XCTAssertEqual(decodedStep.stepNumber, 1)
            XCTAssertEqual(decodedStep.description, "Go to Assets → Withdraw.")
        } catch {
            XCTFail("Failed to encode/decode DonationStep: \(error)")
        }
    }
    
    func testDonationInstructions_Codable() {
        // Given
        let instructions = DonationInstructions(
            instructionsTitle: "For Bybit Users:",
            donationSteps: [
                DonationStep(stepNumber: 1, description: "Go to Assets → Withdraw."),
                DonationStep(stepNumber: 2, description: "Select USDT, USDC, ETH, MNT, or ARB.")
            ],
            confirmationMessage: "✅ Your donation will be credited after one confirmation—usually within seconds."
        )
        
        // When
        do {
            let jsonData = try JSONEncoder().encode(instructions)
            let decodedInstructions = try JSONDecoder().decode(DonationInstructions.self, from: jsonData)
            
            // Then
            XCTAssertEqual(decodedInstructions.instructionsTitle, "For Bybit Users:")
            XCTAssertEqual(decodedInstructions.donationSteps.count, 2)
            XCTAssertEqual(decodedInstructions.donationSteps[0].stepNumber, 1)
            XCTAssertEqual(decodedInstructions.donationSteps[1].description, "Select USDT, USDC, ETH, MNT, or ARB.")
            XCTAssertEqual(decodedInstructions.confirmationMessage, "✅ Your donation will be credited after one confirmation—usually within seconds.")
        } catch {
            XCTFail("Failed to encode/decode DonationInstructions: \(error)")
        }
    }
    
    func testWalletResponse_Codable() {
        // Given
        let walletResponse = WalletResponse(
            wallet_address: "0xTEST_WALLET_ADDRESS",
            networks: [
                NetworkItem(
                    id: "test1",
                    networkName: "Test Network 1: $0.1 fee",
                    gasToken: "TEST1",
                    supportedCurrencies: ["USDT"]
                ),
                NetworkItem(
                    id: "test2",
                    networkName: "Test Network 2",
                    gasToken: "TEST2",
                    supportedCurrencies: ["ETH: $0.15 fee", "USDT: $0.0 fee"]
                )
            ],
            instructions: DonationInstructions(
                instructionsTitle: "Test Instructions:",
                donationSteps: [
                    DonationStep(stepNumber: 1, description: "Test step 1"),
                    DonationStep(stepNumber: 2, description: "Test step 2")
                ],
                confirmationMessage: "Test confirmation message"
            )
        )
        
        // When
        do {
            let jsonData = try JSONEncoder().encode(walletResponse)
            let decodedResponse = try JSONDecoder().decode(WalletResponse.self, from: jsonData)
            
            // Then
            XCTAssertEqual(decodedResponse.wallet_address, "0xTEST_WALLET_ADDRESS")
            XCTAssertEqual(decodedResponse.networks.count, 2)
            
            // Verify order is preserved
            XCTAssertEqual(decodedResponse.networks[0].id, "test1")
            XCTAssertEqual(decodedResponse.networks[1].id, "test2")
            XCTAssertEqual(decodedResponse.networks[0].networkName, "Test Network 1: $0.1 fee")
            XCTAssertEqual(decodedResponse.networks[1].supportedCurrencies, ["ETH: $0.15 fee", "USDT: $0.0 fee"])
            
            // Verify instructions
            XCTAssertNotNil(decodedResponse.instructions)
            XCTAssertEqual(decodedResponse.instructions?.instructionsTitle, "Test Instructions:")
            XCTAssertEqual(decodedResponse.instructions?.donationSteps.count, 2)
            XCTAssertEqual(decodedResponse.instructions?.donationSteps[0].stepNumber, 1)
            XCTAssertEqual(decodedResponse.instructions?.donationSteps[0].description, "Test step 1")
            XCTAssertEqual(decodedResponse.instructions?.confirmationMessage, "Test confirmation message")
        } catch {
            XCTFail("Failed to encode/decode WalletResponse: \(error)")
        }
    }
    
    func testDisplayWallet_InitFromNetworkItem() {
        // Given
        let networkItem = NetworkItem(
            id: "test",
            networkName: "Test Network: $0.2 fee",
            gasToken: "TEST",
            supportedCurrencies: ["USDT: $0.0 fee", "ETH: $0.13 fee", "TEST"]
        )
        let address = "0xTEST_ADDRESS"
        
        // When
        let displayWallet = DisplayWallet(address: address, networkItem: networkItem)
        
        // Then
        XCTAssertEqual(displayWallet.id, "test")
        XCTAssertEqual(displayWallet.networkName, "Test Network: $0.2 fee")
        XCTAssertEqual(displayWallet.address, "0xTEST_ADDRESS")
        XCTAssertEqual(displayWallet.currencies, ["USDT: $0.0 fee", "ETH: $0.13 fee", "TEST"])
    }
}
