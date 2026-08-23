//
//  FlowLayout.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 20/08/2026.
//

import SwiftUI

// MARK: - Implementation plan (learning path: the Layout protocol)
//
// Goal: a wrapping layout (chips flow onto multiple lines like word-wrap).
//
// How the Layout protocol works here:
// 1. `sizeThatFits` — answer "how big would I be, given a proposal?" by
//    simulating the wrap: walk subviews, measuring each with
//    `subview.sizeThatFits(.unspecified)` (their ideal size), break to a new
//    row when the width budget is exceeded.
// 2. `placeSubviews` — now that we have a concrete `bounds`, mirror the same
//    wrap math and call `subview.place(at:proposal:)` for each child.
// 3. The two methods intentionally duplicate the math (the classic layout
//    smell); the `Cache` type is the sanctioned way to share work between
//    them when measurement gets expensive — we don't need it for ~5 chips.
// 4. Because this is a Layout, NOT views: no per-child view identity, no
//    intermediate layout views, and layout happens once per geometry change.
struct FlowLayout: Layout {
    var horizontalSpacing: CGFloat = 8
    var verticalSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var widestRow: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + verticalSpacing
                rowHeight = 0
            }
            x += size.width
            widestRow = max(widestRow, x)
            x += horizontalSpacing
            rowHeight = max(rowHeight, size.height)
        }

        let height = y + rowHeight
        return CGSize(width: min(widestRow, maxWidth), height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + verticalSpacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + horizontalSpacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview("FlowLayout") {
    FlowLayout(horizontalSpacing: 8, verticalSpacing: 8) {
        ForEach(["Read-only", "Never trades", "Keychain", "No withdrawals", "HTTPS only"], id: \.self) { text in
            Text(text)
                .font(.callout)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.primary.opacity(0.08)))
        }
    }
    .padding()
    .frame(width: 240)
}
