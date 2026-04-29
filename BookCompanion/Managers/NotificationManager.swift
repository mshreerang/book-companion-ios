//
//  NotificationManager.swift
//  BookCompanion
//
//  Created by Shree on 21/04/2026.
//

import Foundation
import UserNotifications
import UIKit
import Combine

@MainActor
final class NotificationManager: NSObject, ObservableObject {

    static let shared = NotificationManager()

    override private init() {
        super.init()
        // Register as delegate so notifications show even when app is foregrounded
        UNUserNotificationCenter.current().delegate = self
    }
    // MARK: - Permission

    /// Call once after the user signs in.
    /// Does nothing if permission was already granted or denied.
    func requestPermission() {
        Task {
            let centre = UNUserNotificationCenter.current()
            let settings = await centre.notificationSettings()

            // Already decided — don't re-prompt
            guard settings.authorizationStatus == .notDetermined else {
                if settings.authorizationStatus == .authorized {
                    registerForRemoteNotifications()
                }
                return
            }

            do {
                let granted = try await centre.requestAuthorization(options: [.alert, .badge, .sound])
                if granted {
                    registerForRemoteNotifications()
                    print("✅ Push notifications authorised")
                } else {
                    print("ℹ️ Push notifications declined by user")
                }
            } catch {
                print("⚠️ Push permission request error: \(error)")
            }
        }
    }

    // MARK: - APNs Registration

    @MainActor
    private func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }

    // MARK: - Token Registration

    /// Called from BookCompanionApp when APNs returns a device token.
    /// Converts raw Data → hex string and POSTs to backend.
    func registerToken(_ tokenData: Data) {
        let token = tokenData.map { String(format: "%02x", $0) }.joined()
        print("📱 APNs token: \(token)")

        Task {
            await sendTokenToBackend(token)
        }
    }

    // MARK: - Local Notifications

    /// Schedule a local notification when the user hits 4/5 summaries.
    /// Called from UsageManager whenever usage is updated.
    /// Safe to call multiple times — deduped by notification identifier.
    func scheduleQuotaWarning(used: Int, limit: Int) {
        print("🔔 scheduleQuotaWarning called: used=\(used), limit=\(limit)")
        guard used == limit - 1 else { return }

        let centre = UNUserNotificationCenter.current()
        // Remove any existing quota warning first — prevents duplicates
        centre.removePendingNotificationRequests(withIdentifiers: ["quota_warning"])

        let content = UNMutableNotificationContent()
        content.title = "1 summary remaining this month"
        content.body  = "Upgrade to Pro or get more credits to keep going."
        content.sound = .default
        content.badge = 1

        // Fire after 1 second (timeInterval must be > 0)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "quota_warning",
            content: content,
            trigger: trigger
        )

        centre.add(request) { error in
            if let error {
                print("⚠️ Failed to schedule quota warning: \(error)")
            } else {
                print("✅ Quota warning notification scheduled")
            }
        }
    }
    
    /// Schedule a feature discovery nudge 20 minutes after a summary is generated.
    /// Fires only if the user hasn't opened character chat before.
    /// Cancelled automatically if they open chat before it fires.
    func scheduleCharacterChatDiscovery(bookTitle: String) {
        // Don't nudge if user has already discovered chat
        let hasSeenChat = UserDefaults.standard.bool(forKey: "hasSeenChatDisclaimer")
        guard !hasSeenChat else { return }

        let centre = UNUserNotificationCenter.current()

        // Cancel any existing discovery nudge — only one at a time
        centre.removePendingNotificationRequests(withIdentifiers: ["chat_discovery"])

        let content = UNMutableNotificationContent()
        content.title = "Did you know? 💬"
        content.body  = "You can chat with the characters from \"\(bookTitle)\" — spoiler-safe up to your chapter."
        content.sound = .default

        // Fire after 20 minutes
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 20 * 60, repeats: false)
        let request = UNNotificationRequest(
            identifier: "chat_discovery",
            content: content,
            trigger: trigger
        )

        centre.add(request) { error in
            if let error {
                print("⚠️ Failed to schedule chat discovery nudge: \(error)")
            } else {
                print("✅ Chat discovery nudge scheduled (20 mins)")
            }
        }
    }

    /// Cancel the chat discovery nudge — called when user opens character chat.
    func cancelCharacterChatDiscovery() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["chat_discovery"])
        print("✅ Chat discovery nudge cancelled — user opened chat")
    }

    /// Clear the quota warning badge when user opens the app.
    /// Called from BookCompanionApp on .active scenePhase.
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error {
                print("⚠️ Failed to clear badge: \(error)")
            }
        }
    }

    // MARK: - Backend Sync

    private func sendTokenToBackend(_ deviceToken: String) async {
        guard let jwtToken = KeychainManager.shared.getUserToken() else {
            print("ℹ️ No JWT — skipping push token registration (user not signed in)")
            return
        }

        let environment: String
        #if DEBUG
        environment = "sandbox"
        #else
        environment = "production"
        #endif

        guard let url = URL(string: "\(Config.apiEndpoint)/api/push/register") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "deviceToken": deviceToken,
            "environment": environment
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (_, response) = try await URLSession.shared.data(for: request)

            if let http = response as? HTTPURLResponse {
                if http.statusCode == 200 {
                    print("✅ Push token registered with backend")
                } else {
                    print("⚠️ Push token registration failed — HTTP \(http.statusCode)")
                }
            }
        } catch {
            // Non-fatal — app works fine without push
            print("⚠️ Push token registration network error: \(error)")
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
//
// Allows notifications to display as banners even when the app is foregrounded.
// Without this, local notifications are silently suppressed while the app is active.
// After the user backgrounds or closes the app, notifications appear normally
// in the notification centre and as an app icon badge — this delegate just
// ensures they also show immediately if the app is open.

extension NotificationManager: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner + badge + sound even when app is in foreground
        completionHandler([.banner, .badge, .sound])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier
        let title = response.notification.request.content.title
        print("📬 Notification tapped: \(identifier)")

        // Track notification tap — tells us if notifications convert to app opens
        Task { @MainActor in
            AnalyticsManager.shared.track(
                event: "notification_tapped",
                properties: [
                    "notification_id":    identifier,
                    "notification_title": title
                ]
            )
        }
        completionHandler()
    }
}
