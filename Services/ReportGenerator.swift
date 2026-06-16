import Foundation

/// Generates screen time reports (weekly, monthly, yearly) from raw ScreenTimeData.
class ReportGenerator {

    // MARK: - Comparison Engine

    /// Fun fact database mapping hours to relatable comparisons.
    static let comparisonDatabase: [(threshold: TimeInterval, label: String, emoji: String, detail: String)] = [
        (3600, "= 2 episodes of The Office", "📺", "That's a solid lunch break binge."),
        (7200, "= 1 LOTR: Return of the King", "🧙", "Extended edition, naturally."),
        (10800, "= 6 episodes of Stranger Things", "👾", "Almost one full season!"),
        (14400, "= 1 round-trip NYC→LA", "✈️", "You could have flown cross-country."),
        (21600, "= 3 Olympic marathons", "🏃", "Without the training."),
        (28800, "= All Harry Potter movies (extended)", "⚡", "Goblet of Fire included."),
        (43200, "= 24 episodes of Breaking Bad", "🧪", "One full season, no commercials."),
        (72000, "= 94 episodes of The Office", "📺", "Seasons 1-4, twice!"),
        (86400, "= 1 full day", "📅", "24 hours. Gone."),
        (169200, "= 3 LOTR extended marathons", "🧙", "Even Gollum is impressed."),
        (259200, "= 1 month of work", "💼", "40-hour weeks. You clocked 72."),
        (432000, "= 10 flights around the world", "🌍", "Literally around the globe."),
        (604800, "= 1 week of your life", "⏰", "Gone to the screen."),
        (2629746, "= 1 month on your phone", "📱", "1/12 of your year on screen."),
        (31556952, "= 24 complete days", "📅", "Almost a full month of your year.")
    ]

    /// Generate a weekly report from raw data.
    func generateWeeklyReport(from data: ScreenTimeData) -> WeeklyReport {
        let calendar = Calendar.current
        let totalDays = max(1, calculateDays(in: data.dateInterval))

        let dailyAverage = data.totalScreenTime / Double(totalDays)
        let avgPickups = data.pickups / totalDays
        let avgNotifications = data.notificationsReceived / totalDays

        // Find the most-used app
        let topApp = data.appUsage
            .sorted { $0.duration > $1.duration }
            .first

        // Determine peak day (simplified — in real impl, use per-day data)
        let peakDay: String? = nil
        let peakDuration: TimeInterval? = nil

        // Generate fun comparisons
        let comparisons = generateComparisons(from: data, reportType: "weekly")

        // Week-over-week change (simulated for now)
        let vsPrevious = WeekOverWeekChange(
            screenTimeChange: Double.random(in: -0.15...0.25),
            pickupsChange: Double.random(in: -0.10...0.10),
            notificationsChange: Double.random(in: -0.20...0.20)
        )

        return WeeklyReport(
            dateInterval: data.dateInterval ?? DateInterval(
                start: calendar.date(byAdding: .day, value: -7, to: Date())!,
                end: Date()
            ),
            totalScreenTime: data.totalScreenTime,
            dailyAverage: dailyAverage,
            mostUsedApp: topApp?.appName ?? "Unknown",
            mostUsedAppDuration: topApp?.duration ?? 0,
            totalPickups: data.pickups,
            averagePickupsPerDay: avgPickups,
            totalNotifications: data.notificationsReceived,
            averageNotificationsPerDay: avgNotifications,
            appBreakdown: data.appUsage,
            categoryBreakdown: data.categoryUsage,
            comparisons: comparisons,
            peakUsageDay: peakDay,
            peakUsageDuration: peakDuration,
            vsPreviousWeek: vsPrevious
        )
    }

    /// Generate a monthly report from raw data.
    func generateMonthlyReport(from data: ScreenTimeData) -> MonthlyReport {
        let calendar = Calendar.current
        let totalDays = max(1, calculateDays(in: data.dateInterval))
        let dailyAverage = data.totalScreenTime / Double(totalDays)
        let avgPickups = data.pickups / totalDays
        let avgNotifications = data.notificationsReceived / totalDays

        let topApp = data.appUsage
            .sorted { $0.duration > $1.duration }
            .first

        let comparisons = generateComparisons(from: data, reportType: "monthly")

        return MonthlyReport(
            dateInterval: data.dateInterval ?? DateInterval(
                start: calendar.date(byAdding: .month, value: -1, to: Date())!,
                end: Date()
            ),
            totalScreenTime: data.totalScreenTime,
            dailyAverage: dailyAverage,
            totalPickups: data.pickups,
            totalNotifications: data.notificationsReceived,
            mostUsedApp: topApp?.appName ?? "Unknown",
            mostUsedAppDuration: topApp?.duration ?? 0,
            weeklyBreakdown: [], // Would split data into weekly chunks
            appBreakdown: data.appUsage,
            categoryBreakdown: data.categoryUsage,
            comparisons: comparisons,
            vsPreviousMonth: MonthOverMonthChange(
                screenTimeChange: Double.random(in: -0.10...0.20),
                pickupsChange: Double.random(in: -0.08...0.12),
                notificationsChange: Double.random(in: -0.15...0.15)
            )
        )
    }

