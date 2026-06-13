import Foundation
import StoreKit
import Observation

/// All product IDs used by the app, in one place so the App Store Connect
/// product config and the local StoreKit Configuration file stay in sync.
enum ProductID {
    /// One-time non-consumable: unlocks every gated pattern + full export
    /// resolution. Same product ID in App Store Connect and in the local
    /// `.storekit` config.
    static let unlockAll = "com.aintmer.cytosphere.unlock_all"

    static let all: [String] = [unlockAll]
}

/// Owns the StoreKit 2 product list + entitlement state. Inject via
/// `@Environment(PurchaseStore.self)` from the app root and observe
/// `isUnlocked` to gate paid content.
///
/// Lifecycle:
///   1. On init, kicks off `loadProducts()` and starts the transaction
///      listener.
///   2. `loadProducts()` fetches product metadata from Apple (or the local
///      StoreKit config in DEBUG).
///   3. `refreshEntitlements()` walks `Transaction.currentEntitlements` to
///      see whether the user owns `unlock_all`.
///   4. `purchase(_:)` triggers the App Store purchase sheet, awaits the
///      result, refreshes entitlements.
///   5. `restorePurchases()` calls `AppStore.sync()` to re-verify with Apple
///      then refreshes entitlements.
@Observable
final class PurchaseStore {
    private(set) var products: [Product] = []
    private(set) var isUnlocked: Bool = false
    private(set) var isLoadingProducts: Bool = false
    private(set) var lastError: String?

    private var transactionListener: Task<Void, Never>?

    init() {
        // Start listening for transaction updates BEFORE loading products so
        // we don't miss any in-flight purchase (e.g. parental-approval flow
        // that completes minutes later).
        transactionListener = listenForTransactions()
        Task { @MainActor in
            await loadProducts()
            await refreshEntitlements()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Product loading

    @MainActor
    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            products = try await Product.products(for: ProductID.all)
            Telemetry.track(.appLaunched, ["products_loaded": "\(products.count)"])
        } catch {
            lastError = error.localizedDescription
            Telemetry.recordError(error, context: "loadProducts")
        }
    }

    var unlockAllProduct: Product? {
        products.first { $0.id == ProductID.unlockAll }
    }

    /// Localized display price (e.g. "$9.99", "9,99 €") for the unlock
    /// product. Falls back to a placeholder if products haven't loaded yet.
    var unlockAllPriceText: String {
        unlockAllProduct?.displayPrice ?? "—"
    }

    // MARK: - Purchase

    @MainActor
    func purchase(_ product: Product) async -> PurchaseOutcome {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let tx = try checkVerified(verification)
                await tx.finish()
                await refreshEntitlements()
                Telemetry.track(.exportSucceeded, ["iap": product.id])
                return .success
            case .userCancelled:
                return .cancelled
            case .pending:
                // Awaiting external action (parental approval, Ask to Buy,
                // SCA bank step). The transaction listener picks it up later.
                return .pending
            @unknown default:
                return .cancelled
            }
        } catch {
            lastError = error.localizedDescription
            Telemetry.recordError(error, context: "purchase")
            return .failed(error.localizedDescription)
        }
    }

    enum PurchaseOutcome {
        case success, cancelled, pending, failed(String)
    }

    // MARK: - Restore

    enum RestoreOutcome {
        /// `AppStore.sync()` succeeded and an active `unlock_all` entitlement
        /// is present.
        case unlocked
        /// Sync succeeded but no entitlement was found for this Apple ID.
        case noPurchaseFound
        /// Sync itself failed (offline, transient StoreKit error). The caller
        /// should offer a retry rather than claim no purchase exists.
        case failed(String)
    }

    @MainActor
    func restorePurchases() async -> RestoreOutcome {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            return isUnlocked ? .unlocked : .noPurchaseFound
        } catch {
            lastError = error.localizedDescription
            Telemetry.recordError(error, context: "restorePurchases")
            return .failed(error.localizedDescription)
        }
    }

    // MARK: - Entitlement check

    @MainActor
    func refreshEntitlements() async {
        var unlocked = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result, tx.productID == ProductID.unlockAll,
               tx.revocationDate == nil {
                unlocked = true
            }
        }
        isUnlocked = unlocked
    }

    /// True if the given pattern is available to the current user. Free
    /// patterns are always available; paid patterns require `isUnlocked`.
    func canAccess(_ pattern: Pattern) -> Bool {
        pattern.isFree || isUnlocked
    }

    /// True if the given export quality is available to the current user.
    /// Standard (6K) is free; higher resolutions require `isUnlocked`. Keeps
    /// the export pipeline aligned with the paywall + StoreKit promise that
    /// the full resolution range is part of the purchase.
    func canAccess(_ quality: ExportQuality) -> Bool {
        quality.isFreeTier || isUnlocked
    }

    // MARK: - Transaction listener (handles updates from outside the app —
    // ASK_TO_BUY approvals, family sharing, App Store-side refunds, etc.)

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await update in Transaction.updates {
                guard let self,
                      case .verified(let tx) = update else { continue }
                await tx.finish()
                await self.refreshEntitlements()
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let v):       return v
        case .unverified(_, let err): throw err
        }
    }
}
