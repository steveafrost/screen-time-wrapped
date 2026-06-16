import SwiftUI
import UIKit

/// Card customization view — allows theme selection and preview before sharing.
struct ShareCardView: View {
    @EnvironmentObject var proUnlockManager: ProUnlockManager

    let report: WeeklyReport
    let onShare: (UIImage) -> Void

    @State private var selectedTheme: CardRenderer.CardTheme = .ocean
    @State private var previewImage: UIImage?

    private let renderer = CardRenderer()

    private let availableThemes: [CardRenderer.CardTheme] = {
        let freeThemes = CardRenderer.CardTheme.freeThemes
        let proThemes = CardRenderer.CardTheme.proThemes
        return freeThemes + proThemes
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Preview
                if let previewImage = previewImage {
                    Image(uiImage: previewImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 400)
                        .cornerRadius(16)
                        .shadow(radius: 10)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray5))
                        .frame(height: 400)
                        .overlay {
                            ProgressView()
                        }
                }

                // Theme Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("CARD THEME")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .tracking(1.5)

                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 60), spacing: 16)
                    ], spacing: 16) {
                        ForEach(availableThemes, id: \.name) { theme in
                            let isLocked = theme.isPro && !proUnlockManager.isProUnlocked

                            VStack(spacing: 4) {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: theme.gradientColors.map { Color($0) },
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 48, height: 48)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary.opacity(selectedTheme.name == theme.name ? 0.6 : 0.1), lineWidth: 3)
                                    )
                                    .overlay(
                                        isLocked ?
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                        : nil
                                    )
                                    .opacity(isLocked ? 0.6 : 1.0)

                                Text(theme.name)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .onTapGesture {
                                if !isLocked {
                                    selectedTheme = theme
                                    updatePreview()
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)

                // Share Button
                Button(action: shareCard) {
                    Label("Share Card", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }

                // Pro Upgrade Prompt
                if !proUnlockManager.isProUnlocked {
                    NavigationLink(destination: ProUpgradeView()) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("Unlock \(CardRenderer.CardTheme.proThemes.count) more themes with Pro")
                                .font(.subheadline)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Customize Card")
        .onAppear { updatePreview() }
    }

    private func updatePreview() {
        previewImage = renderer.renderWeeklyCard(report: report, theme: selectedTheme)
    }

    private func shareCard() {
        guard let image = previewImage else { return }
        onShare(image)
    }
}

#Preview {
    NavigationStack {
        ShareCardView(
            report: WeeklyReport.preview,
            onShare: { _ in }
        )
        .environmentObject(ProUnlockManager())
    }
}
