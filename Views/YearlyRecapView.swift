import SwiftUI
import UIKit

/// Yearly "ScreenTime Wrapped" experience — flagship Pro feature.
/// Full-screen card slideshow with annual stats, comparisons, and insights.
struct YearlyRecapView: View {
    @EnvironmentObject var screenTimeService: ScreenTimeService
    @EnvironmentObject var proUnlockManager: ProUnlockManager

    @State private var report: YearlyReport?
    @State private var isLoading = true
    @State private var showingShareSheet = false
    @State private var sharedImage: UIImage?
    @State private var currentCard = 0
    @State private var isFullScreen = false

    private let renderer = CardRenderer()
    private let generator = ReportGenerator()

    var body: some View {
        NavigationStack {
            VStack {
                if !proUnlockManager.isProUnlocked {
                    proLockView
                } else if isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(2)
                    Text("Generating your Year Wrapped...")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .padding(.top)
                    Spacer()
                } else if let report = report {
                    if isFullScreen {
                        fullScreenSlideshow(report: report)
                    } else {
                        ScrollView {
                            VStack(spacing: 20) {
                                yearHeroCard(report: report)
                                yearStatsGrid(report: report)
                                yearComparisonCard(report: report)
                                topFiveCard(report: report)
                                yearSummaryCard(report: report)

                                Button(action: { isFullScreen = true }) {
                                    Label("View Full Screen", systemImage: "arrow.up.left.and.arrow.down.right")
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
                    }
                } else {
                    ContentUnavailableView(
                        "Not Enough Data",
                        systemImage: "year.calendar",
                        description: Text("A full year of data is needed for your Wrapped.")
                    )
                }
            }
            .navigationTitle("Yearly Wrapped")
            .toolbar {
                if !isFullScreen && report != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Full Screen") {
                            withAnimation { isFullScreen = true }
                        }
                    }
                }
            }
            .refreshable { if proUnlockManager.isProUnlocked { await loadData() } }
            .task { if proUnlockManager.isProUnlocked { await loadData() } }
            .sheet(isPresented: $showingShareSheet) {
                if let image = sharedImage { ShareSheet(items: [image]) }
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
            Text("Yearly Wrapped is Pro")
                .font(.title.bold())
            Text("The full ScreenTime Wrapped experience — annual stats, trends, and a shareable card slideshow.")
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
        report = generator.generateYearlyReport(from: data)
        isLoading = false
    }

    // MARK: - Full Screen Slideshow

    @ViewBuilder
    private func fullScreenSlideshow(report: YearlyReport) -> some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentCard) {
                fullScreenCard(
                    emoji: "📊",
                    title: "Your Year in Screens",
                    value: report.formattedTotalTime,
                    subtitle: "Total Screen Time",
                    color: .purple
                )
                .tag(0)

                fullScreenCard(
                    emoji: "📱",
                    title: "Daily Average",
                    value: report.formattedDailyAverage,
                    subtitle: "Per Day",
                    color: .blue
                )
                .tag(1)

                fullScreenCard(
                    emoji: "👆",
                    title: "Device Pickups",
                    value: "\(report.totalPickups)",
                    subtitle: "\(report.totalPickups / 365)/day on average",
                    color: .orange
                )
                .tag(2)

                fullScreenCard(
                    emoji: "🔔",
                    title: "Notifications",
                    value: "\(report.totalNotifications)",
                    subtitle: "\(report.totalNotifications / 365)/day on average",
                    color: .red
                )
                .tag(3)

                fullScreenCard(
                    emoji: "🏆",
                    title: "Most Used App",
                    value: report.mostUsedApp,
                    subtitle: "\(Int(report.mostUsedAppDuration / 3600)) hours total",
                    color: .purple
                )
                .tag(4)

                if let comparison = report.comparisons.first {
                    fullScreenCard(
                        emoji: comparison.emoji,
                        title: comparison.title,
                        value: comparison.value,
                        subtitle: comparison.detail,
                        color: .green
                    )
                    .tag(5)
                }

                // Year summary
                VStack(spacing: 20) {
                    Spacer()
                    Text("🎉")
                        .font(.system(size: 100))
                    Text("Your ScreenTime Wrapped")
                        .font(.title.bold())
                        .foregroundColor(.white)
                    Text("\(report.totalDaysFormatted) on screen")
                        .font(.system(size: 48, weight: .black))
                        .foregroundColor(.purple)
                    Text("\(report.totalUniqueAppsUsed) apps used")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()

                    Button(action: shareSlideshow) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 16)
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                    }
                    .padding(.bottom, 40)

