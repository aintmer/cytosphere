import SwiftUI

/// Pattern + background category. Pattern and Background each become a menu
/// button showing the current selection — tap to open a full picker. Background
/// lightness slider lives below.
struct PatternPanel: View {
    @Bindable var state: AppState
    @Environment(PurchaseStore.self) private var purchaseStore

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Pattern menu — locked patterns show a lock glyph next to their name
            // in the menu, but the user can still tap; gating happens at export.
            MenuRow(
                label: "Pattern",
                currentDisplay: state.pattern.displayName,
                accessoryImage: purchaseStore.canAccess(state.pattern) ? nil : "lock.fill"
            ) {
                ForEach(Pattern.allCases) { pattern in
                    Button {
                        state.pattern = pattern
                    } label: {
                        Label(
                            pattern.displayName + (purchaseStore.canAccess(pattern) ? "" : " 🔒"),
                            systemImage: state.pattern == pattern ? "checkmark" : ""
                        )
                    }
                }
            }

            MenuRow(
                label: "Background",
                currentDisplay: state.background.displayName
            ) {
                ForEach(BackgroundPreset.allCases) { bg in
                    Button {
                        state.background = bg
                    } label: {
                        Label(
                            bg.displayName,
                            systemImage: state.background == bg ? "checkmark" : ""
                        )
                    }
                }
            }

            HapticSlider(
                label: "Background lightness",
                value: $state.backgroundLightness,
                range: -100...100,
                step: 1,
                format: { v in (v > 0 ? "+" : "") + "\(Int(v))" }
            )
        }
    }
}
