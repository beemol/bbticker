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
                print("✅ Siri authorization granted")
                
                // Donate the shortcut to help Siri learn the phrases
                Task {
                    do {
                        let intent = GetBalanceIntent()
                        try await intent.donate()
                        print("✅ Siri intent donated successfully")
                        
                    } catch {
                        print("❌ Failed to donate Siri intent: \(error)")
                    }
                }
                
                print("Siri setup complete - you can now say:")
                print("• 'Hey Siri, what's my \(getAppName()) balance?'")
                print("• 'Hey Siri, check my balance in \(getAppName())'")
                print("• 'Hey Siri, get my \(getAppName()) balance'")
                
                AnalyticsManager.shared.track(.other(msg: "siri_shortcut_setup"))
                
            case .denied:
                print("❌ Siri authorization denied")
                AnalyticsManager.shared.track(.other(msg: "siri_authorization_denied"))
                
            case .restricted:
                print("❌ Siri authorization restricted")
                AnalyticsManager.shared.track(.other(msg: "siri_authorization_restricted"))
                
            case .notDetermined:
                print("⚠️ Siri authorization not determined")
                
            @unknown default:
                print("⚠️ Unknown Siri authorization status")
            }
        }
    }
} 
#endif
