import SwiftUI

struct ContentView: View {
    @EnvironmentObject var screenTimeService: ScreenTimeService
    @EnvironmentObject var storeKitManager: StoreKitManager
    @EnvironmentObject var proUnlockManager: ProUnlockManager
    @State private var showOnboarding = false

    var body: some View {
        Group {
            if screenTimeService.isAuthorized {
                MainTabView()
            } else {
                AuthorizationRequestView()
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView()
        }
        .onAppear {
            if !UserDefaults.standard.bool(forKey: "hasSeenOnboarding") {
                showOnboarding = true
                UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
            }
        }
    }
}

// MARK: - Authorization Request View

struct AuthorizationRequestView: View {
    @EnvironmentObject var screenTimeService: ScreenTimeService

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 72))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .blue, .teal],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("ScreenTime Wrapped")
                .font(.largeTitle.bold())

            Text("See your screen time like never before.\nWeekly recaps, fun comparisons, and insights.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)

            Button(action: {
                screenTimeService.requestAuthorization()
            }) {
                HStack {
                    Image(systemName: "hand.raised.fill")
                    Text("Enable Screen Time Access")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }
            .shadow(color: .blue.opacity(0.3), radius: 12, y: 6)

            Text("Your data stays on-device. We never see it.")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
    }
}

// MARK: - Onboarding View

struct OnboardingView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        TabView {
            OnboardingPage(
                image: "clock.arrow.circlepath",
                title: "Track Your Time",
                description: "See exactly where your screen time goes — every day, every app."
            )
            OnboardingPage(
                image: "rectangle.stack.fill",
                title: "Weekly Wrapped",
                description: "Get a Spotify-style recap every week with fun comparisons."
            )
            OnboardingPage(
                image: "star.circle.fill",
                title: "Go Pro",
                description: "Unlock monthly & yearly trends, custom themes, and more for a one-time purchase."
            )
        }
        .tabViewStyle(.page)
        .interactiveDismissDisabled()
        .overlay(alignment: .bottom) {
            Button("Get Started") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom, 40)
        }
    }
}

struct OnboardingPage: View {
    let image: String
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: image)
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text(title)
                .font(.title.bold())
            Text(description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            Spacer()
        }
        .padding()
    }
}

#Preview {
    ContentView()
        .environmentObject(ScreenTimeService())
        .environmentObject(StoreKitManager())
        .environmentObject(ProUnlockManager())
}
