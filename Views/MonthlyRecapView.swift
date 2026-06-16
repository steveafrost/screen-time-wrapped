import SwiftUI
import UIKit

/// Monthly recap view — Pro feature with a summary of the past month.
struct MonthlyRecapView: View {
    @EnvironmentObject var screenTimeService: ScreenTimeService
    @EnvironmentObject var proUnlockManager: ProUnlockManager

    @State private var report: MonthlyReport?
    @State private var isLoading = true
    @State private var showingShareSheet = false
    @State private var sharedImage: UIImage?
    @State private var selectedTheme: CardRenderer.CardTheme = .ocean

    private let renderer = CardRenderer()
    private let generator = ReportGenerator()

    var body: some View {
        NavigationStack {
            VStack {
                if !proUnlockManager.isProUnlocked {
                    // Lock screen for non-Pro users
                    proLockView
                } else if isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Crunching your monthly numbers...")
                        .foregroundColor(.secondary)
                        .padding(.top)
                    Spacer()
                } else if let report = report {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Hero Section
                            monthlyHeroCard(report: report)

                            // Weekly breakdown
                            weeklyBreakdownCard(report: report)

                            // Category breakdown
                            categoryCard(report: report)

                            // Top apps
                            topAppsCard(report: report)

                            // Comparison
                            if let comparison = report.comparisons.first {
                                comparisonCard(comparison: comparison)
                            }

                            // Month-over-month change
                            if let change = report.vsPreviousMonth {
                                monthlyChangeCard(change: change)
                            }

                            // Share button
                            Button(action: shareCard) {
                                Label("Share This Recap", systemImage: "square.and.arrow.up")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.purple)
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                    .background(Color(.systemGroupedBackground))
                } else {
                    ContentUnavailableView(
                        "No Monthly Data",
                        systemImage: "calendar",
                        description: Text("Not enough data to generate a monthly report yet.")
                    )
                }
            }
            .navigationTitle("Monthly Recap")
            .refreshable { if proUnlockManager.isProUnlocked { await loadData() } }
            .task { if proUnlockManager.isProUnlocked { await loadData() } }
            .sheet(isPresented: $showingShareSheet) {
                if let image = sharedImage {
                    ShareSheet(items: [image])
                }
            }
        }
    }

    // MARK: - Pro Lock

    private var proLockView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "lock.fill")
                .font(.system(size: 72))
                .foregroundColor(.purple)

            Text("Monthly Recaps are Pro")
                .font(.title.bold())

            Text("Get a full monthly breakdown with week-by-week trends, category insights, and fun comparisons.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)

            NavigationLink(destination: ProUpgradeView()) {
                Text("Upgrade to Pro – $4.99")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color.purple)
                    .cornerRadius(16)
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Data Loading

    private func loadData() async {
        isLoading = true
        let data = await screenTimeService.fetchWeeklyData()
        report = generator.generateMonthlyReport(from: data)
        isLoading = false
    }

    // MARK: - Share

    private func shareCard() {
        guard let report = report else { return }
        sharedImage = renderer.renderMonthlyCard(report: report, theme: selectedTheme)
        if sharedImage != nil {
            showingShareSheet = true
        }
    }

    // MARK: - Card Views

    @ViewBuilder
    private func monthlyHeroCard(report: MonthlyReport) -> some View {
        VStack(spacing: 12) {
            Text("This Month")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))

            Text(report.formattedTotalTime)
                .font(.system(size: 56, weight: .black))
                .foregroundColor(.white)

            Text("\(report.formattedDailyAverage) daily average")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))

            Divider()
                .background(.white.opacity(0.3))

            HStack(spacing: 30) {
                VStack {
                    Text("\(report.totalPickups)")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Text("Pickups")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                VStack {
                    Text("\(report.totalNotifications)")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Text("Notifications")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                VStack {
                    Text(report.formattedDailyAverage)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Text("Daily Avg")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [.purple, .indigo, .blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(24)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func weeklyBreakdownCard(report: MonthlyReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WEEK BY WEEK")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .tracking(1.5)

            let weeks = ["Week 1", "Week 2", "Week 3", "Week 4"]
            ForEach(Array(weeks.enumerated()), id: \.offset) { index, weekLabel in
                HStack {
                    Text(weekLabel)
                        .font(.subheadline)
                    Spacer()
                    if index < report.weeklyBreakdown.count {
                        Text(report.weeklyBreakdown[index].formattedTotalTime)
                            .font(.subheadline.bold())
                    } else {
                        Text("--")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func categoryCard(report: MonthlyReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CATEGORIES")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .tracking(1.5)

            ForEach(report.categoryBreakdown) { category in
                HStack {
                    Image(systemName: category.category.icon)
                        .foregroundColor(.purple)
                    Text(category.category.rawValue)
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(category.percentage * 100))%")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.purple)
                            .frame(width: geo.size.width * category.percentage, height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func topAppsCard(report: MonthlyReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TOP APPS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .tracking(1.5)

            ForEach(Array(report.appBreakdown.prefix(5).enumerated()), id: \.element.id) { index, app in
                HStack {
                    Text("\(index + 1)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    Text(app.appName)
                        .font(.subheadline)
                    Spacer()
                    Text(formatDuration(app.duration))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func comparisonCard(comparison: FunComparison) -> some View {
        HStack {
            Text(comparison.emoji)
                .font(.system(size: 36))
            VStack(alignment: .leading, spacing: 4) {
                Text(comparison.value)
                    .font(.title3.bold())
                Text(comparison.detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func monthlyChangeCard(change: MonthOverMonthChange) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("vs LAST MONTH")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .tracking(1.5)

            changeRow(icon: "clock.fill", label: "Screen Time", change: change.screenTimeChange)
            changeRow(icon: "hand.raised.fill", label: "Pickups", change: change.pickupsChange)
            changeRow(icon: "bell.fill", label: "Notifications", change: change.notificationsChange)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func changeRow(icon: String, label: String, change: Double) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
            Text(label)
                .font(.subheadline)
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                    .font(.caption)
                Text("\(abs(Int(change * 100)))%")
                    .font(.subheadline.bold())
            }
            .foregroundColor(change >= 0 ? .red : .green)
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
}

#Preview {
    MonthlyRecapView()
        .environmentObject(ScreenTimeService())
        .environmentObject(ProUnlockManager())
}
