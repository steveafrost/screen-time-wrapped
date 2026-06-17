import Foundation
import AppIntents
import SwiftUI

/// App Intent that opens the app directly to the weekly recap view.
/// Uses the `openDestination` / `NSUserActivity` pattern.
@available(iOS 16.0, *)
struct GetWeeklyRecapIntent: AppIntent {
    // MARK: - AppIntent Conformance

    static let title: LocalizedStringResource = "Open Weekly Recap"

    static let description = IntentDescription(
        "Opens ScreenTime Wrapped directly to the weekly recap view.",
        categoryName: "Screen Time"
    )

    /// This intent opens the app when run.
    static let openAppWhenRun: Bool = true

    // MARK: - Parameters

    /// Optional parameter to specify whether to generate a fresh recap on open.
    @Parameter(
        title: "Refresh Data",
        description: "Fetch fresh screen time data when opening",
        default: false
    )
    var refreshData: Bool

    // MARK: - perform

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Create a user activity that the app's scene delegate / SwiftUI
        // can observe to navigate to the weekly recap tab.
        let activity = NSUserActivity(activityType: "com.steveafrost.ScreenTimeWrapped.weeklyRecap")
        activity.title = "Weekly Recap"
        activity.userInfo = [
            "refreshData": refreshData
        ]
        activity.isEligibleForHandoff = false

        // Update the UI via environment / scene connection
        ActivityBridge.shared.navigateToWeeklyRecap(refresh: refreshData)

        return .result(dialog: IntentDialog(stringLiteral: "Opening Weekly Recap…"))
    }
}

/// A small observable bridge so the intent can signal the SwiftUI app to navigate.
/// The app's root view observes this and acts on navigation requests.
@available(iOS 16.0, *)
@MainActor
class ActivityBridge: ObservableObject {
    static let shared = ActivityBridge()

    @Published var shouldNavigateToWeeklyRecap = false
    @Published var shouldRefreshData = false

    func navigateToWeeklyRecap(refresh: Bool) {
        shouldRefreshData = refresh
        shouldNavigateToWeeklyRecap = true
    }

    func consumeNavigation() {
        shouldNavigateToWeeklyRecap = false
        shouldRefreshData = false
    }
}
