import SwiftUI

@main
struct ScreenTimeWrappedApp: App {
    @StateObject private var storeKitManager = StoreKitManager()
    @StateObject private var screenTimeService = ScreenTimeService()
    @StateObject private var proUnlockManager = ProUnlockManager()

    init() {
        // Register default settings for free tier
        UserDefaults.standard.register(defaults: [
            "hasSeenOnboarding": false,
            "isProUnlocked": false,
            "lastWeeklyRecapDate": Date.distantPast.timeIntervalSince1970,
            "selectedTheme": "ocean"
        ])
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(storeKitManager)
                .environmentObject(screenTimeService)
                .environmentObject(proUnlockManager)
                .onAppear {
                    storeKitManager.loadProducts()
                    screenTimeService.requestAuthorization()
                }
        }
    }
}
