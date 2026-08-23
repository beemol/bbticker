//
//  SetupStepsView.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 20/08/2026.
//

import SwiftUI

// MARK: - Implementation plan (learning path: GeometryReader in a scrollable)
//
// Goal: page 4 — the API-key creation steps, scrollable, with a
// geometry-driven reveal effect (rows fade/slide in as they enter the
// viewport). This is the "GeometryReader inside a ScrollView" exercise.
//
// 1. GeometryReader #1 wraps the ScrollView: measures the viewport ONCE per
//    layout. The reveal math in every row references this height, so the
//    measurement is not repeated per row.
// 2. GeometryReader #2 sits INSIDE the scrollable, one per step row:
//    - `proxy.frame(in: .named("setupSteps"))` re-evaluates as the row
//      scrolls — that is the cost to understand: every GeometryReader row
//      participates in layout on every scroll frame.
//    - Fine for ~3-6 steps. Do NOT copy this pattern into long or lazy
//      lists (LazyVStack rows), where re-measurement multiplies.
//    - `containerRelativeFrame` / `onGeometryChange` (macOS 15+) are the
//      cheaper replacements — out of scope while the target is macOS 14.
// 3. Steps content comes from SettingsViewModel.loadAPIKeySteps()
//    (Remote Config with local JSON fallback) — the shell fetches and
//    passes them in. "Open Bybit" deep link is a later add.
struct SetupStepsView: View {
    var steps: [String]
    var notes: String?

    private static let scrollSpace = "setupSteps"

    var body: some View {
        // GeometryReader #1 — one viewport measurement (see plan above).
        GeometryReader { viewport in
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        stepRow(index: index, text: step, viewportHeight: viewport.size.height)
                    }
                    if let notes {
                        Text(notes)
                            .font(.caption).bold()
                            .foregroundStyle(.orange)
                            .padding(.top, 6)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .coordinateSpace(name: Self.scrollSpace)
        }
    }

    /// GeometryReader #2 — one per row, INSIDE the scrollable (see plan).
    private func stepRow(index: Int, text: String, viewportHeight: CGFloat) -> some View {
        GeometryReader { proxy in
            let rect = proxy.frame(in: .named(Self.scrollSpace))
            let distance = abs(rect.midY - viewportHeight / 2)
            // 1.0 at the viewport center → 0.0 at the edges.
            let reveal = max(0, min(1, 1 - distance / (viewportHeight * 0.6)))

            HStack(alignment: .top, spacing: 10) {
                Text("\(index + 1)")
                    .font(.callout.monospacedDigit().bold())
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(Color.accentColor))
                Text(text)
                    .font(.callout)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .opacity(0.35 + 0.65 * reveal) // never fully invisible
            .offset(y: 10 * (1 - reveal))
        }
        .frame(minHeight: 52) // stable row height keeps the geometry math sane
    }
}

#Preview("Setup Steps") {
    SetupStepsView(
        steps: [
            "Log into bybit.com and go to Account → API Management.",
            "Create a new API key with read-only wallet access.",
            "Copy the key and secret into BBTicker Settings.",
        ],
        notes: "Never grant trade or withdrawal permissions."
    )
    .frame(width: 300, height: 420)
}
