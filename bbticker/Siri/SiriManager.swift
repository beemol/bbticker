import Foundation
import AppIntents
import Intents

// MARK: - Simple Siri Manager
#if !os(macOS)
class SiriManager {
    static let shared = SiriManager()
    
    private init() {}
    
    func setupModernSiri() {
        // Force update app shortcuts with the system
        // This is crucial after app reinstall or updates
        
        BalanceShortcutsProvider.updateAppShortcutParameters()
//        Task {
//            do {
//                try await BalanceShortcutsProvider.updateAppShortcutParameters()
//                print("✅ App shortcuts updated successfully")
//            } catch {
//                print("⚠️ Failed to update app shortcuts: \(error)")
//            }
//        }
        
        // Request Siri authorization first
        INPreferences.requestSiriAuthorization { status in
            switch status {
            case .authorized:
                AppLog.siri.info("Siri authorization granted")
                
                // Donate the shortcut to help Siri learn the phrases
                Task {
                    do {
                        let intent = GetBalanceIntent()
                        try await intent.donate()
                        // print("✅ Siri intent donated successfully")
                        
                    } catch {
                        AppLog.siri.error("Failed to donate Siri intent: \(error)")
                    }
                }
                
                AnalyticsManager.shared.track(.other(msg: "siri_shortcut_setup"))
                
            case .denied:
                AppLog.siri.warning("Siri authorization denied")
                AnalyticsManager.shared.track(.other(msg: "siri_authorization_denied"))
                
            case .restricted:
                AppLog.siri.warning("Siri authorization restricted")
                AnalyticsManager.shared.track(.other(msg: "siri_authorization_restricted"))
                
            case .notDetermined:
                // print("⚠️ Siri authorization not determined")
                break
                
            @unknown default:
                // print("⚠️ Unknown Siri authorization status")
                break
            }
        }
    }
} 
#endif
