//
//  NotificationService.swift
//  bbticker
//
//  Created by Aleh Fiodarau on 13/09/2026.
//

import Foundation
import UserNotifications

#if !os(macOS)

/// Thin wrapper around `UNUserNotificationCenter` for local notifications.
final class NotificationService: NSObject, UNUserNotificationCenterDelegate, Sendable {
    static let shared = NotificationService()

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    /// Requests authorization to present alerts, sounds and badges.
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            AppLog.background.info("Notification permission granted: \(granted)")
            return granted
        } catch {
            AppLog.background.error("Notification authorization failed: \(error.localizedDescription)")
            return false
        }
    }

    /// Checks current authorization status without prompting.
    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    /// Posts an immediate local notification with the current equity.
    func postBalanceNotification(totalEquity: Double) {
        let content = UNMutableNotificationContent()
        content.title = "Balance Update"
        content.body = String(format: "Your current equity is $%.2f", totalEquity)
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // deliver immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                AppLog.background.error("Failed to post balance notification: \(error.localizedDescription)")
            } else {
                AppLog.background.info("Successfully scheduled local balance notification for $\(String(format: "%.2f", totalEquity))")
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate
    // Allows notifications to show banner/sound even if the app is currently in the foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge, .list])
    }
}

#endif
