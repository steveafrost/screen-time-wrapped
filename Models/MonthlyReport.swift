import Foundation

/// A monthly screen time report — Pro feature.
struct MonthlyReport: Codable, Equatable, Identifiable {
    var id: String { "monthly-\(dateInterval.start.timeIntervalSince1970)" }

    let dateInterval: DateInterval
    let totalScreenTime: TimeInterval
    let dailyAverage: TimeInterval
    let totalPickups: Int
    let totalNotifications: Int
    let mostUsedApp: String
    let mostUsedAppDuration: TimeInterval
    let weeklyBreakdown: [WeeklyReport]
    let appBreakdown: [AppUsageItem]
    let categoryBreakdown: [CategoryUsageItem]
    let comparisons: [FunComparison]
    let vsPreviousMonth: MonthOverMonthChange?

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
        return "\(hours)h \(minutes)m"
    }

    static let preview = MonthlyReport(
        dateInterval: DateInterval(
            start: Calendar.current.date(byAdding: .month, value: -1, to: Date())!,
            end: Date()
        ),
        totalScreenTime: 676800,
        dailyAverage: 22560,
        totalPickups: 4800,
        totalNotifications: 3388,
        mostUsedApp: "TikTok",
        mostUsedAppDuration: 288000,
        weeklyBreakdown: Array(repeating: WeeklyReport.preview, count: 4),
        appBreakdown: ScreenTimeData.preview.appUsage,
        categoryBreakdown: ScreenTimeData.preview.categoryUsage,
        comparisons: FunComparison.previews,
        vsPreviousMonth: MonthOverMonthChange(
            screenTimeChange: 0.05,
            pickupsChange: -0.02,
            notificationsChange: 0.10
        )
    )
}

/// Month-over-month comparison.
struct MonthOverMonthChange: Codable, Equatable {
    let screenTimeChange: Double
    let pickupsChange: Double
    let notificationsChange: Double
}
