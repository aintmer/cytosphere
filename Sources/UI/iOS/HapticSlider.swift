import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// A two-line slider row with title on the left, formatted value on the right,
/// and a native slider underneath. Adds gentle haptic feedback on iOS / iPadOS
/// every time the value crosses a step boundary — same tactile feel as
/// Lightroom / Photos. macOS skips the haptic call (trackpads support haptics
/// but the Slider control handles its own feedback well enough).
struct HapticSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    var format: (Double) -> String = { String(format: "%.2f", $0) }

    @State private var lastSteppedValue: Double = .nan

    #if canImport(UIKit)
    private let haptic = UIImpactFeedbackGenerator(style: .soft)
    #endif

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(format(value))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.18), value: value)
            }
            Slider(value: $value, in: range, step: step)
                .tint(.accentColor)
                .onChange(of: value) { _, newValue in
                    let stepped = (newValue / step).rounded() * step
                    if stepped != lastSteppedValue {
                        lastSteppedValue = stepped
                        #if canImport(UIKit)
                        haptic.impactOccurred(intensity: 0.35)
                        #endif
                    }
                }
        }
        .onAppear {
            #if canImport(UIKit)
            haptic.prepare()
            #endif
        }
    }
}
