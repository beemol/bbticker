//
//  OnboardingView.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 20/08/2026.
//

import SwiftUI

/// Cross-platform paging shell for the onboarding flow.
/// Used inside the macOS tutorial popover and as an iOS full screen cover.
struct OnboardingView: View {
    @Bindable var store: OnboardingStore
    let onOpenSettings: () -> Void

    var body: some View {
        EmptyView()
        // TODO: paging container (TabView(.page) / ScrollView with GeometryReader),
        // DotProgressLayout page indicator, Skip / Next / Get Started actions
    }
}
