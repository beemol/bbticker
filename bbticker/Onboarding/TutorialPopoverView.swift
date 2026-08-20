//
//  TutorialPopoverView.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 20/08/2026.
//

import SwiftUI

#if os(macOS)
/// macOS presentation of the tutorial: the onboarding flow rendered
/// inside the menu bar popover on first launch.
struct TutorialPopoverView: View {
    @Bindable var store: OnboardingStore
    let onOpenSettings: () -> Void

    var body: some View {
        EmptyView()
        // TODO: present OnboardingView when store.needsOnboarding,
        // fall back to the regular popover content otherwise
    }
}
#endif
