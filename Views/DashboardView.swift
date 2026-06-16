import SwiftUI

/// Dashboard showing current period's screen time stats at a glance.
struct DashboardView: View {
    @EnvironmentObject var screenTimeService: ScreenTimeService
    @EnvironmentObject var proUnlockManager: ProUnlockManager

    @State private var weeklyReport: WeeklyReport?
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding(.top, 80)
                        Text("Loading your screen time...")
                            .foregroundColor(.secondary)
                    } else if let report = weeklyReport {
                        // Hero Card
                        heroCard(report: report)

                        // Quick Stats Grid
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ],
                            spacing: 16
                        ) {
                            statCard(
                                icon: "clock.fill",
                                title: "Total Time",
                                value: report.formattedTotalTime,
                                color: .purple
                            )
                            statCard(
                                icon: "hand.raised.fill",
                                title: "Pickups",
                                value: "\(report.totalPickups)",
                                color: .blue
                            )
                            statCard(
                                icon: "bell.fill",
                                title: "Notifications",
                                value: "\(report.totalNotifications)",
                                color: .orange
                            )
                            statCard(
                                icon: "chart.bar.fill",
                                title: "Daily Avg",
                                value: report.formattedDailyAverage,
                                color: .green
                            )
                        }
                        .padding(.horizontal)

                        // Most Used App
                        mostUsedAppCard(report: report)

                        // Category Breakdown
                        categoryBreakdownCard(report: report)

                        // Fun Comparison
                        if let comparison = report.comparisons.first {
                            funComparisonCard(comparison: comparison)
                        }

                        // Pro Upgrade Card (if not Pro)
                        if !proUnlockManager.isProUnlocked {
                            proUpgradeCard()
                        }
                    } else {
                        ContentUnavailableView(
                            "No Data Yet",
                            systemImage: "chart.bar.xaxis",
                            description: Text("Enable Screen Time access in Settings to see your stats.")
                        )
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dashboard")
            .refreshable {
                await loadData()
            }
            .task {
                await loadData()
            }
        }
    }

    // MARK: - Data Loading

    private func loadData() async {
        isLoading = true
        let data = await screenTimeService.fetchWeeklyData()
        let generator = ReportGenerator()
        weeklyReport = generator.generateWeeklyReport(from: data)
        isLoading = false
    }

    // MARK: - Card Components

    @ViewBuilder
    private func heroCard(report: WeeklyReport) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("This Week")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    Text(report.formattedTotalTime)
                        .font(.system(size: 48, weight: .black))
                        .foregroundColor(.white)
                }
                Spacer()
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.5))
            }

            Divider()
                .background(.white.opacity(0.3))

            HStack {
                Label("\(report.totalPickups) pickups", systemImage: "hand.raised.fill")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Label("\(report.totalNotifications) notifications", systemImage: "bell.fill")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [.purple, .blue, .teal],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(24)
        .padding(.horizontal)
        .shadow(color: .purple.opacity(0.3), radius: 15, y: 8)
    }

    @ViewBuilder
    private func statCard(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    @ViewBuilder
    private func mostUsedAppCard(report: WeeklyReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MOST USED APP")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .tracking(1.5)

            HStack {
                Image(systemName: "app.fill")
                    .font(.title)
                    .foregroundColor(.purple)

                VStack(alignment: .leading, spacing: 2) {
                    Text(report.mostUsedApp)
                        .font(.title2.bold())
                    Text("\(Int(report.mostUsedAppDuration / 3600))h \(Int(report.mostUsedAppDuration) % 3600 / 60)m total")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Progress bar
                let fraction = report.totalScreenTime > 0 ? report.mostUsedAppDuration / report.totalScreenTime : 0
                CircularProgressView(progress: fraction, color: .purple)
                    .frame(width: 44, height: 44)
            }

            // Top apps list
            ForEach(Array(report.appBreakdown.prefix(5).enumerated()), id: \.element.id) { index, app in
                HStack {
                    Text("\(index + 1)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 20, alignment: .leading)
                    Text(app.appName)
                        .font(.subheadline)
                    Spacer()
                    Text(formatDuration(app.duration))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 2)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func categoryBreakdownCard(report: WeeklyReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CATEGORIES")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .tracking(1.5)

            ForEach(report.categoryBreakdown) { category in
                HStack {
                    Image(systemName: category.category.icon)
                        .foregroundColor(categoryColor(category.category))
                        .frame(width: 24)
                    Text(category.category.rawValue)
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(category.percentage * 100))%")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(categoryColor(category.category))
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
    private func funComparisonCard(comparison: FunComparison) -> some View {
        HStack {
            Text(comparison.emoji)
                .font(.system(size: 40))
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
    private func proUpgradeCard() -> some View {
        NavigationLink(destination: ProUpgradeView()) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Go Pro")
                        .font(.headline.bold())
                        .foregroundColor(.primary)
                    Text("Unlock monthly trends, custom themes & more")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [.purple.opacity(0.15), .blue.opacity(0.15)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }

    private func categoryColor(_ category: AppCategory) -> Color {
        switch category {
        case .social: return .blue
        case .entertainment: return .red
        case .productivity: return .green
        case .communication: return .orange
        case .reading: return .purple
        case .health: return .pink
        case .education: return .indigo
        case .shopping: return .yellow
        case .utilities: return .gray
        case .other: return .secondary
        }
    }
}

// MARK: - Circular Progress View

struct CircularProgressView: View {
    let progress: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 4)
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
            Text("\(Int(progress * 100))%")
                .font(.system(size: 10, weight: .bold))
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(ScreenTimeService())
        .environmentObject(ProUnlockManager())
}
