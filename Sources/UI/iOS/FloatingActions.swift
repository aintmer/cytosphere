#if !os(macOS)
import SwiftUI
import UIKit

/// Top-right floating button cluster on the preview. Two pill buttons:
/// Re-roll (new seed, same look) and Surprise me (randomize everything).
/// These live OVER the wallpaper preview so they're always reachable without
/// the user needing to open any panel.
struct FloatingActions: View {
    @Bindable var state: AppState
    private let haptic = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        HStack(spacing: 8) {
            GlassIconButton(systemImage: "dice",
                            accessibilityLabel: "Re-roll seed") {
                haptic.impactOccurred()
                withAnimation(.snappy(duration: 0.35, extraBounce: 0.15)) {
                    state.reroll()
                }
            }

            GlassIconButton(systemImage: "wand.and.stars",
                            accessibilityLabel: "Surprise me") {
                haptic.impactOccurred(intensity: 0.85)
                withAnimation(.snappy(duration: 0.45, extraBounce: 0.18)) {
                    state.randomize()
                }
            }
        }
        .onAppear { haptic.prepare() }
    }
}
#endif
