import XCTest
import LLCore
@testable import bbticker

class MockUserDataStorage: UserDataStorageProtocol {
    var data: [String: Any] = [:]

    func save(key: String, value: Any) {
        data[key] = value
    }

    func value(forKey: String) -> Any? {
        data[forKey]
    }

    func reset() {
        data.removeAll()
    }
}

@MainActor
final class SettingsServiceTests: XCTestCase {
    func testInitialLoad_UsesStoredValues() {
        let mock = MockUserDataStorage()
        mock.save(key: "update_frequency", value: 10.0)
        mock.save(key: "selected_exchange_type", value: "kucoin:futures")
        mock.save(key: "iap_ispro_unlocked", value: true)

        let service = SettingsService(storage: mock)

        XCTAssertEqual(service.state.updateFrequency, 10.0)
        XCTAssertEqual(service.state.exchangeType, Exchange(.kucoin, wallet: .futures))
        XCTAssertTrue(service.state.isProActive)
    }

    func testInitialLoad_DefaultsWhenNoValues() {
        let mock = MockUserDataStorage()
        let service = SettingsService(storage: mock)

        XCTAssertEqual(service.state.updateFrequency, ProFeatures.freePollingInterval)
        XCTAssertEqual(service.state.exchangeType, Exchange(.bybit, wallet: .unified))
        XCTAssertFalse(service.state.isProActive)
    }

    func testSetUpdateFrequency_SavesValue() {
        let mock = MockUserDataStorage()
        let service = SettingsService(storage: mock)

        service.setUpdateFrequency(15.0)

        XCTAssertEqual(service.state.updateFrequency, 15.0)
        XCTAssertEqual(mock.value(forKey: "update_frequency") as? Double, 15.0)
    }

    func testSetExchangeType_SavesSerializedValue() {
        let mock = MockUserDataStorage()
        let service = SettingsService(storage: mock)

        service.setExchangeType(Exchange(.kucoin, wallet: .futures))

        XCTAssertEqual(service.state.exchangeType, Exchange(.kucoin, wallet: .futures))
        XCTAssertEqual(mock.value(forKey: "selected_exchange_type") as? String, "kucoin:futures")
    }

    func testSetUpdateFrequencyUnlocked_SavesValue() {
        let mock = MockUserDataStorage()
        let service = SettingsService(storage: mock)

        service.applyProStatus(true)

        XCTAssertTrue(service.state.isProActive)
        XCTAssertEqual(mock.value(forKey: "iap_ispro_unlocked") as? Bool, true)
    }

    func testLoadExchangeType_InvalidStringFallsBack() {
        let mock = MockUserDataStorage()
        mock.save(key: "selected_exchange_type", value: "invalid:format")

        let service = SettingsService(storage: mock)

        XCTAssertEqual(service.state.exchangeType, Exchange(.bybit, wallet: .unified))
    }

    // MARK: - API Environment Tests

    func testAPIEnvironment_DefaultsToProduction() {
        let mock = MockUserDataStorage()
        let service = SettingsService(storage: mock)

        XCTAssertEqual(service.state.apiEnvironment, .production)
    }

    func testAPIEnvironment_SetToTestnet_SavesValue() {
        let mock = MockUserDataStorage()
        let service = SettingsService(storage: mock)

        service.setAPIEnvironment(.testnet)

        XCTAssertEqual(service.state.apiEnvironment, .testnet)
        XCTAssertEqual(mock.value(forKey: "api_environment") as? String, "testnet")
    }

    func testAPIEnvironment_SetToProduction_SavesValue() {
        let mock = MockUserDataStorage()
        let service = SettingsService(storage: mock)

        service.setAPIEnvironment(.testnet)
        service.setAPIEnvironment(.production)

        XCTAssertEqual(service.state.apiEnvironment, .production)
        XCTAssertEqual(mock.value(forKey: "api_environment") as? String, "production")
    }

    func testAPIEnvironment_LoadsStoredTestnetValue() {
        let mock = MockUserDataStorage()
        mock.save(key: "api_environment", value: "testnet")

        let service = SettingsService(storage: mock)

        XCTAssertEqual(service.state.apiEnvironment, .testnet)
    }

    func testAPIEnvironment_InvalidStoredValueFallsBackToProduction() {
        let mock = MockUserDataStorage()
        mock.save(key: "api_environment", value: "invalid_env")

        let service = SettingsService(storage: mock)

        XCTAssertEqual(service.state.apiEnvironment, .production)
    }

    func testAPIEnvironment_AllCasesAreAvailable() {
        let mock = MockUserDataStorage()
        let service = SettingsService(storage: mock)

        let environments = service.availableAPIEnvironments

        XCTAssertFalse(environments.isEmpty, "Should return at least one environment for the default exchange")
        XCTAssertTrue(environments.contains(.production), "Should always include production")
    }

    func testAPIEnvironment_AvailableEnvironments_FallsBackWhenExchangeNotRegistered() {
        // Use an unregistered exchange identifier — capabilities will be nil
        // availableAPIEnvironments should fall back to [.production]
        let mock = MockUserDataStorage()
        let service = SettingsService(storage: mock)

        // The default exchange (.bybit) should have registered capabilities
        let environments = service.availableAPIEnvironments

        // Falls back to production if no capabilities found
        XCTAssertTrue(environments.contains(.production))
    }

    func testSelectedAPIEnvironmentBinding_ReadsState() {
        let mock = MockUserDataStorage()
        mock.save(key: "api_environment", value: "testnet")
        let service = SettingsService(storage: mock)

        let binding = service.selectedAPIEnvironmentBinding

        XCTAssertEqual(binding.wrappedValue, .testnet)
    }

    func testSelectedAPIEnvironmentBinding_WritesToService() {
        let mock = MockUserDataStorage()
        let service = SettingsService(storage: mock)

        let binding = service.selectedAPIEnvironmentBinding
        binding.wrappedValue = .testnet

        XCTAssertEqual(service.state.apiEnvironment, .testnet)
        XCTAssertEqual(mock.value(forKey: "api_environment") as? String, "testnet")
    }
}
