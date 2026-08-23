//
//  SecurityPageView.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 20/08/2026.
//

import SwiftUI

// MARK: - Implementation plan (learning path: custom Layout)
//
// Goal: page 3 — trust content (read-only, no trading, Keychain) +
// analytics consent.
//
// 1. Permission badges use the custom `FlowLayout` (Layout/):
//    - The wrapping behavior comes from implementing `sizeThatFits`
//      (compute rows) and `placeSubviews` (mirror the same math to place).
//    - The view can't know badge widths in advance, so a custom layout is
//      the natural fit; a manual HStack would need GeometryReader hacks.
//    - We constrain the layout's width (`.frame(maxWidth:)`) so wrapping is
//      actually exercised in small popover widths.
// 2. Shield graphic: plain SF Symbol for now. Later exercise: re-draw it as
//    a `Canvas` (single draw pass, resolution-independent).
// 3. Consent toggle is intentionally local @State placeholder:
//    TODO: wire to the app's analytics switch — persist in UserDefaults
//    under "analytics_enabled" and call AnalyticsManager.setEnabled(_:),
//    exactly like SettingsViewModel.analyticsEnabledBinding does.
struct SecurityPageView: View {
    private let badges: [(icon: String, label: String)] = [
        ("eye", "Read-only"),
        ("xmark.circle", "Never trades"),
        ("lock.fill", "Keychain"),
    ]

    @State private var analyticsConsent = false

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 44))
                .foregroundStyle(.blue)

            FlowLayout(horizontalSpacing: 8, verticalSpacing: 8) {
                ForEach(badges, id: \.label) { badge in
                    chip(icon: badge.icon, label: badge.label)
                }
            }
            .frame(maxWidth: 240) // constrain so the flow actually wraps

            Divider()

            Toggle("Share anonymous usage data", isOn: $analyticsConsent)
                .toggleStyle(.switch)
                .font(.callout)
                .frame(maxWidth: 240)
        }
    }

    private func chip(icon: String, label: String) -> some View {
        Label(label, systemImage: icon)
            .font(.callout)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color.primary.opacity(0.08)))
    }
}

#Preview("Security") {
    SecurityPageView()
        .padding()
        .frame(width: 300)
}
