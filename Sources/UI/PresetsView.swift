import SwiftUI

/// Presets list with apply / delete actions. Lives in the sidebar (macOS)
/// and in the controls sheet (iOS). Tapping a row applies the preset;
/// long-press / swipe deletes.
struct PresetsView: View {
    @Bindable var state: AppState
    var store: PresetStore

    @State private var showingSavePrompt = false
    @State private var newPresetName: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("PRESETS")
                    .font(.caption2).foregroundStyle(.secondary)
                Spacer()
                Button {
                    newPresetName = suggestedName(for: state.config)
                    showingSavePrompt = true
                } label: {
                    Label("Save", systemImage: "plus.circle.fill")
                        .labelStyle(.iconOnly)
                        .font(.body)
                }
                .buttonStyle(.borderless)
                .help("Save current settings as preset")
            }

            if store.presets.isEmpty {
                Text("No presets yet. Hit + to save your current settings.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                VStack(spacing: 4) {
                    ForEach(store.presets) { preset in
                        PresetRow(preset: preset,
                                  isCurrent: state.config == preset.config,
                                  onApply: { state.apply(preset) },
                                  onDelete: { store.delete(preset) })
                    }
                }
            }
        }
        .alert("Save preset", isPresented: $showingSavePrompt) {
            TextField("Name", text: $newPresetName)
            Button("Save") {
                store.save(name: newPresetName, config: state.config)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Give this configuration a name so you can recall it later.")
        }
    }

    /// A short generated suggestion combining pattern + background — users
    /// will usually overwrite, but it makes the prompt feel populated.
    private func suggestedName(for config: RenderConfig) -> String {
        "\(config.pattern.displayName.split(separator: " ").first ?? "Preset") · \(config.background.displayName)"
    }
}

private struct PresetRow: View {
    let preset: Preset
    let isCurrent: Bool
    let onApply: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onApply) {
            HStack(spacing: 10) {
                colorSwatch
                    .frame(width: 22, height: 22)
                VStack(alignment: .leading, spacing: 1) {
                    Text(preset.name)
                        .font(.callout)
                        .lineLimit(1)
                    Text(preset.config.pattern.displayName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                if isCurrent {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.tint)
                        .font(.caption)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(isCurrent ? Color.accentColor.opacity(0.10) : Color.clear,
                    in: RoundedRectangle(cornerRadius: 6))
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        #if os(iOS)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        #endif
    }

    /// Tiny color preview built from the preset's hue + background. Gives
    /// each row a unique visual fingerprint without rendering a thumbnail.
    private var colorSwatch: some View {
        let c = preset.config
        let bgIsDark = c.background.isDark
        let hueColor = Color(hue: c.hue / 360.0,
                             saturation: 0.55,
                             brightness: bgIsDark ? 0.75 : 0.55)
        let bgColor = backgroundSwatch(c.background)
        return ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(bgColor)
            Circle()
                .fill(hueColor)
                .frame(width: 12, height: 12)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5)
        )
    }

    private func backgroundSwatch(_ bg: BackgroundPreset) -> Color {
        bg.baseRGB.color
    }
}
