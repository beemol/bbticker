//
//  FeatureGridView.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 20/08/2026.
//

import SwiftUI

// MARK: - Implementation plan (learning path: complex grids)
//
// Goal: page 2 — feature highlight cards.
//
// 1. `LazyVGrid` with an `.adaptive` column: the grid picks how many columns
//    fit for the available width (each ≥ 140 pt). No manual column math.
// 2. Cards use FIXED min-heights:
//    - Lazy grids only instantiate visible cells, but every cell must still
//      be measured when it appears. Fixed sizes keep scroll layout cheap and
//      predictable.
//    - Deliberately NO GeometryReader inside cells: a GeometryReader per cell
//      re-measures that cell on every scroll frame. Adaptive columns already
//      solve "how wide is my cell" — cells don't need geometry at all.
// 3. Later exercise: span the first card across both columns with
//    `.gridCellColumns(2)` (macOS 13+), and measure cell width once via a
//    background GeometryReader + preference if a card truly needs it.
struct FeatureGridView: View {
    private let features: [FeatureItem] = [
        FeatureItem(icon: "arrow.triangle.2.circlepath", title: "Live Equity", caption: "Menu bar balance, refreshed up to every second."),
        FeatureItem(icon: "circle.fill", title: "Risk Dot", caption: "Margin level at a glance — green to red."),
        FeatureItem(icon: "lock.shield", title: "Keychain", caption: "Keys encrypted at rest in the macOS Keychain."),
        FeatureItem(icon: "iphone", title: "Widget & Siri", caption: "Home screen widget and \"Hey Siri\" balance."),
        FeatureItem(icon: "bolt.circle", title: "Pro Speeds", caption: "Unlock 1 s, 5 s or 10 s refresh rates."),
    ]

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 140), spacing: 12)],
            spacing: 12
        ) {
            ForEach(features) { feature in
                FeatureCard(feature: feature)
            }
        }
    }
}

private struct FeatureItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let caption: String
}

private struct FeatureCard: View {
    let feature: FeatureItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: feature.icon)
                .font(.system(size: 18))
                .foregroundStyle(.tint)
            Text(feature.title)
                .font(.callout).bold()
            Text(feature.caption)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 86, alignment: .topLeading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.primary.opacity(0.05))
        )
    }
}

#Preview("Feature Grid") {
    FeatureGridView()
        .padding()
        .frame(width: 300)
}
