import Foundation

enum CompactBalanceFormatter {
    private static let compactUnits: [(threshold: Decimal, suffix: String)] = [
        (Decimal(string: "1000000000")!, "B"),
        (Decimal(string: "1000000")!, "M"),
        (Decimal(string: "1000")!, "K")
    ]

    static func display(_ value: Double, standardFractionDigits: Int = 1) -> String {
        guard value.isFinite else { return "n/a" }

        let decimalValue = Decimal(string: String(value), locale: Locale(identifier: "en_US_POSIX")) ?? 0
        let magnitude = decimalValue < 0 ? -decimalValue : decimalValue

        guard let unit = compactUnits.first(where: { magnitude >= $0.threshold }) else {
            return String(
                format: "%.\(standardFractionDigits)f",
                locale: Locale(identifier: "en_US_POSIX"),
                value
            )
        }

        return compactDisplay(for: magnitude, isNegative: decimalValue < 0, unit: unit)
    }

    static func display(rawValue: String, standardFractionDigits: Int = 2) -> String {
        guard let value = Double(rawValue) else { return rawValue }
        return display(value, standardFractionDigits: standardFractionDigits)
    }

    private static func compactDisplay(
        for magnitude: Decimal,
        isNegative: Bool,
        unit: (threshold: Decimal, suffix: String)
    ) -> String {
        let scaledValue = roundedToOneDecimal(magnitude / unit.threshold)

        if scaledValue >= 1000,
           let unitIndex = compactUnits.firstIndex(where: { $0.threshold == unit.threshold }),
           unitIndex > 0 {
            return compactDisplay(
                for: magnitude,
                isNegative: isNegative,
                unit: compactUnits[unitIndex - 1]
            )
        }

        let sign = isNegative ? "-" : ""
        return "\(sign)\(NSDecimalNumber(decimal: scaledValue).stringValue)\(unit.suffix)"
    }

    private static func roundedToOneDecimal(_ value: Decimal) -> Decimal {
        var value = value
        var result = Decimal()
        NSDecimalRound(&result, &value, 1, .plain)
        return result
    }
}