                    Button("Exit Full Screen") {
                        withAnimation { isFullScreen = false }
                    }
                    .foregroundColor(.white.opacity(0.6))
                }
                .tag(6)
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }

    @ViewBuilder
    private func fullScreenCard(emoji: String, title: String, value: String, subtitle: String, color: Color) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Text(emoji)
                .font(.system(size: 80))
            Text(title)
                .font(.title2)
                .foregroundColor(.white.opacity(0.7))
            Text(value)
                .font(.system(size: 64, weight: .black))
                .foregroundStyle(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.body)
                .foregroundColor(.white.opacity(0.5))
            Spacer()
        }
        .padding()
    }

    // MARK: - Share

    private func shareSlideshow() {
        guard let report = report else { return }
        sharedImage = renderer.renderYearlyCard(report: report, theme: .ocean)
        if sharedImage != nil {
            showingShareSheet = true
        }
    }

    // MARK: - Card Views

    @ViewBuilder
    private func yearHeroCard(report: YearlyReport) -> some View {
        VStack(spacing: 12) {
            Text("Your \(Calendar.current.component(.year, from: Date())) Wrapped")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))

            Text(report.formattedTotalTime)
                .font(.system(size: 56, weight: .black))
                .foregroundColor(.white)

            Text("\(report.totalDaysFormatted) on screen")
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))

            Divider().background(.white.opacity(0.3))

            HStack(spacing: 20) {
                VStack {
                    Text("\(report.totalPickups)")
                        .font(.title2.bold()).foregroundColor(.white)
                    Text("Pickups").font(.caption).foregroundColor(.white.opacity(0.7))
                }
                VStack {
                    Text("\(report.totalNotifications)")
                        .font(.title2.bold()).foregroundColor(.white)
                    Text("Notifications").font(.caption).foregroundColor(.white.opacity(0.7))
                }
                VStack {
                    Text("\(report.totalUniqueAppsUsed)")
                        .font(.title2.bold()).foregroundColor(.white)
                    Text("Apps Used").font(.caption).foregroundColor(.white.opacity(0.7))
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
    private func yearStatsGrid(report: YearlyReport) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            statCard(icon: "clock.fill", title: "Daily Avg", value: report.formattedDailyAverage, color: .purple)
            statCard(icon: "hand.raised.fill", title: "Pickups/Day", value: "\(report.totalPickups / 365)", color: .blue)
            statCard(icon: "bell.fill", title: "Notifs/Day", value: "\(report.totalNotifications / 365)", color: .orange)
            statCard(icon: "app.fill", title: "Top App", value: report.mostUsedApp, color: .green)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func statCard(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title2).foregroundColor(color)
            Text(value).font(.title3.bold())
            Text(title).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    @ViewBuilder
    private func yearComparisonCard(report: YearlyReport) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("YOUR YEAR IN PERSPECTIVE")
                .font(.caption).fontWeight(.semibold).foregroundColor(.secondary).tracking(1.5)

            ForEach(report.comparisons.prefix(3)) { comparison in
                HStack {
                    Text(comparison.emoji).font(.system(size: 32))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(comparison.value).font(.headline)
                        Text(comparison.detail).font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
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
    private func topFiveCard(report: YearlyReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TOP 5 APPS")
                .font(.caption).fontWeight(.semibold).foregroundColor(.secondary).tracking(1.5)

            ForEach(Array(report.topFiveApps.enumerated()), id: \.element.id) { index, app in
                HStack {
                    Text("\(index + 1)").font(.caption).foregroundColor(.secondary).frame(width: 20)
                    VStack(alignment: .leading) {
                        Text(app.appName).font(.subheadline.bold())
                        Text(formatDuration(app.duration)).font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    let fraction = report.totalScreenTime > 0 ? app.duration / report.totalScreenTime : 0
                    Text("\(Int(fraction * 100))%").font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func yearSummaryCard(report: YearlyReport) -> some View {
        VStack(spacing: 12) {
            Text("\(report.totalDaysFormatted) on your phone")
                .font(.title.bold())
            Text("That's \(Int(report.totalScreenTime / 31556952 * 12)) months of your life.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
}

#Preview {
    YearlyRecapView()
        .environmentObject(ScreenTimeService())
        .environmentObject(ProUnlockManager())
}
