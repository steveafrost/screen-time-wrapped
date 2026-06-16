import Foundation
import FamilyControls
import ManagedSettings

/// Raw screen time data fetched from the DeviceActivity framework.
struct ScreenTimeData: Codable, Equatable {
    var totalScreenTime: TimeInterval        // Total screen time in seconds
    var appUsage: [AppUsageItem]             // Per-app breakdown
    var notificationsReceived: Int           // Total notifications
    var notificationsByApp: [String: Int]    // Notifications per app
    var pickups: Int                         // Total device pickups
    var pickupsByApp: [String: Int]          // Pickups per app
    var firstPickup: Date?                   // First pickup of day
    var lastPickup: Date?                    // Last pickup of day
    var dateInterval: DateInterval?          // The date range this data covers
    var categoryUsage: [CategoryUsageItem]   // Usage by category (social, productivity, etc.)

    static let empty = ScreenTimeData(
        totalScreenTime: 0,
        appUsage: [],
        notificationsReceived: 0,
        notificationsByApp: [:],
        pickups: 0,
        pickupsByApp: [:],
        firstPickup: nil,
        lastPickup: nil,
        dateInterval: nil,
        categoryUsage: []
    )

    static let preview = ScreenTimeData(
        totalScreenTime: 169200, // 47 hours
        appUsage: [
            AppUsageItem(appName: "TikTok", category: .social, duration: 72000, identifier: "com.bytedance.tiktok"),
            AppUsageItem(appName: "Instagram", category: .social, duration: 28800, identifier: "com.instagram"),
            AppUsageItem(appName: "YouTube", category: .entertainment, duration: 21600, identifier: "com.google.ios.youtube"),
            AppUsageItem(appName: "Messages", category: .communication, duration: 14400, identifier: "com.apple.MobileSMS"),
            AppUsageItem(appName: "Safari", category: .productivity, duration: 10800, identifier: "com.apple.mobilesafari"),
            AppUsageItem(appName: "Spotify", category: .entertainment, duration: 7200, identifier: "com.spotify.client"),
            AppUsageItem(appName: "Mail", category: .productivity, duration: 3600, identifier: "com.apple.mobilemail"),
            AppUsageItem(appName: "Chrome", category: .productivity, duration: 3600, identifier: "com.google.chrome.ios"),
            AppUsageItem(appName: "Twitter", category: .social, duration: 5400, identifier: "com.twitter.ios"),
            AppUsageItem(appName: "Reddit", category: .social, duration: 5400, identifier: "com.reddit.Reddit")
        ],
        notificationsReceived: 847,
        notificationsByApp: [
            "Messages": 245,
            "Instagram": 186,
            "TikTok": 142,
            "Mail": 98,
            "Twitter": 76,
            "Reddit": 52,
            "YouTube": 30,
            "Spotify": 18
        ],
        pickups: 1200,
        pickupsByApp: [
            "Messages": 320,
            "Instagram": 285,
            "TikTok": 240,
            "Twitter": 105,
            "Reddit": 80,
            "YouTube": 65,
            "Mail": 55,
            "Spotify": 50
        ],
        firstPickup: Calendar.current.date(bySettingHour: 6, minute: 45, second: 0, of: Date()),
        lastPickup: Calendar.current.date(bySettingHour: 23, minute: 30, second: 0, of: Date()),
        dateInterval: DateInterval(
            start: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
            end: Date()
        ),
        categoryUsage: [
            CategoryUsageItem(category: .social, duration: 111600, percentage: 0.66),
            CategoryUsageItem(category: .entertainment, duration: 28800, percentage: 0.17),
            CategoryUsageItem(category: .productivity, duration: 18000, percentage: 0.11),
            CategoryUsageItem(category: .communication, duration: 14400, percentage: 0.09)
        ]
    )
}

/// Usage data for a single app.
struct AppUsageItem: Codable, Equatable, Identifiable {
    var id: String { identifier }
    let appName: String
    let category: AppCategory
    let duration: TimeInterval
    let identifier: String
}

/// Categories for app usage.
enum AppCategory: String, Codable, CaseIterable {
    case social = "Social"
    case entertainment = "Entertainment"
    case productivity = "Productivity"
    case communication = "Communication"
    case reading = "Reading"
    case health = "Health & Fitness"
    case education = "Education"
    case shopping = "Shopping"
    case utilities = "Utilities"
    case other = "Other"

    var icon: String {
        switch self {
        case .social: return "person.2.fill"
        case .entertainment: return "tv.fill"
        case .productivity: return "briefcase.fill"
        case .communication: return "message.fill"
        case .reading: return "book.fill"
        case .health: return "heart.fill"
        case .education: return "graduationcap.fill"
        case .shopping: return "bag.fill"
        case .utilities: return "wrench.and.screwdriver.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

/// Usage data for a category of apps.
struct CategoryUsageItem: Codable, Equatable, Identifiable {
    var id: String { category.rawValue }
    let category: AppCategory
    let duration: TimeInterval
    let percentage: Double
}
