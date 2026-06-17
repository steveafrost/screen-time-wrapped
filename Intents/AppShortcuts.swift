import Foundation
import AppIntents

/// Registers the app's Siri Shortcuts (App Intents) with the Shortcuts app.
/// No separate Intents Extension needed — App Intents are linked into the main app.
@available(iOS 16.0, *)
struct AppShortcuts: AppShortcutsProvider {
    /// The color used to badge the shortcut tiles in the Shortcuts app.
    static var shortcutTileColor: ShortcutTileColor = .purple

    /// The list of intents the app provides to the Shortcuts gallery.
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetScreenTimeIntent(),
            phrases: [
                "Get my screen time",
                "Show my screen time",
                "How much screen time do I have",
                "Check my screen time with \(.applicationName)",
                "Get screen time summary using \(.applicationName)",
            ],
            shortTitle: "Get Screen Time",
            systemImageName: "clock.fill"
        )

        AppShortcut(
            intent: GetWeeklyRecapIntent(),
            phrases: [
                "Open my weekly recap",
                "Show weekly recap",
                "View this week's screen time with \(.applicationName)",
                "Open weekly screen time recap",
            ],
            shortTitle: "Open Weekly Recap",
            systemImageName: "calendar.badge.clock"
        )
    }
}