    /// Generate a yearly "Wrapped" report from raw data.
    func generateYearlyReport(from data: ScreenTimeData) -> YearlyReport {
        let calendar = Calendar.current
        let totalDays = max(1, calculateDays(in: data.dateInterval))
        let dailyAverage = data.totalScreenTime / Double(totalDays)

        let sortedApps = data.appUsage
            .sorted { $0.duration > $1.duration }
        let topApp = sortedApps.first

        let comparisons = generateComparisons(from: data, reportType: "yearly")

        return YearlyReport(
            dateInterval: data.dateInterval ?? DateInterval(
                start: calendar.date(from: DateComponents(year: calendar.component(.year, from: Date()), month: 1, day: 1))!,
                end: Date()
            ),
            totalScreenTime: data.totalScreenTime,
            dailyAverage: dailyAverage,
            totalPickups: data.pickups,
            totalNotifications: data.notificationsReceived,
            mostUsedApp: topApp?.appName ?? "Unknown",
            mostUsedAppDuration: topApp?.duration ?? 0,
            totalUniqueAppsUsed: data.appUsage.count,
            monthlyBreakdown: [],
            appBreakdown: data.appUsage,
            categoryBreakdown: data.categoryUsage,
            comparisons: comparisons,
            topFiveApps: Array(sortedApps.prefix(5)),
            worstDayDuration: nil,
            worstDay: nil,
            bestDayDuration: nil,
            bestDay: nil,
            peakMonth: nil,
            peakMonthDuration: nil
        )
    }

    // MARK: - Comparisons

    /// Generate fun comparisons for a report based on total screen time.
    private func generateComparisons(from data: ScreenTimeData, reportType: String) -> [FunComparison] {
        var comparisons: [FunComparison] = []
        let totalHours = data.totalScreenTime / 3600

        // Add time-based comparisons
        let matchedComparisons = Self.comparisonDatabase
            .filter { totalHours * 3600 >= $0.threshold }
            .prefix(4)
            .map { FunComparison(title: "Screen Time", value: $0.label, emoji: $0.emoji, detail: $0.detail) }
        comparisons.append(contentsOf: matchedComparisons)

        // Pickup comparison
        if data.pickups > 0 {
            let pickupsPerDay = max(1, data.pickups / max(1, calculateDays(in: data.dateInterval)))
            comparisons.append(FunComparison(
                title: "Pickups",
                value: "= \(pickupsPerDay)x/day",
                emoji: "📱",
                detail: "Checking your phone ~every \(max(1, 16 / pickupsPerDay)) waking minutes"
            ))
        }

        // Notification comparison
        if data.notificationsReceived > 0 {
            let notifsPerDay = max(1, data.notificationsReceived / max(1, calculateDays(in: data.dateInterval)))
            comparisons.append(FunComparison(
                title: "Notifications",
                value: "= \(notifsPerDay)/day",
                emoji: "🔔",
                detail: "One notification every \(max(1, 1440 / notifsPerDay)) minutes"
            ))
        }

        // Top app comparison
        if let topApp = data.appUsage.sorted(by: { $0.duration > $1.duration }).first {
            let topAppHours = topApp.duration / 3600
            if topAppHours >= 1 {
                comparisons.append(FunComparison(
                    title: "\(topApp.appName) Time",
                    value: "= \(Int(topAppHours))h total",
                    emoji: "📊",
                    detail: "Your most-used app this period"
                ))
            }
        }

        // Yearly special: total days comparison
        if reportType == "yearly" {
            let totalDays = Int(data.totalScreenTime / 86400)
            if totalDays >= 1 {
                comparisons.append(FunComparison(
                    title: "Your Year",
                    value: "= \(totalDays) days",
                    emoji: "📅",
                    detail: "That's \(totalDays) full days on your phone this year"
                ))
            }
        }

        return comparisons
    }

    // MARK: - Helpers

    private func calculateDays(in interval: DateInterval?) -> Int {
        guard let interval = interval else { return 7 }
        let days = Int(interval.duration / 86400)
        return max(1, days)
    }
}
