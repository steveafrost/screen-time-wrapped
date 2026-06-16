import Foundation

/// A yearly "ScreenTime Wrapped" report — Pro feature.
struct YearlyReport: Codable, Equatable, Identifiable {
    var id: String { "yearly-\(Calendar.current.component(.year, from: dateInterval.start))" }

    let dateInterval: DateInterval
    let totalScreenTime: TimeInterval
    let dailyAverage: TimeInterval
    let totalPickups: Int
    let totalNotifications: Int
    let mostUsedApp: String
    let mostUsedAppDuration: TimeInterval
    let totalUniqueAppsUsed: Int
    let monthlyBreakdown: [MonthlyReport]
    let appBreakdown: [AppUsageItem]
    let categoryBreakdown: [CategoryUsageItem]
    let comparisons: [FunComparison]
    let topFiveApps: [AppUsageItem]
    let worstDayDuration: TimeInterval?
    let worstDay: String?
    let bestDayDuration: TimeInterval?
    let bestDay: String?
    let peakMonth: String?
    let peakMonthDuration: TimeInterval?

    var formattedTotalTime: String {
        let days = Int(totalScreenTime) / 86400
        let hours = (Int(totalScreenTime) % 86400) / 3600
        if days > 0 {
            return "\(days)d \(hours)h"
        }
        return formattedTotalTimeShort
    }

    var formattedTotalTimeShort: String {
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

    /// A mind-blowing total like "You spent 24 days on your phone this year."
    var totalDaysFormatted: String {
        let days = Int(totalScreenTime) / 86400
        return "\(days) days"
    }

    static let preview = YearlyReport(
        dateInterval: DateInterval(
            start: Calendar.current.date(from: DateComponents(year: Calendar.current.component(.year, from: Date()) - 1, month: 1, day: 1))!,
            end: Date()
        ),
        totalScreenTime: 8121600,
        dailyAverage: 22251,
        totalPickups: 57600,
        totalNotifications: 40656,
        mostUsedApp: "TikTok",
        mostUsedAppDuration: 3456000,
        totalUniqueAppsUsed: 47,
        monthlyBreakdown: Array(repeating: MonthlyReport.preview, count: 12),
        appBreakdown: ScreenTimeData.preview.appUsage,
        categoryBreakdown: ScreenTimeData.preview.categoryUsage,
        comparisons: [
            FunComparison(
                title: "Total Time",
                value: "= 24 days",
                emoji: "📅",
                detail: "Over 3 weeks of your life on screen"
            ),
            FunComparison(
                title: "TikTok Time",
                value: "= 40 days",
                emoji: "🎵",
                detail: "You spent 40 full days scrolling TikTok"
            ),
            FunComparison(
                title: "Pickups",
                value: "= 57,600 times",
                emoji: "📱",
                detail: "That's like picking up your phone every 9 minutes"
            ),
            FunComparison(
                title: "Notifications",
                value: "= 40,656",
                emoji: "🔔",
                detail: "Average of 111 notifications per day"
            ),
            FunComparison(
                title: "Marathon",
                value: "= 97 LOTR marathons",
                emoji: "🧙",
                detail: "You could have watched LOTR extended 97 times"
            ),
            FunComparison(
                title: "Flight",
                value: "= 200 flights NYC→LA",
                emoji: "✈️",
                detail: "You could have flown cross-country 200 times"
            )
        ],
        topFiveApps: Array(ScreenTimeData.preview.appUsage.prefix(5)),
        worstDayDuration: 36000,
        worstDay: "Monday",
        bestDayDuration: 7200,
        bestDay: "Sunday",
        peakMonth: "January",
        peakMonthDuration: 720000
    )
}
