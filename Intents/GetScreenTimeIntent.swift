import Foundation
import AppIntents
import SwiftUI

/// App Intent that returns today's total screen time as a string.
/// Available via Siri Shortcuts on iOS 16+.
@available(iOS 16.0, *)
struct GetScreenTimeIntent: AppIntent {
    // MARK: - AppIntent Conformance

    static let title: LocalizedStringResource = "Get My Screen Time"

    static let description = IntentDescription(
        "Returns your total screen time for today as a formatted string.",
        categoryName: "Screen Time"
    )

    static let openAppWhenRun: Bool = false

    // MARK: - Parameters

    /// Optional: if true, returns a more detailed breakdown instead of just the total.
    @Parameter(
        title: "Detailed",
        description: "Show detailed breakdown instead of just total time",
        default: false
    )
    var detailed: Bool

    // MARK: - perform

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let service = ScreenTimeService()

        // Use the service's fetch to get today's data (falls back to preview data)
        let data = await service.fetchWeeklyData()

        // Format the total time
        let totalSeconds = data.totalScreenTime
        let hours = Int(totalSeconds) / 3600
        let minutes = (Int(totalSeconds) % 3600) / 60
        let totalFormatted: String
        if hours > 0 {
            totalFormatted = "\(hours)h \(minutes)m"
        } else {
            totalFormatted = "\(minutes)m"
        }

        if detailed {
            // Build a detailed summary
            let pickups = data.pickups
            let notifications = data.notificationsReceived
            let topApp = data.appUsage
                .sorted(by: { $0.duration > $1.duration })
                .first

            var detail = "Today's screen time: \(totalFormatted)."
            detail += "\nPickups: \(pickups)"
            detail += "\nNotifications: \(notifications)"
            if let top = topApp {
                let topHours = Int(top.duration) / 3600
                let topMins = (Int(top.duration) % 3600) / 60
                detail += "\nMost used: \(top.appName) (\(topHours)h \(topMins)m)"
            }

            return .result(dialog: IntentDialog(stringLiteral: detail))
        } else {
            let message = "You have \(totalFormatted) of screen time today."
            return .result(dialog: IntentDialog(stringLiteral: message))
        }
    }
}
