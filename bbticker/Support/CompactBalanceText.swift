import SwiftUI

struct CompactBalanceText: View {
    private let displayValue: String

    init(_ value: Double, standardFractionDigits: Int = 1, prefix: String = "") {
        displayValue = prefix + CompactBalanceFormatter.display(
            value,
            standardFractionDigits: standardFractionDigits
        )
    }

    init(rawValue: String, standardFractionDigits: Int = 2, prefix: String = "") {
        displayValue = prefix + CompactBalanceFormatter.display(
            rawValue: rawValue,
            standardFractionDigits: standardFractionDigits
        )
    }

    var body: some View {
        Text(displayValue)
    }
}
