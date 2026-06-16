import SwiftUI

/// Pro upgrade screen — feature comparison and purchase button.
struct ProUpgradeView: View {
    @EnvironmentObject var storeKitManager: StoreKitManager
    @EnvironmentObject var proUnlockManager: ProUnlockManager
    @Environment(\.dismiss) var dismiss

    @State private var isPurchasing = false
    @State private var purchaseError: String?
    @State private var showingError = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Hero Section
                heroSection

                // Features Comparison
                featuresSection

                // Price & Purchase
                purchaseSection

                // Legal
                legalSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Upgrade to Pro")
        .alert("Purchase Error", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(purchaseError ?? "An unknown error occurred.")
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange, .red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("ScreenTime Wrapped Pro")
                .font(.title.bold())

            Text("One-time purchase. Forever access.")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Unlock the complete screen time experience with monthly & yearly wrapped reports, custom themes, video export, and more.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("")
                    .frame(width: 100, alignment: .leading)
                Spacer()
                Text("Free")
                    .font(.caption.bold())
                    .frame(width: 60)
                Text("Pro")
                    .font(.caption.bold())
                    .foregroundColor(.purple)
                    .frame(width: 60)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            Divider()

            ForEach(proUnlockManager.proFeatures, id: \.rawValue) { feature in
                VStack(spacing: 0) {
                    HStack {
                        HStack {
                            Image(systemName: feature.icon)
                                .foregroundColor(.purple)
                                .frame(width: 24)
                            Text(feature.rawValue)
                                .font(.subheadline)
                        }
                        .frame(width: 200, alignment: .leading)

                        Spacer()

                        // Free tier check
                        Image(systemName: feature.isFreeTier ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(feature.isFreeTier ? .green : .gray.opacity(0.4))
                            .frame(width: 60)

                        // Pro tier check
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.purple)
                            .frame(width: 60)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal)

                    Divider()
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: - Purchase Section

    private var purchaseSection: some View {
        VStack(spacing: 16) {
            if proUnlockManager.isProUnlocked {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)

                    Text("Pro is Unlocked!")
                        .font(.title2.bold())

                    Text("Thank you for your support.")
                        .foregroundColor(.secondary)

                    Button("Go Back") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            } else {
                // Price
                Text("$4.99")
                    .font(.system(size: 56, weight: .black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("One-time payment, not a subscription")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Purchase Button
                Button(action: purchasePro) {
                    HStack {
                        if isPurchasing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "star.fill")
                            Text("Upgrade to Pro")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
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
                .disabled(isPurchasing)
                .shadow(color: .purple.opacity(0.3), radius: 12, y: 6)

                // Restore Button
                Button("Restore Purchases") {
                    Task {
                        isPurchasing = true
                        let success = await storeKitManager.restorePurchases()
                        isPurchasing = false
                        if success {
                            dismiss()
                        }
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: - Legal

    private var legalSection: some View {
        VStack(spacing: 8) {
            Text("Payment will be charged to your Apple ID account at confirmation of purchase. The purchase is non-consumable and will not expire. Restoration of purchases works across devices signed into the same Apple ID.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Link("Privacy Policy", destination: URL(string: "https://nousresearch.com/privacy")!)
                .font(.caption2)
                .foregroundColor(.purple)

            Link("Terms of Service", destination: URL(string: "https://nousresearch.com/terms")!)
                .font(.caption2)
                .foregroundColor(.purple)
        }
        .padding(.horizontal)
    }

    // MARK: - Purchase Logic

    private func purchasePro() {
        isPurchasing = true
        Task {
            let success = await storeKitManager.purchasePro()
            await MainActor.run {
                isPurchasing = false
                if success {
                    dismiss()
                } else if let error = storeKitManager.purchaseError {
                    purchaseError = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProUpgradeView()
            .environmentObject(StoreKitManager())
            .environmentObject(ProUnlockManager())
    }
}
