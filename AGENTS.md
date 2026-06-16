# ScreenTime Wrapped — AGENTS.md

## Architecture Overview

ScreenTime Wrapped is an iOS 17+ SwiftUI app that provides Spotify-Wrapped-style screen time recap cards for iPhone. The app uses the DeviceActivity and FamilyControls frameworks to read on-device screen time data, generates fun comparisons, renders shareable card images, and offers a one-time $4.99 Pro unlock via StoreKit 2.

## What's Built

### Project Structure (SPM-based)

```
ScreenTimeWrapped/
├── App/
│   ├── ScreenTimeWrappedApp.swift   — @main entry, environment setup
│   └── ContentView.swift            — Auth gate + onboarding
├── Models/
│   ├── ScreenTimeData.swift         — Raw data models (AppUsageItem, CategoryUsageItem)
│   ├── WeeklyReport.swift           — Weekly report + FunComparison + WeekOverWeekChange
│   ├── MonthlyReport.swift          — Monthly report (Pro) + MonthOverMonthChange
│   ├── YearlyReport.swift           — Yearly "Wrapped" report (Pro)
│   └── ProUnlockManager.swift       — Feature gating + unlock state
├── Services/
│   ├── ScreenTimeService.swift      — DeviceActivity auth + data fetching
│   ├── ReportGenerator.swift        — Computes reports from raw data + comparison engine
│   ├── CardRenderer.swift           — Core Graphics card image generation (1080×1920)
│   ├── StoreKitManager.swift        — StoreKit 2 purchase handling
│   └── NotificationService.swift    — UNNotification management for weekly recaps
├── Views/
│   ├── MainTabView.swift            — 5-tab navigation
│   ├── DashboardView.swift          — Current period stats with cards
│   ├── WeeklyRecapView.swift        — Card slideshow with share + theme picker
│   ├── MonthlyRecapView.swift       — Monthly breakdown (Pro-locked)
│   ├── YearlyRecapView.swift        — Full-screen wrapped experience (Pro-locked)
│   ├── ShareCardView.swift          — Card customization + preview
│   ├── SettingsView.swift           — Preferences, notifications, account
│   └── ProUpgradeView.swift         — Feature comparison + purchase
├── Resources/
│   ├── Assets.xcassets/             — Placeholder asset catalog
│   └── Preview Assets.xcassets/     — Placeholder preview assets
├── Package.swift                    — SwiftPM package definition (iOS 17+)
├── AGENTS.md                        — This file
└── .gitignore
```

### Key Features Implemented (Code-Complete)

1. **ScreenTimeService** — Full authorization flow via `AuthorizationCenter.shared.requestAuthorization()`. Fetches data using DeviceActivity API structure. Falls back to realistic preview data for development (since entitlement is required for real data).

2. **ReportGenerator** — Computes weekly/monthly/yearly reports from raw ScreenTimeData. Includes a full comparison engine with 14 fun fact thresholds (e.g., "47h = 94 episodes of The Office"). Generates per-app breakdowns, category usage, and week-over-week change deltas.

3. **CardRenderer** — Core Graphics-based image generator producing 1080×1920 pixel cards. Draws gradient backgrounds, large stat text, pickups/notifications rows, top app info, fun comparisons, and "SCREENTIME WRAPPED" footer. Supports 5 themes (Ocean, Midnight, Sunset, Forest, Lava) with distinct gradient palettes.

4. **Comparison Engine** — Built into ReportGenerator with 14 fun fact thresholds. Dynamically generates comparisons for total time, pickups, notifications, and top app usage.

5. **Weekly/Monthly/Yearly Recap Views** — Full card slideshow (TabView with page indices), scrollable stats breakdowns, full-screen immersive mode for yearly wrapped.

6. **ShareSheet Integration** — `UIActivityViewController` wrapped for SwiftUI. Cards render to UIImage and share as PNG.

7. **StoreKitManager** — Full StoreKit 2 purchase flow: `Product.products(for:)`, `product.purchase()`, `Transaction.currentEntitlements`, `Transaction.updates` observation, `AppStore.sync()` for restore. Uses `proProductID = "com.nousresearch.screentimewrapped.pro"`.

8. **ProUpgradeView** — Feature comparison table showing Free vs Pro for all 13 features. Purchase button, restore button, legal/disclaimer text.

9. **NotificationService** — Weekly recap push notification scheduling via `UNCalendarNotificationTrigger` (Sundays at 10:00 AM). Permission request flow, cancel/reschedule support.

### Monetization

- **Free tier:** Weekly recap, basic stats, 2 themes (Ocean, Midnight), basic comparisons
- **Pro ($4.99 one-time):** Monthly recap, yearly wrapped, historical trends, 20+ themes (3 more implemented), video export (placeholder), app-level breakdowns, weekly push recaps, all comparison styles, no ads

## What's Placeholder / Needs Real Device

### Screen Time API Entitlement
The Screen Time API requires a **special entitlement** from Apple (`com.apple.developer.familycontrols`). Without it:
- `DeviceActivityCenter`, `FamilyControls`, and `ManagedSettingsStore` calls will fail at runtime
- The app falls back to `ScreenTimeData.preview` — realistic sample data
- **To ship:** Apply for the entitlement at developer.apple.com, add it to your App ID, and configure in Xcode

### StoreKit Configuration
For testing purchases without App Store Connect:
1. Create a `.storekit` configuration file in Xcode
2. Add a non-consumable IAP with product ID `com.nousresearch.screentimewrapped.pro`
3. Set price to $4.99
4. Run with "StoreKit Configuration" in the scheme

### Card Image Generation
`CardRenderer` uses `UIGraphicsImageRenderer` which works on-device and in simulator. The card designs are production-ready with gradient backgrounds, proper typography, and spacing.

### Push Notifications
`NotificationService` is fully implemented but requires:
1. Push notification capability enabled in Xcode
2. APNs certificate or key configured
3. Real device testing (simulator can't receive remote pushes)

## Next Steps to Ship

### 1. Xcode Project Setup
```bash
# Generate .xcodeproj from the SPM package
swift package generate-xcodeproj
# Or create a new Xcode project and point sources to this directory
```

### 2. Configure Entitlements
- Add Screen Time entitlement (`com.apple.developer.familycontrols`)
- Enable Push Notifications capability
- Set up App Groups if needed for WidgetKit

### 3. StoreKit Configuration
- Create IAP in App Store Connect (product ID: `com.nousresearch.screentimewrapped.pro`)
- Add local StoreKit configuration file for testing
- Test purchase + restore flows

### 4. Real Data Integration
Once entitlement is approved:
- Replace `simulateWeeklyFetch()` in `ScreenTimeService` with real `DeviceActivityReport` queries
- Integrate `DeviceActivitySchedule` for background monitoring
- Add `DeviceActivityMonitor` extension for push triggers

### 5. Polish
- Add proper app icon (replace Assets.xcassets placeholder)
- Configure deep links for notification tap handling
- Add WidgetKit extension for home screen stats
- Add video export capability (AVFoundation-based slideshow)

### 6. Testing
- Test on physical device (Screen Time API doesn't work in simulator)
- Verify all Pro gating logic
- Test purchase restore across devices
- Validate card rendering at all safe area sizes

## Dependencies
- iOS 17+ (required for DeviceActivity and SwiftUI features)
- Swift 5.9+
- No third-party dependencies (pure SwiftUI + system frameworks)

## Build & Run
```bash
cd ScreenTimeWrapped
swift package resolve
swift build
# Or open in Xcode and run on device
```

## Contributing
PRs welcome. See the full plan at `/tmp/app-plans/screen-time-wrapped-plan.md`
