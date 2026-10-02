//
//  IOSRouter.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 9/29/26.
//


import Observation
import SwiftUI

@MainActor
@Observable
final class IOSRouter {
    enum Sheet: Identifiable, Equatable {
        case settings(section: SettingsSection?)

        var id: String {
            switch self {
            case .settings(let section):
                return "settings-\(section?.rawValue ?? "root")"
            }
        }
    }

    var presentedSheet: Sheet?

    func navigate(to route: AppRoute) {
        switch route {
        case .settings(let section):
            presentedSheet = .settings(section: section)
        }
    }
}
