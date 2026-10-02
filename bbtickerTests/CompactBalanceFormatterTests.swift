import XCTest
@testable import bbticker

final class CompactBalanceFormatterTests: XCTestCase {
    func testDisplay_FormatsValuesBelowTheCompactThresholdWithRequestedPrecision() {
        XCTAssertEqual(CompactBalanceFormatter.display(999.9), "999.9")
        XCTAssertEqual(CompactBalanceFormatter.display(789.01, standardFractionDigits: 2), "789.01")
    }

    func testDisplay_FormatsTheThousandThresholdAndKValues() {
        XCTAssertEqual(CompactBalanceFormatter.display(1_000), "1K")
        XCTAssertEqual(CompactBalanceFormatter.display(1_001), "1K")
        XCTAssertEqual(CompactBalanceFormatter.display(1_049), "1K")
        XCTAssertEqual(CompactBalanceFormatter.display(1_050), "1.1K")
        XCTAssertEqual(CompactBalanceFormatter.display(12_345.67), "12.3K")
    }

    func testDisplay_PromotesRoundedKValuesToMillions() {
        XCTAssertEqual(CompactBalanceFormatter.display(999_949), "999.9K")
        XCTAssertEqual(CompactBalanceFormatter.display(999_950), "1M")
        XCTAssertEqual(CompactBalanceFormatter.display(999_999), "1M")
        XCTAssertEqual(CompactBalanceFormatter.display(1_250_000), "1.3M")
    }

    func testDisplay_FormatsNegativeCompactValues() {
        XCTAssertEqual(CompactBalanceFormatter.display(-1_250), "-1.3K")
    }

    func testDisplay_FormatsBillionValues() {
        XCTAssertEqual(CompactBalanceFormatter.display(1_000_000_000), "1B")
    }

    func testDisplay_HandlesInvalidNumericValuesSafely() {
        XCTAssertEqual(CompactBalanceFormatter.display(.nan), "n/a")
        XCTAssertEqual(CompactBalanceFormatter.display(.infinity), "n/a")
    }

    func testDisplayRawValue_PreservesNonNumericWidgetStates() {
        XCTAssertEqual(CompactBalanceFormatter.display(rawValue: "n/a"), "n/a")
        XCTAssertEqual(CompactBalanceFormatter.display(rawValue: "invalid"), "invalid")
    }
}
