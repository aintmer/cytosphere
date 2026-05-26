import SwiftUI

/// A labelled slider with a live value readout — the panel's workhorse control.
struct SliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double = 0.01
    var format: (Double) -> String = { String(format: "%.2f", $0) }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label.uppercased())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(format(value))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.primary)
            }
            Slider(value: $value, in: range, step: step)
        }
    }
}
