//
//  DotProgressLayout.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 20/08/2026.
//

import SwiftUI

/// Custom Layout for the page indicator dots — gap-aware sizing, emphasizes the active dot.
struct DotProgressLayout: Layout {
    var dotCount: Int
    var spacing: CGFloat = 8
    var activeDotSize: CGFloat = 10
    var inactiveDotSize: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        // TODO
        return proposal.replacingUnspecifiedDimensions()
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        // TODO
    }
}
