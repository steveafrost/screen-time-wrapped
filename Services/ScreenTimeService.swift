import Foundation
import FamilyControls
import DeviceActivity
import ManagedSettings

/// Service responsible for requesting Screen Time API authorization and
/// fetching device activity data.
///
/// NOTE: The Screen Time API requires a special entitlement from Apple.
/// This code provides the full integration path, but the entitlement
/// must be configured in the developer portal and Xcode project.
class ScreenTimeService: ObservableObject {
    @Published var isAuthorized = false
    @Published var authorizationStatus: AuthorizationStatus = .notDetermined
    @Published var isLoading = false
    @Published var error: ScreenTimeError?

    private let center = DeviceActivityCenter()
    private let store = ManagedSettingsStore()

    enum AuthorizationStatus {
        case notDetermined
        case authorized
        case denied
        case restricted
    }

    enum ScreenTimeError: LocalizedError {
        case notAuthorized
        case noData
        case fetchFailed(String)

        var errorDescription: String? {
            switch self {
            case .notAuthorized:
                return "Screen Time access not authorized. Please enable in Settings."
            case .noData:
                return "No screen time data available for this period."
            case .fetchFailed(let reason):
                return "Failed to fetch screen time data: \(reason)"
            }
        }
    }

    /// Request authorization from the user for Screen Time data access.
    func requestAuthorization() {
        isLoading = true

        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                await MainActor.run {
                    self.isAuthorized = true
                    self.authorizationStatus = .authorized
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isAuthorized = false
                    self.authorizationStatus = .denied
                    self.isLoading = false
                    self.error = .notAuthorized
                }
            }
        }
    }

    /// Check current authorization status without prompting.
    func checkAuthorizationStatus() {
        Task {
            let status = AuthorizationCenter.shared.authorizationStatus
            await MainActor.run {
                switch status {
                case .approved:
                    self.isAuthorized = true
                    self.authorizationStatus = .authorized
                case .denied:
                    self.isAuthorized = false
                    self.authorizationStatus = .denied
                case .notDetermined:
                    self.isAuthorized = false
                    self.authorizationStatus = .notDetermined
                @unknown default:
                    self.isAuthorized = false
                    self.authorizationStatus = .notDetermined
                }
            }
        }
    }

    /// Fetch the most recent week of screen time data.
    /// Returns preview data when running without entitlement (development).
    func fetchWeeklyData() async -> ScreenTimeData {
        guard isAuthorized else {
            return .preview
        }

        isLoading = true
        defer {
            Task { @MainActor in
                self.isLoading = false
            }
        }

        do {
            // In a real implementation, we would query DeviceActivityReport
            // with the appropriate date interval. This requires the entitlement.
            //
            // let schedule = DeviceActivitySchedule(
            //     intervalStart: DateComponents(hour: 0, minute: 0),
            //     intervalEnd: DateComponents(hour: 23, minute: 59),
            //     repeated: true
            // )
            // let activity = DeviceActivityName("weekly")
            // try center.startMonitoring(activity, during: schedule)
            //
            // Then fetch report data via FamilyControls and ManagedSettings.

            // For now, return preview data that simulates real API results.
            // When the entitlement is configured, replace with actual API calls.
            return try await simulateWeeklyFetch()
        } catch {
            await MainActor.run {
                self.error = .fetchFailed(error.localizedDescription)
            }
            return .preview
        }
    }

    /// Fetch data for a custom date range (Pro feature).
    func fetchData(from startDate: Date, to endDate: Date) async -> ScreenTimeData {
        guard isAuthorized else { return .preview }

        isLoading = true
        defer {
            Task { @MainActor in
                self.isLoading = false
            }
        }

        // Placeholder for historical data fetch.
        // Real implementation would adjust the DeviceActivitySchedule.
        return .preview
    }

    // MARK: - Private

    /// Simulated fetch for development without the entitlement.
    private func simulateWeeklyFetch() async throws -> ScreenTimeData {
        // Artificial delay to mimic network/DB fetch
        try await Task.sleep(nanoseconds: 500_000_000)
        return .preview
    }
}
