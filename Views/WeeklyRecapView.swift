import SwiftUI

/// Weekly recap view with a card slideshow of screen time stats.
struct WeeklyRecapView: View {
    @EnvironmentObject var screenTimeService: ScreenTimeService
    @EnvironmentObject var proUnlockManager: ProUnlockManager

    @State private var report: WeeklyReport?
    @State private var isLoading = true
    @State private var currentCardIndex = 0
    @State private var showingShareSheet = false
    @State private var sharedImage: UIImage?
    @State private var selectedTheme: CardRenderer.CardTheme = .ocean

    private let renderer = CardRenderer()
    private let generator = ReportGenerator()

    private let themes: [CardRenderer.CardTheme] = [.ocean, .midnight, .sunset, .forest, .lava]

    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Generating your weekly recap...")
                        .foregroundColor(.secondary)
                        .padding(.top)
                    Spacer()
                } else if let report = report {
                    // Card slideshow
                    TabView(selection: $currentCardIndex) {
                        // Card 1: Total Time
                        totalTimeCard(report: report)
                            .tag(0)

                        // Card 2: Most Used App
                        mostUsedAppCard(report: report)
                            .tag(1)

                        // Card 3: Pickups & Notifications
                        pickupsCard(report: report)
                            .tag(2)

                        // Card 4: Fun Comparison
                        if let comparison = report.comparisons.first {
                            comparisonCard(comparison: comparison)
                                .tag(3)
                        }

                        // Card 5: Week over Week
                        if let change = report.vsPreviousWeek {
                            weeklyChangeCard(change: change)
                                .tag(4)
                        }

                        // Card 6: App Breakdown (Pro)
                        if proUnlockManager.isProUnlocked {
                            appBreakdownCard(report: report)
                                .tag(5)
                        }
                    }
                    .tabViewStyle(.page)
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                    .frame(height: 440)

                    // Controls
                    HStack(spacing: 20) {
                        // Share button
                        Button(action: shareCurrentCard) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.purple)
                                .cornerRadius(12)
                        }

                        // Theme picker
                        if proUnlockManager.isProUnlocked {
                            themePicker
                        } else {
                            themePicker
                        }
                    }
                    .padding(.top, 8)

                    // Pro upgrade prompt
                    if !proUnlockManager.isProUnlocked {
                        NavigationLink(destination: ProUpgradeView()) {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text("Go Pro for more themes & insights")
                                    .font(.subheadline)
                            }
                            .padding(12)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .padding(.top, 8)
                    }

                    Spacer()
                } else {
                    ContentUnavailableView(
                        "No Weekly Data",
                        systemImage: "calendar.badge.clock",
                        description: Text("Enable Screen Time access to see your weekly recap.")
                    )
                }
            }
            .navigationTitle("Weekly Recap")
            .background(Color(.systemGroupedBackground))
            .refreshable { await loadData() }
            .task { await loadData() }
            .sheet(isPresented: $showingShareSheet) {
                if let image = sharedImage {
                    ShareSheet(items: [image])
                }
            }
        }
    }

    // MARK: - Data Loading

    private func loadData() async {
        isLoading = true
        let data = await screenTimeService.fetchWeeklyData()
        report = generator.generateWeeklyReport(from: data)
        isLoading = false
    }

    // MARK: - Share

    private func shareCurrentCard() {
        guard let report = report else { return }
        let theme = themes[safe: currentCardIndex] ?? selectedTheme
        sharedImage = renderer.renderWeeklyCard(report: report, theme: theme)
        if sharedImage != nil {
            showingShareSheet = true
        }
    }

    // MARK: - Theme Picker

    private var themePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(themes, id: \.name) { theme in
                    let isFree = !theme.isPro || proUnlockManager.isProUnlocked
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: theme.gradientColors.map { Color($0) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .stroke(Color.primary.opacity(selectedTheme.name == theme.name ? 0.8 : 0.2), lineWidth: 2)
                        )
                        .overlay(
                            !isFree ?
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.white)
                            : nil
                        )
                        .onTapGesture {
                            if isFree {
                                selectedTheme = theme
                            }
                        }
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(width: 180)
    }

    // MARK: - Card Views

    @ViewBuilder
    private func totalTimeCard(report: WeeklyReport) -> some View {
        VStack(spacing: 16) {
            Text("Your Weekly Total")
                .font(.headline)
                .foregroundColor(.secondary)

            Text(report.formattedTotalTime)
                .font(.system(size: 64, weight: .black))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("screen time this week")
                .font(.body)
                .foregroundColor(.secondary)

            Divider()
                .padding(.horizontal, 40)

            HStack(spacing: 40) {
                VStack {
                    Text(report.formattedDailyAverage)
                        .font(.title2.bold())
                    Text("Daily Avg")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                VStack {
                    Text("\(report.averagePickupsPerDay)")
                        .font(.title2.bold())
                    Text("Pickups/Day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(24)
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func mostUsedAppCard(report: WeeklyReport) -> some View {
        VStack(spacing: 16) {
            Text("Most Used App")
                .font(.headline)
                .foregroundColor(.secondary)

            Image(systemName: "app.fill")
                .font(.system(size: 48))
                .foregroundColor(.purple)

            Text(report.mostUsedApp)
                .font(.system(size: 42, weight: .black))

            Text("\(Int(report.mostUsedAppDuration / 3600))h \(Int(report.mostUsedAppDuration) % 3600 / 60)m total")
                .font(.title3)
                .foregroundColor(.secondary)

            // Usage bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(height: 16)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * min(CGFloat(report.mostUsedAppDuration / max(report.totalScreenTime, 1)), 1.0), height: 16)
                }
            }
            .frame(height: 16)
            .padding(.horizontal, 20)

            Text("\(Int(report.mostUsedAppDuration / report.totalScreenTime * 100))% of your total screen time")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(24)
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func pickupsCard(report: WeeklyReport) -> some View {
        VStack(spacing: 20) {
            Text("Pickups & Notifications")
                .font(.headline)
                .foregroundColor(.secondary)

            HStack(spacing: 40) {
                VStack(spacing: 8) {
                    Image(systemName: "hand.raised.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                    Text("\(report.totalPickups)")
                        .font(.system(size: 48, weight: .black))
                    Text("pickups")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(report.averagePickupsPerDay)/day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()
                    .frame(height: 100)

                VStack(spacing: 8) {
                    Image(systemName: "bell.fill")
                        .font(.title)
                        .foregroundColor(.orange)
                    Text("\(report.totalNotifications)")
                        .font(.system(size: 48, weight: .black))
                    Text("notifications")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(report.averageNotificationsPerDay)/day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(24)
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func comparisonCard(comparison: FunComparison) -> some View {
        VStack(spacing: 16) {
            Text("Fun Fact")
                .font(.headline)
                .foregroundColor(.secondary)

            Text(comparison.emoji)
                .font(.system(size: 72))

            Text(comparison.value)
                .font(.system(size: 36, weight: .black))
                .multilineTextAlignment(.center)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text(comparison.detail)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(24)
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func weeklyChangeCard(change: WeekOverWeekChange) -> some View {
        VStack(spacing: 16) {
            Text("vs Last Week")
                .font(.headline)
                .foregroundColor(.secondary)

            VStack(spacing: 12) {
                changeRow(
                    icon: "clock.fill",
                    label: "Screen Time",
                    change: change.screenTimeChange
                )
                changeRow(
                    icon: "hand.raised.fill",
                    label: "Pickups",
                    change: change.pickupsChange
                )
                changeRow(
                    icon: "bell.fill",
                    label: "Notifications",
                    change: change.notificationsChange
                )
            }
            .padding(.horizontal)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(24)
        .padding(.horizontal, 16)
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

    @ViewBuilder
    private func appBreakdownCard(report: WeeklyReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("App Breakdown")
                .font(.headline)
                .foregroundColor(.secondary)

            ForEach(Array(report.appBreakdown.prefix(6).enumerated()), id: \.element.id) { index, app in
                HStack {
                    Text("\(index + 1)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    VStack(alignment: .leading) {
                        Text(app.appName)
                            .font(.subheadline.bold())
                        Text(formatDuration(app.duration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    let fraction = report.totalScreenTime > 0 ? app.duration / report.totalScreenTime : 0
                    Text("\(Int(fraction * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(24)
        .padding(.horizontal, 16)
    }

    // MARK: - Helpers

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
}

// MARK: - Safe Array Extension

extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0 && index < count else { return nil }
        return self[index]
    }
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    WeeklyRecapView()
        .environmentObject(ScreenTimeService())
        .environmentObject(ProUnlockManager())
}
