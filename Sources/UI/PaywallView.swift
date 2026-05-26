import SwiftUI
import StoreKit

/// The "Unlock All Patterns" paywall. Presented as a sheet when the user
/// taps Export on a paid pattern (or selects one without an active
/// purchase). Big, friendly, single CTA — no dark patterns.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PurchaseStore.self) private var store
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var purchaseMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                hero
                pitch
                purchaseButton
                restoreButton
                if let purchaseMessage {
                    Text(purchaseMessage)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                fineprint
            }
            .padding(28)
            .frame(maxWidth: 480)
        }
        #if os(macOS)
        .frame(minWidth: 440, minHeight: 540)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
    }

    private var hero: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.open.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
                .padding(.bottom, 4)
            Text("Unlock all patterns")
                .font(.title.bold())
                .multilineTextAlignment(.center)
            Text("One-time purchase. No subscription.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var pitch: some View {
        VStack(alignment: .leading, spacing: 12) {
            bullet("Twelve generative patterns from biology, chemistry, and physics")
            bullet("All export resolutions, up to 16K")
            bullet("Includes every future pattern pack — yours forever")
            bullet("No ads, no tracking, no subscription")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.tint)
                .font(.body)
            Text(text)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var purchaseButton: some View {
        Button {
            Task { await tapPurchase() }
        } label: {
            HStack {
                if isPurchasing {
                    ProgressView().controlSize(.small)
                } else {
                    Text("Unlock for \(store.unlockAllPriceText)")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(isPurchasing || store.unlockAllProduct == nil)
    }

    private var restoreButton: some View {
        Button {
            Task { await tapRestore() }
        } label: {
            HStack {
                if isRestoring {
                    ProgressView().controlSize(.small)
                } else {
                    Text("Restore previous purchase")
                        .font(.callout)
                }
            }
        }
        .buttonStyle(.borderless)
        .disabled(isRestoring)
    }

    private var fineprint: some View {
        Text("Payment will be charged to your Apple ID at confirmation. Restoring works on any device signed in to the same Apple ID.")
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
    }

    // MARK: - Actions

    private func tapPurchase() async {
        guard let product = store.unlockAllProduct else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        let outcome = await store.purchase(product)
        switch outcome {
        case .success:
            purchaseMessage = nil
            dismiss()
        case .pending:
            purchaseMessage = "Waiting for approval. You'll be unlocked automatically when it's approved."
        case .cancelled:
            purchaseMessage = nil   // silent — user knows they cancelled
        case .failed(let msg):
            purchaseMessage = "Purchase failed: \(msg)"
        }
    }

    private func tapRestore() async {
        isRestoring = true
        defer { isRestoring = false }
        await store.restorePurchases()
        if store.isUnlocked {
            purchaseMessage = nil
            dismiss()
        } else {
            purchaseMessage = "No previous purchase found for this Apple ID."
        }
    }
}
