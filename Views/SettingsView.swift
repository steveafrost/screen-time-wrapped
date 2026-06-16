import SwiftUI

/// Settings screen with account, notification, theme, and Pro management.
struct SettingsView: View {
    @EnvironmentObject var screenTimeService: ScreenTimeService
    @EnvironmentObject var storeKitManager: StoreKitManager
    @EnvironmentObject var proUnlockManager: ProUnlockManager

    @StateObject private var notificationService = NotificationService()
    @State private var showingRestoreAlert = false
    @State private var restoreMessage = ""
    @State private var showingResetAlert = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Pro Section
                Section {
                    if proUnlockManager.isProUnlocked {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("ScreenTime Wrapped Pro")
                                    .font(.headline)
                                Text("All features unlocked")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                        }
                    } else {
                        NavigationLink(destination: ProUpgradeView()) {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.title2)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Upgrade to Pro")
                                        .font(.headline)
                                    Text("$4.99 – one-time purchase")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }

                        Button("Restore Purchases") {
                            Task {
                                let success = await storeKitManager.restorePurchases()
                                restoreMessage = success ? "Pro restored successfully!" : "No purchases found to restore."
                                showingRestoreAlert = true
                            }
                        }
                    }
                } header: {
                    Label("Pro", systemImage: "crown")
                }

                // MARK: - Screen Time Section
                Section {
                    HStack {
                        Text("Authorization")
                        Spacer()
                        Text(statusString)
                            .foregroundColor(.secondary)
                    }

                    if !screenTimeService.isAuthorized {
                        Button("Request Screen Time Access") {
                            screenTimeService.requestAuthorization()
                        }
                    }

                    Button("Refresh Data") {
                        Task {
                            _ = await screenTimeService.fetchWeeklyData()
                        }
                    }
                } header: {
                    Label("Screen Time", systemImage: "chart.bar.xaxis")
                }

                // MARK: - Notifications Section
                Section {
                    Toggle("Push Notifications", isOn: $notificationService.isNotificationsEnabled)
                        .onChange(of: notificationService.isNotificationsEnabled) { _, newValue in
                            if newValue {
                                Task {
                                    _ = await notificationService.requestAuthorization()
                                    if notificationService.isNotificationsEnabled && proUnlockManager.isProUnlocked {
                                        notificationService.scheduleWeeklyRecapNotification()
                                    }
                                }
                            } else {
                                notificationService.cancelAllNotifications()
                            }
                        }

                    if notificationService.isNotificationsEnabled {
                        if proUnlockManager.isProUnlocked {
                            Text("Weekly recap notifications are active.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.purple)
                                    .font(.caption)
                                Text("Weekly recap notifications require Pro")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Label("Notifications", systemImage: "bell.badge")
                }

                // MARK: - Theme Section
                Section {
                    NavigationLink(destination: themeSelectionView) {
                        HStack {
                            Image(systemName: "paintpalette.fill")
                                .foregroundColor(.purple)
                            Text("Card Theme")
                            Spacer()
                            Text("Ocean")
                                .foregroundColor(.secondary)
                        }
                    }

                    if !proUnlockManager.isProUnlocked {
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.purple)
                                .font(.caption)
                            Text("20+ themes available with Pro")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Label("Appearance", systemImage: "paintbrush")
                }

                // MARK: - About Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    Link(destination: URL(string: "https://github.com/steveafrost/screen-time-wrapped")!) {
                        HStack {
                            Text("GitHub")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Link(destination: URL(string: "https://nousresearch.com/privacy")!) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Label("About", systemImage: "info.circle")
                }

                // MARK: - Danger Zone
                Section {
                    Button("Reset All Data", role: .destructive) {
                        showingResetAlert = true
                    }
                } header: {
                    Label("Data", systemImage: "trash")
                }
            }
            .navigationTitle("Settings")
            .alert("Restore Purchases", isPresented: $showingRestoreAlert) {
                Button("OK") {}
            } message: {
                Text(restoreMessage)
            }
            .alert("Reset Data", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("This will clear all stored preferences, cached reports, and Pro status. You'll need to re-authorize Screen Time access.")
            }
        }
    }

    // MARK: - Theme Selection View

    private var themeSelectionView: some View {
        List {
            ForEach(CardRenderer.CardTheme.freeThemes, id: \.name) { theme in
                HStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: theme.gradientColors.map { Color($0) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    Text(theme.name)
                        .font(.body)
                    Spacer()
                    Image(systemName: "checkmark")
                        .foregroundColor(.purple)
                }
            }

            if proUnlockManager.isProUnlocked {
                ForEach(CardRenderer.CardTheme.proThemes, id: \.name) { theme in
                    HStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: theme.gradientColors.map { Color($0) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                        Text(theme.name)
                            .font(.body)
                        Spacer()
                    }
                }
            } else {
                ForEach(CardRenderer.CardTheme.proThemes, id: \.name) { theme in
                    HStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: theme.gradientColors.map { Color($0) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                            .opacity(0.4)
                        Text(theme.name)
                            .font(.body)
                            .foregroundColor(.secondary)
                        Spacer()
                        Image(systemName: "lock.fill")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
        }
        .navigationTitle("Themes")
    }

    // MARK: - Helpers

    private var statusString: String {
        switch screenTimeService.authorizationStatus {
        case .authorized: return "Authorized"
        case .denied: return "Denied"
        case .notDetermined: return "Not Requested"
        case .restricted: return "Restricted"
        }
    }

    private func resetAllData() {
        UserDefaults.standard.removeObject(forKey: "hasSeenOnboarding")
        UserDefaults.standard.removeObject(forKey: "isProUnlocked")
        UserDefaults.standard.removeObject(forKey: "lastWeeklyRecapDate")
        UserDefaults.standard.removeObject(forKey: "selectedTheme")
        proUnlockManager.resetPro()
        notificationService.cancelAllNotifications()
    }
}

#Preview {
    SettingsView()
        .environmentObject(ScreenTimeService())
        .environmentObject(StoreKitManager())
        .environmentObject(ProUnlockManager())
}
