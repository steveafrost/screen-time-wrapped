# App Store Connect Setup — ScreenTime Wrapped

## App Record
- **Name:** ScreenTime Wrapped
- **Bundle ID:** com.steveafrost.ScreenTimeWrapped
- **SKU:** screentime-wrapped-2026
- **Apple ID:** (leave blank until created)
- **Price:** Free with $4.99 one-time purchase
- **Category:** Productivity
- **Age Rating:** 4+
- **Privacy URL:** https://straightcodes.com/privacy (or your privacy page)
- **Support URL:** (your support URL)

## App Icon
- Placeholder icon included in Assets.xcassets/AppIcon.appiconset/
- Replace with a real 1024×1024 PNG before submission

## Screenshots
3 screenshots included at Resources/Screenshots/ for 6.7" iPhone (1290×2796 px)

## In-App Purchases
- **Reference Name:** ScreenTime Wrapped Pro
- **Product ID:** com.steveafrost.ScreenTimeWrapped.pro
- **Type:** Non-Consumable
- **Price:** $4.99

## App Privacy
- No data collected (all on-device processing)
- Screen Time data never leaves the device
- Privacy manifest required: indicate NO data collected

## Family Controls Entitlement
**CRITICAL:** Before archiving for TestFlight, you must submit the Family Controls entitlement request at:
https://developer.apple.com/contact/request/family-controls-distribution

See FAMILY_CONTROLS_ENTITLEMENT.md for the draft response.

## Distribution Checklist
- [ ] Submit Family Controls entitlement request (1-3 week delay)
- [ ] Create app record in App Store Connect
- [ ] Set pricing and availability
- [ ] Upload screenshots
- [ ] Fill in privacy details
- [ ] Add App Icon (1024×1024)
- [ ] Create IAP in App Store Connect
- [ ] Test on physical device
- [ ] Archive and upload via Xcode
