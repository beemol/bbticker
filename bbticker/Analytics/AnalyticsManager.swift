import Foundation
import FirebaseAnalytics
import FirebaseCrashlytics

// MARK: - Analytics Event

enum AnalyticsEvent {
    case appLaunch
    case appLaunchTime(duration: TimeInterval)
    case connectionAttempt
    case connectionSuccess
    case disconnection(error: String)
    case settingsOpened
    case credentialsSaved
    case credentialsDeleted
    case apiSuccess(endpoint: String)
    case apiFailure(endpoint: String, error: String)
    case keychainError(operation: String, status: OSStatus)
    case widgetConfiguration(enabled: Bool, refreshInterval: Double)
    case unexpectedError(context: String, description: String)
    case settingsChange(key: String, newValue: String)
    case other(msg: String)
    
    var name: String {
        switch self {
        case .appLaunch:
            return "app_launch"
        case .appLaunchTime:
            return "app_launch_time"
        case .connectionAttempt:
            return "connection_attempt"
        case .connectionSuccess:
            return "connection_success"
        case .disconnection:
            return "disconnection"
        case .settingsOpened:
            return "settings_opened"
        case .credentialsSaved:
            return "credentials_saved"
        case .credentialsDeleted:
            return "credentials_deleted"
        case .apiSuccess:
            return "api_success"
        case .apiFailure:
            return "api_failure"
        case .keychainError:
            return "keychain_error"
        case .widgetConfiguration:
            return "widget_configured"
        case .unexpectedError:
            return "unexpected_error"
        case .settingsChange:
            return "settings_change"
        case .other:
            return "other"
        }
    }
    
    var parameters: [String: Any]? {
        switch self {
        case .appLaunch, .connectionAttempt, .connectionSuccess, .settingsOpened, .credentialsSaved, .credentialsDeleted, .settingsChange:
            return nil
            
        case .disconnection(let error):
            return ["error": error]
            
        case .appLaunchTime(let duration):
            return ["duration": duration]
            
        case .apiSuccess(let endpoint):
            return [
                "endpoint": endpoint
            ]
            
        case .apiFailure(let endpoint, let error):
            return [
                "endpoint": endpoint,
                "error": error
            ]
            
        case .keychainError(let operation, let status):
            return [
                "operation": operation,
                "status": Int(status)
            ]
            
        case .widgetConfiguration(let enabled, let refreshInterval):
            return [
                "enabled": enabled,
                "refresh_interval": refreshInterval
            ]
            
        case .unexpectedError(let context, let description):
            return [
                "context": context,
                "description": description
            ]
        case .other(let msg):
            return ["message": msg]
        }
    }
}

// MARK: - Analytics Manager Protocol
protocol AnalyticsManagerProtocol: Actor {
    var isEnabled: Bool { get set }
    func track(_ event: AnalyticsEvent)
}

// MARK: - Simple Firebase Analytics Manager
actor AnalyticsManager: AnalyticsManagerProtocol {
    private let defaults = UserDefaults.standard
    private let enabledKey = "analytics_enabled"

    // In-memory source of truth for quick reads
    private var _enabled: Bool
    
    static let shared = AnalyticsManager()

    private init() {
        let persisted = defaults.object(forKey: enabledKey) as? Bool ?? false
        _enabled = persisted
        
        if FirebaseBootstrap.isConfigured {
            // Keep Analytics and Crashlytics aligned (init previously only toggled Crashlytics).
            Analytics.setAnalyticsCollectionEnabled(persisted)
            Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(persisted)
        } else {
            // force-disable when firebase is not configured
            _enabled = false
        }
    }

    var isEnabled: Bool {
        get {
            _enabled
        }
        set {
            _enabled = newValue
            defaults.set(newValue, forKey: enabledKey)
            
            if FirebaseBootstrap.isConfigured {
                Analytics.setAnalyticsCollectionEnabled(newValue)
                Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(newValue)
            }
        }
    }
    
    func track(_ event: AnalyticsEvent) {
        guard FirebaseBootstrap.isConfigured, _enabled else { return }
        Analytics.logEvent(event.name, parameters: event.parameters)
    }
}
