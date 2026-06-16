import Foundation

/// A weekly screen time report containing summary stats and comparisons.
struct WeeklyReport: Codable, Equatable, Identifiable {
    var id: String { "weekly-\(dateInterval.start.timeIntervalSince1970)" }

    let dateInterval: DateInterval
    let totalScreenTime: TimeInterval
    let dailyAverage: TimeInterval
    let mostUsedApp: String
    let mostUsedAppDuration: TimeInterval
    let totalPickups: Int
    let averagePickupsPerDay: Int
    let totalNotifications: Int
    let averageNotificationsPerDay: Int
    let appBreakdown: [AppUsageItem]
    let categoryBreakdown: [CategoryUsageItem]
    let comparisons: [FunComparison]
    let peakUsageDay: String?
    let peakUsageDuration: TimeInterval?

    /// How this week compares to the previous week (percentage change).
    let vsPreviousWeek: WeekOverWeekChange?

    var formattedTotalTime: String {
        let hours = Int(totalScreenTime) / 3600
        let minutes = (Int(totalScreenTime) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var formattedDailyAverage: String {
        let hours = Int(dailyAverage) / 3600
        let minutes = (Int(dailyAverage) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    static let preview = WeeklyReport(
        dateInterval: DateInterval(
            start: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
            end: Date()
        ),
        totalScreenTime: 169200,
        dailyAverage: 24171,
        mostUsedApp: "TikTok",
        mostUsedAppDuration: 72000,
        totalPickups: 1200,
        averagePickupsPerDay: 171,
        totalNotifications: 847,
        averageNotificationsPerDay: 121,
        appBreakdown: ScreenTimeData.preview.appUsage,
        categoryBreakdown: ScreenTimeData.preview.categoryUsage,
        comparisons: FunComparison.previews,
        peakUsageDay: "Saturday",
        peakUsageDuration: 28800,
        vsPreviousWeek: WeekOverWeekChange(
            screenTimeChange: 0.12,
            pickupsChange: -0.05,
            notificationsChange: 0.08
        )
    )
}

/// A fun comparison stat for the recap cards.
struct FunComparison: Codable, Equatable, Identifiable {
    var id: String { title }
    let title: String
    let value: String
    let emoji: String
    let detail: String

    static let previews: [FunComparison] = [
        FunComparison(
            title: "TikTok Time",
            value: "= 94 episodes",
            emoji: "📺",
            detail: "That's enough to watch The Office (S1-4) twice!"
        ),
        FunComparison(
            title: "Pickups",
            value: "= 5x daily",
            emoji: "📱",
            detail: "Checking your phone every ~3 waking hours"
        ),
        FunComparison(
            title: "Notifications",
            value: "= 121/day",
            emoji: "🔔",
            detail: "That's one notification every 12 minutes"
        ),
        FunComparison(
            title: "Screen Time",
            value: "= 3 LOTR marathons",
            emoji: "🧙",
            detail: "Extended editions, naturally"
        ),
        FunComparison(
            title: "Total Time",
            value: "= 17 flights NYC→LA",
            emoji: "✈️",
            detail: "You could have crossed the US 17 times"
        ),
        FunComparison(
            title: "Your Year",
            value: "= 1 month/year",
            emoji: "📅",
            detail: "At this rate, 1 month per year on your phone"
        )
    ]
}

/// Week-over-week comparison.
struct WeekOverWeekChange: Codable, Equatable {
    let screenTimeChange: Double   // e.g. 0.12 = +12%
    let pickupsChange: Double
    let notificationsChange: Double
}
