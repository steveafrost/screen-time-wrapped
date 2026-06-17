import Foundation
import StoreKit

/// Manages the one-time $4.99 Pro purchase using StoreKit 2.
///
/// This service handles product loading, purchasing, receipt validation,
/// and subscription to transaction updates.
class StoreKitManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoadingProducts = false
    @Published var isPurchasing = false
    @Published var purchaseError: PurchaseError?

    private let proProductID = "com.nousresearch.screentimewrapped.pro"
    private weak var proUnlockManager: ProUnlockManager?

    /// Link the ProUnlockManager so purchase/restore updates the UI correctly.
    func configure(proUnlockManager: ProUnlockManager) {
        self.proUnlockManager = proUnlockManager
    }

    enum PurchaseError: LocalizedError {
        case productNotFound
        case purchaseFailed(String)
        case userCancelled
        case notAvailable
        case verificationFailed

        var errorDescription: String? {
            switch self {
            case .productNotFound:
                return "Pro upgrade not found in App Store."
            case .purchaseFailed(let reason):
                return "Purchase failed: \(reason)"
            case .userCancelled:
                return "Purchase was cancelled."
            case .notAvailable:
                return "In-app purchases are not available on this device."
            case .verificationFailed:
                return "Transaction verification failed. Please contact support."
            }
        }
    }

    /// Load product information from App Store Connect.
    func loadProducts() {
        guard !isLoadingProducts else { return }
        isLoadingProducts = true

        Task {
            do {
                let products = try await Product.products(for: [proProductID])
                await MainActor.run {
                    self.products = products
                    self.isLoadingProducts = false
                }
            } catch {
                await MainActor.run {
                    self.isLoadingProducts = false
                    // Products remain empty when StoreKit isn't configured;
                    // purchase flow will show productNotFound error gracefully.
                }
            }
        }
    }

    /// Purchase the Pro unlock.
    func purchasePro() async -> Bool {
        guard let product = products.first(where: { $0.id == proProductID }) ?? products.first else {
            await MainActor.run {
                self.purchaseError = .productNotFound
            }
            return false
        }

        await MainActor.run { self.isPurchasing = true }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await MainActor.run {
                    self.isPurchasing = false
                    self.proUnlockManager?.unlockPro()
                }
                await transaction.finish()
                return true

            case .userCancelled:
                await MainActor.run {
                    self.isPurchasing = false
                    self.purchaseError = .userCancelled
                }
                return false

            case .pending:
                await MainActor.run {
                    self.isPurchasing = false
                }
                return false

            @unknown default:
                await MainActor.run {
                    self.isPurchasing = false
                    self.purchaseError = .purchaseFailed("Unknown error")
                }
                return false
            }
        } catch {
            await MainActor.run {
                self.isPurchasing = false
                self.purchaseError = .purchaseFailed(error.localizedDescription)
            }
            return false
        }
    }

    /// Restore previous purchases.
    func restorePurchases() async -> Bool {
        await MainActor.run { self.isPurchasing = true }

        do {
            try await AppStore.sync()
            // After sync, check if we have a valid transaction for our product
            var hasValidTransaction = false
            for await result in Transaction.currentEntitlements {
                let transaction = try checkVerified(result)
                if transaction.productID == proProductID {
                    hasValidTransaction = true
                    break
                }
            }

            await MainActor.run {
                self.isPurchasing = false
                if hasValidTransaction {
                    self.proUnlockManager?.unlockPro()
                }
            }
            return hasValidTransaction
        } catch {
            await MainActor.run {
                self.isPurchasing = false
                self.purchaseError = .purchaseFailed(error.localizedDescription)
            }
            return false
        }
    }

    /// Listen for transaction updates (e.g., family sharing, refunds).
    func observeTransactionUpdates() {
        Task(priority: .background) {
            for await result in Transaction.updates {
                do {
                    let transaction = try checkVerified(result)
                    if transaction.productID == proProductID {
                        await MainActor.run {
                            if transaction.revocationDate == nil {
                                self.proUnlockManager?.unlockPro()
                            } else {
                                self.proUnlockManager?.resetPro()
                            }
                        }
                    }
                    await transaction.finish()
                } catch {
                    // Log verification failure
                }
            }
        }
    }

    /// Check if the user already has a valid Pro transaction.
    func checkForExistingPurchase() async -> Bool {
        do {
            for await result in Transaction.currentEntitlements {
                let transaction = try checkVerified(result)
                if transaction.productID == proProductID {
                    await MainActor.run {
                        self.proUnlockManager?.unlockPro()
                    }
                    return true
                }
            }
        } catch {
            // No valid transaction found
        }
        return false
    }

    // MARK: - Private

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw PurchaseError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
}


