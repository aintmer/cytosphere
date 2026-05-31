import SwiftUI

/// Shape category — element scale, density, depth of field.
struct ShapePanel: View {
    @Bindable var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HapticSlider(
                label: "Element scale",
                value: $state.elementScale,
                range: 0.4...1.5,
                step: 0.05,
                format: { String(format: "%.2f", $0) }
            )
            HapticSlider(
                label: "Density",
                value: $state.density,
                range: 0.1...1.5,
                step: 0.05,
                format: { String(format: "%.2f", $0) }
            )
            HapticSlider(
                label: "Depth of field",
                value: $state.depthOfField,
                range: 0...2,
                step: 0.05,
                format: { String(format: "%.2f", $0) }
            )
        }
    }
}
