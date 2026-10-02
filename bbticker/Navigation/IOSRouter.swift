import Observation
import SwiftUI

@MainActor
@Observable
final class IOSRouter {
    enum Tab: Hashable {
        case dashboard
        case portfolio
        case activity
    }

    enum DashboardDestination: Hashable {
        case account(id: String)
    }

    enum ActivityDestination: Hashable {
        case transaction(id: String)
    }

    enum Sheet: Identifiable {
        case settings(section: SettingsSection?)
        case support

        var id: String {
            switch self {
            case .settings(let section):
                return "settings-\(section?.rawValue ?? "root")"
            case .support:
                return "support"
            }
        }
    }

    var selectedTab: Tab = .dashboard
    var dashboardPath: [DashboardDestination] = []
    var activityPath: [ActivityDestination] = []
    var presentedSheet: Sheet?

    func navigate(to route: AppRoute) {
        switch route {
        case .dashboard:
            presentedSheet = nil
            selectedTab = .dashboard
            dashboardPath = []

        case .account(let id):
            presentedSheet = nil
            selectedTab = .dashboard
            dashboardPath = [.account(id: id)]

        case .transaction(let id):
            presentedSheet = nil
            selectedTab = .activity
            activityPath = [.transaction(id: id)]

        case .settings(let section):
            presentedSheet = .settings(section: section)

        case .support:
            presentedSheet = .support
        }
    }
}
