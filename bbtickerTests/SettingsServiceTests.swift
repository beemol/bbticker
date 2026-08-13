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
        XCTAssertEqual(mock.value(forKey: "selected_exchange_type") as? String, "kucoin:futures:production")
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

        XCTAssertEqual(service.state.exchangeType.environment, .production)
    }

    func testAPIEnvironment_SetToTestnet_SavesValue() {
        let mock = MockUserDataStorage()
        let service = SettingsService(storage: mock)

        service.setExchangeType(Exchange(.bybit, environment: .testnet, wallet: .unified))

        XCTAssertEqual(service.state.exchangeType.environment, .testnet)
        XCTAssertEqual(mock.value(forKey: "selected_exchange_type") as? String, "bybit:unified:testnet")
    }

    func testAPIEnvironment_SetToProduction_SavesValue() {
        let mock = MockUserDataStorage()
        let service = SettingsService(storage: mock)

        service.setExchangeType(Exchange(.bybit, environment: .testnet, wallet: .unified))
        service.setExchangeType(Exchange(.bybit, environment: .production, wallet: .unified))

        XCTAssertEqual(service.state.exchangeType.environment, .production)
        XCTAssertEqual(mock.value(forKey: "selected_exchange_type") as? String, "bybit:unified:production")
    }

    func testAPIEnvironment_LoadsStoredTestnetValue() {
        let mock = MockUserDataStorage()
        mock.save(key: "selected_exchange_type", value: "bybit:unified:testnet")

        let service = SettingsService(storage: mock)

        XCTAssertEqual(service.state.exchangeType.environment, .testnet)
    }

    func testAPIEnvironment_LegacyTwoPartValueDefaultsToProduction() {
        let mock = MockUserDataStorage()
        mock.save(key: "selected_exchange_type", value: "bybit:unified")

        let service = SettingsService(storage: mock)

        XCTAssertEqual(service.state.exchangeType.environment, .production)
    }

    func testAPIEnvironment_InvalidStoredValueFallsBackToProduction() {
        let mock = MockUserDataStorage()
        mock.save(key: "selected_exchange_type", value: "bybit:unified:invalid_env")

        let service = SettingsService(storage: mock)

        XCTAssertEqual(service.state.exchangeType.environment, .production)
    }

    func testAPIEnvironment_AvailableEnvironments_FromRegistry() {
        let mock = MockUserDataStorage()
        let service = SettingsService(storage: mock)

        let environments = service.availableAPIEnvironments

        XCTAssertFalse(environments.isEmpty, "Should return at least one environment for the default exchange")
        XCTAssertTrue(environments.contains(.production), "Should always include production")
    }

    func testSelectedAPIEnvironmentBinding_ReadsState() {
        let mock = MockUserDataStorage()
        mock.save(key: "selected_exchange_type", value: "bybit:unified:testnet")
        let service = SettingsService(storage: mock)

        let binding = service.selectedAPIEnvironmentBinding

        XCTAssertEqual(binding.wrappedValue, .testnet)
    }

    func testSelectedAPIEnvironmentBinding_WritesToService() {
        let mock = MockUserDataStorage()
        let service = SettingsService(storage: mock)

        let binding = service.selectedAPIEnvironmentBinding
        binding.wrappedValue = .testnet

        XCTAssertEqual(service.state.exchangeType.environment, .testnet)
        XCTAssertEqual(mock.value(forKey: "selected_exchange_type") as? String, "bybit:unified:testnet")
    }
}
