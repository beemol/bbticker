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
        TabView(selection: $store.currentPage) {
            ForEach(OnboardingPage.allCases) { page in
                VStack(spacing: 16) {
                    header(for: page)          // ← uses title, subtitle, systemImage, accentColor
                    //uniqueContent(for: page)   // ← the page-specific view
                }
                .tag(page.rawValue)
            }
        }
        
        Divider()
        
        HStack {
            Button {
                store.previous()
            } label: {
                Label("Back", systemImage: "chevron.left")
            }
            .disabled(store.currentPage == 0)
            
            Spacer()
            
            Text("\(store.currentPage + 1) / \(store.pageCount)")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Button {
                store.next()
            } label: {
                Label("Next", systemImage: "chevron.right")
            }
            .disabled(store.currentPage == store.pageCount - 1)
        }
    }
}
#endif

@ViewBuilder
private func header(for page: OnboardingPage) -> some View {
    VStack(spacing: 8) {
        Image(systemName: page.systemImage)
            .font(.system(size: 40))
            .foregroundStyle(page.accentColor)
        Text(page.title)
            .font(.title2).bold()
        Text(page.subtitle)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
    }
}

#Preview("Tutorial Popover") {
    TutorialPopoverView(store: OnboardingStore()) {
    }
    .padding()
}
