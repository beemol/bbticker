//
//  OnboardingPage.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 20/08/2026.
//

import SwiftUI

/// The five pages of the first-run tutorial, in order.
enum OnboardingPage: Int, CaseIterable, Identifiable {
    case welcome
    case features
    case security
    case setup
    case getStarted

    var id: Int { rawValue }

    // MARK: - Page details
    var title: String { "" }
    var subtitle: String { "" }
    var systemImage: String { "" }
    var accentColor: Color { .accentColor }
}
