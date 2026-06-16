import Foundation
import StoreKit

/// Manages the one-time Pro unlock purchase for ScreenTime Wrapped.
///
/// Uses UserDefaults to persist unlock status (does not rely on keychain
/// for simplicity; in production, validate receipts server-side).
class ProUnlockManager: ObservableObject {
    @Published var isProUnlocked: Bool {
        didSet {
            UserDefaults.standard.set(isProUnlocked, forKey: "isProUnlocked")
        }
    }

    /// Features gated behind the Pro tier.
    let proFeatures: [ProFeature] = ProFeature.allCases

    init() {
        self.isProUnlocked = UserDefaults.standard.bool(forKey: "isProUnlocked")
    }

    /// Whether the user can access a given feature.
    func canAccess(_ feature: ProFeature) -> Bool {
        if feature.isFreeTier { return true }
        return isProUnlocked
    }

    /// Unlock Pro (called after successful purchase or restore).
    func unlockPro() {
        isProUnlocked = true
    }

    /// Reset unlock (for testing).
    func resetPro() {
        isProUnlocked = false
    }
}

/// Features available in the app, partitioned by free vs Pro.
enum ProFeature: String, CaseIterable, Codable {
    // Free tier features
    case weeklyRecap = "Weekly Recap"
    case basicStats = "Basic Stats"
    case twoThemes = "2 Card Themes"
    case basicComparisons = "Basic Comparisons"

    // Pro tier features
    case monthlyRecap = "Monthly Recap"
    case yearlyRecap = "Yearly Wrapped"
    case historicalTrends = "Historical Trends"
    case customThemes = "20+ Custom Themes"
    case videoExport = "Video Export"
    case appBreakdowns = "App-Level Breakdowns"
    case weeklyPushRecaps = "Weekly Push Recaps"
    case allComparisons = "All Comparison Styles"
    case noAds = "No Ads"

    /// Whether this feature is available in the free tier.
    var isFreeTier: Bool {
        switch self {
        case .weeklyRecap, .basicStats, .twoThemes, .basicComparisons:
            return true
        case .monthlyRecap, .yearlyRecap, .historicalTrends, .customThemes,
                .videoExport, .appBreakdowns, .weeklyPushRecaps, .allComparisons, .noAds:
            return false
        }
    }

    var icon: String {
        switch self {
        case .weeklyRecap: return "calendar.badge.clock"
        case .basicStats: return "chart.bar.fill"
        case .twoThemes: return "paintpalette.fill"
        case .basicComparisons: return "arrow.left.arrow.right"
        case .monthlyRecap: return "calendar"
        case .yearlyRecap: return "year.calendar"
        case .historicalTrends: return "chart.line.uptrend.xyaxis"
        case .customThemes: return "paintbrush.fill"
        case .videoExport: return "video.fill"
        case .appBreakdowns: return "square.grid.3x1.fill"
        case .weeklyPushRecaps: return "bell.badge.fill"
        case .allComparisons: return "rectangle.3.group.fill"
        case .noAds: return "nosign"
        }
    }

    var description: String {
        switch self {
        case .weeklyRecap: return "Your weekly screen time recap"
        case .basicStats: return "Total time, pickups, notifications"
        case .twoThemes: return "Ocean and Midnight themes"
        case .basicComparisons: return "Compare your usage to fun facts"
        case .monthlyRecap: return "Full monthly breakdowns"
        case .yearlyRecap: return "Year-in-review wrapped experience"
        case .historicalTrends: return "See how your usage changes over time"
        case .customThemes: return "Unlock 20+ beautiful card themes"
        case .videoExport: return "Export your recap as a video slideshow"
        case .appBreakdowns: return "See exactly which apps you use most"
        case .weeklyPushRecaps: return "Get notified when your weekly recap is ready"
        case .allComparisons: return "All fun comparison styles unlocked"
        case .noAds: return "Remove all advertisements"
        }
    }
}
