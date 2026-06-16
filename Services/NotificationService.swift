import Foundation
import UserNotifications

/// Manages weekly recap push notifications for Pro users.
class NotificationService: ObservableObject {
    @Published var isNotificationsEnabled = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let notificationCenter = UNUserNotificationCenter.current()

    /// Request notification permission from the user.
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            await MainActor.run {
                self.isNotificationsEnabled = granted
                self.authorizationStatus = granted ? .authorized : .denied
            }
            return granted
        } catch {
            await MainActor.run {
                self.authorizationStatus = .denied
            }
            return false
        }
    }

    /// Check current notification authorization status.
    func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
                self.isNotificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }

    /// Schedule a weekly recap notification (Pro feature).
    func scheduleWeeklyRecapNotification() {
        guard isNotificationsEnabled else { return }

        // Cancel any existing weekly recaps first
        cancelWeeklyRecapNotification()

        let content = UNMutableNotificationContent()
        content.title = "Your Weekly Wrapped is Ready! 🎉"
        content.body = "See how your screen time stacked up this week. New comparisons inside!"
        content.sound = .default
        content.userInfo = ["type": "weekly_recap"]

        // Schedule for every Sunday at 10:00 AM
        var dateComponents = DateComponents()
        dateComponents.weekday = 1  // Sunday
        dateComponents.hour = 10
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: "weekly_recap",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule weekly recap: \(error.localizedDescription)")
            }
        }
    }

    /// Schedule a test notification (fires in 5 seconds for debugging).
    func scheduleTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "ScreenTime Wrapped"
        content.body = "Your weekly recap is ready! Check it out."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(
            identifier: "test_notification",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request)
    }

    /// Cancel the weekly recap notification.
    func cancelWeeklyRecapNotification() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["weekly_recap"])
    }

    /// Cancel all pending notifications.
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    /// Get count of pending notifications.
    func pendingNotificationCount() async -> Int {
        let requests = await notificationCenter.pendingNotificationRequests()
        return requests.count
    }
}
