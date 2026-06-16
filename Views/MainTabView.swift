import SwiftUI

/// Main tab navigation with Dashboard, Recaps, and Settings tabs.
struct MainTabView: View {
    @EnvironmentObject var screenTimeService: ScreenTimeService
    @EnvironmentObject var proUnlockManager: ProUnlockManager
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
                .tag(0)

            WeeklyRecapView()
                .tabItem {
                    Label("Weekly", systemImage: "calendar.badge.clock")
                }
                .tag(1)

            MonthlyRecapView()
                .tabItem {
                    Label("Monthly", systemImage: "calendar")
                }
                .tag(2)

            YearlyRecapView()
                .tabItem {
                    Label("Year", systemImage: "year.calendar")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(.purple)
    }
}

#Preview {
    MainTabView()
        .environmentObject(ScreenTimeService())
        .environmentObject(StoreKitManager())
        .environmentObject(ProUnlockManager())
}
