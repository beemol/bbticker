//
//  GetStartedView.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 20/08/2026.
//

import SwiftUI

// MARK: - Implementation plan
//
// Goal: page 5 — final CTA that hands off to the Settings window.
//
// 1. The shell renders the page header (title/subtitle from OnboardingPage);
//    this view only carries the call-to-action.
// 2. "Open Settings" invokes the injected closure (the app opens its
//    Settings window/scene). The hosting shell is responsible for calling
//    `store.complete()` once the user lands in Settings, so the tutorial
//    never reappears.
// 3. Accessibility identifier is set for UI tests (AccessibilityID).
// 4. Later exercise: inline "Skip" affordance wired to `store.skip()`, and
//    a subtle success animation (Canvas confetti) — both are additive.
struct GetStartedView: View {
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)

            Button(action: onOpenSettings) {
                Label("Open Settings", systemImage: "gearshape")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier(AccessibilityID.onboardingOpenSettingsButton)
            .padding(.top, 8)
        }
        .frame(maxWidth: 240)
    }
}

#Preview("Get Started") {
    GetStartedView(onOpenSettings: {
        // no-op in preview
    })
    .padding()
    .frame(width: 300)
}
