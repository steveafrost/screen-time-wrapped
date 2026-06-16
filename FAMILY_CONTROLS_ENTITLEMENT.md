# Family Controls Entitlement — Complete Guide

## What This Is

Apple requires **explicit approval** before any app using the Screen Time APIs (FamilyControls, ManagedSettings, DeviceActivity) can be distributed via TestFlight or the App Store. This is a privileged entitlement — you can develop locally, but you can't ship without Apple saying yes.

**Entitlement key:** `com.apple.developer.family-controls`

## Two Versions

| Type | How to get it | Works for |
|---|---|---|
| **Development** | Add "Family Controls" capability in Xcode → Signing & Capabilities | Local builds, simulator, device via Xcode |
| **Distribution** | Submit request form to Apple (see below) | TestFlight, App Store, any distributed build |

You can develop and test the entire app with the development entitlement. The distribution one is only needed when you try to archive for distribution.

## The Request Form

**URL:** https://developer.apple.com/contact/request/family-controls-distribution

You must be signed in as the **Account Holder** of the Apple Developer Program membership ($99/yr).

### What the form asks for:

1. **Bundle ID** — `com.steveafrost.ScreenTimeWrapped`
2. **Target type** — Main app target (and each extension separately)
3. **Use case** — Free-form text describing what your app does and why it needs Family Controls
4. **Data handling** — How you handle user data (privacy)
5. **Screenshots/video** — Optional but strongly recommended to show the flow working

### Important Rule

You need **one submission per bundle ID** that uses Family Controls. For ScreenTime Wrapped:
- **Main app** (`com.steveafrost.ScreenTimeWrapped`) — requests authorization, reads activity data
- **DeviceActivityMonitor extension** (`com.steveafrost.ScreenTimeWrapped.Monitor`) — if you add one

Each needs its own form submission. Apple reviews them as a batch.

## Timeline

- **Fastest reported:** 1 week
- **Typical:** 2–3 weeks
- **Slow:** 4+ weeks (usually because of incomplete info)
- The Japanese developer's experience: 1 week to 1 month

Apple sends the decision to the Account Holder's email on file.

## Draft Response — Ready to Copy/Paste

Use this for the main app target submission:

---

**Bundle ID:** `com.steveafrost.ScreenTimeWrapped`

**What best describes your use of Family Controls?**
Self-management (individual)

**Describe how your app uses Family Controls and what features it provides:**

> ScreenTime Wrapped is a digital wellbeing app that helps users understand their iPhone screen time habits through personalized, shareable recap cards — like Spotify Wrapped for screen time.
>
> The app uses Family Controls to request authorization from the user (for .individual) to read their own Screen Time activity data. With user permission, it reads app-usage durations, pickup counts, and notification counts via the Device Activity framework. This data never leaves the device — all processing happens on-device, and no usage data is uploaded or shared.
>
> Key features:
> - Weekly, monthly, and yearly screen time recap cards with fun comparisons ("47 hours = 94 episodes of The Office")
> - Shareable card images generated entirely on-device
> - Trend tracking over time
> - Pro features unlock historical comparisons and custom card themes
>
> The app does NOT:
> - Block or restrict any apps
> - Apply shields or managed settings
> - Monitor children's devices
> - Upload or transmit Screen Time data
> - Use data for advertising or profiling

**How do you handle user privacy and data?**

> All Screen Time data is processed entirely on-device. We never upload, transmit, or share any usage data. The app uses Apple's privacy-preserving opaque tokens (FamilyActivitySelection) and does not request access to specific app identities. Generated recap cards are only shared when the user explicitly taps "Share" and chooses their destination. No analytics SDKs are used. No account or sign-in is required.

**Optional: Attach a screen recording** showing the authorization flow and a generated card.

---

## Step-by-Step Checklist

- [ ] **Step 1:** Add Family Controls capability in Xcode for local dev
  - Open `ScreenTimeWrapped.xcodeproj`
  - Select target → Signing & Capabilities → + → Family Controls
  - This adds `com.apple.developer.family-controls` (Development) automatically

- [ ] **Step 2:** Test on a real device
  - Build and run on your iPhone
  - The app will request Screen Time authorization
  - Authorize and verify the recap cards generate with real data

- [ ] **Step 3:** Submit the distribution request form
  - Go to https://developer.apple.com/contact/request/family-controls-distribution
  - Sign in as Account Holder
  - Paste the draft response above (customize as needed)
  - Submit

- [ ] **Step 4:** Wait for Apple's response (1–4 weeks)
  - Apple emails the Account Holder when approved
  - The entitlement appears in Certificates, Identifiers & Profiles → Capabilities

- [ ] **Step 5:** Generate new provisioning profile
  - After approval, regenerate your provisioning profile
  - The entitlement now shows as "Assigned" with distribution support

- [ ] **Step 6:** Archive and distribute
  - Product → Archive → Distribute → TestFlight

## Common Pitfalls to Avoid

1. **"Forgetting extensions"** — If you add a DeviceActivity extension later, submit a separate request for its bundle ID. Don't assume the main app entitlement covers it.
2. **"Development only" trap** — The checkbox you add in Xcode is *Development* only. The form gets you *Distribution*. Both are needed.
3. **"Feature creep"** — If Apple asks for more info, respond promptly. Delays on your end reset the clock.
4. **"Marketing use case"** — Apple rejects apps that use Screen Time data for anything other than genuine usage management. Our use case is solid (self-reflection + sharing recaps), but if we ever wanted to add ad targeting, that would be a rejection.
5. **"Screenshots help"** — Inclusion of a screen recording or screenshots showing the authorization flow and a generated card significantly speeds up approval.

## For ScreenTime Wrapped Specifically

We're in the strongest possible position because:
- **Self-management** (`.individual`) — simplest use case, fastest approval path
- **No blocking/shielding** — we only READ data, we don't restrict anything
- **No child data** — we never touch Family Sharing or child devices
- **Privacy-first** — all on-device, no data transmission
- **Clear value** — the "Spotify Wrapped for screen time" pitch is immediately understandable

Approval should be on the faster end of the timeline (1–2 weeks).

## References

- Apple Docs: [Requesting the Family Controls entitlement](https://developer.apple.com/documentation/familycontrols/requesting-the-family-controls-entitlement)
- Request Form: https://developer.apple.com/contact/request/family-controls-distribution
- Apple Docs: [Family Controls framework](https://developer.apple.com/documentation/familycontrols)
- Developer Forum: [FamilyControls entitlement request threads](https://developer.apple.com/forums/thread/821650)
