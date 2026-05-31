import SwiftUI

/// Color category — hue, saturation, lightness, opacity.
struct ColorPanel: View {
    @Bindable var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HapticSlider(
                label: "Hue base",
                value: $state.hue,
                range: 0...360,
                step: 1,
                format: { "\(Int($0))°" }
            )
            HapticSlider(
                label: "Saturation",
                value: $state.saturation,
                range: 0...60,
                step: 1,
                format: { "\(Int($0))" }
            )
            HapticSlider(
                label: "Lightness",
                value: $state.lightness,
                range: 20...75,
                step: 1,
                format: { "\(Int($0))" }
            )
            HapticSlider(
                label: "Opacity",
                value: $state.alpha,
                range: 0.05...0.7,
                step: 0.01,
                format: { String(format: "%.2f", $0) }
            )
        }
    }
}
