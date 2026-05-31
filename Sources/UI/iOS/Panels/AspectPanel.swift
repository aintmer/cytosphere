import SwiftUI

/// Aspect category — aspect picker as a menu button + seed display.
struct AspectPanel: View {
    @Bindable var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            MenuRow(
                label: "Aspect",
                currentDisplay: state.aspect.displayName
            ) {
                ForEach(AspectPreset.allCases) { aspect in
                    Button {
                        state.aspect = aspect
                    } label: {
                        Label(
                            aspect.displayName,
                            systemImage: state.aspect == aspect ? "checkmark" : ""
                        )
                    }
                }
            }

            HStack {
                Text("SEED")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(state.seed)")
                    .font(.system(.callout, design: .monospaced))
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.25), value: state.seed)
                    .foregroundStyle(.primary)
            }
        }
    }
}
