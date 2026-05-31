import SwiftUI

/// Presets category — horizontal scroll of preset cards with real cached
/// thumbnail renders. Tap to apply, long-press for delete.
struct PresetsPanel: View {
    @Bindable var state: AppState
    @Environment(PresetStore.self) private var store
    @Environment(PresetThumbnailStore.self) private var thumbnails

    @State private var showingSavePrompt = false
    @State private var newPresetName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("PRESETS")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    newPresetName = suggestedName(for: state.config)
                    showingSavePrompt = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Save current as preset")
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    if store.presets.isEmpty {
                        Text("Tap + to save the current look")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 24)
                    } else {
                        ForEach(store.presets) { preset in
                            PresetCard(
                                preset: preset,
                                isCurrent: state.config == preset.config
                            ) {
                                state.apply(preset)
                            } onDelete: {
                                store.delete(preset)
                            }
                        }
                    }
                }
                .padding(.horizontal, 2)
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

    private func suggestedName(for config: RenderConfig) -> String {
        "\(config.pattern.displayName.split(separator: " ").first ?? "Preset") · \(config.background.displayName)"
    }
}

private struct PresetCard: View {
    let preset: Preset
    let isCurrent: Bool
    let onTap: () -> Void
    let onDelete: () -> Void

    @Environment(PresetThumbnailStore.self) private var thumbnails

    // Logical size of the thumbnail card. Pixel size = pt × displayScale.
    private let cardSide: CGFloat = 84

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                thumbnailView
                    .frame(width: cardSide, height: cardSide)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(isCurrent ? Color.accentColor : Color.primary.opacity(0.10),
                                    lineWidth: isCurrent ? 2.5 : 1)
                    )
                Text(preset.name)
                    .font(.caption.weight(isCurrent ? .semibold : .regular))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .frame(width: cardSide, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete preset", systemImage: "trash")
            }
        }
        .onAppear {
            // 2× pixel size — looks sharp on Retina without paying the @3x
            // cost that's invisible at this thumbnail scale.
            let pixelSide = cardSide * 2
            thumbnails.warm(preset, size: CGSize(width: pixelSide, height: pixelSide))
        }
    }

    @ViewBuilder
    private var thumbnailView: some View {
        if let image = thumbnails.image(for: preset) {
            Image(platformImage: image)
                .resizable()
                .interpolation(.medium)
                .transition(.opacity)
        } else {
            // Placeholder while the thumbnail is rendering — a soft
            // gradient based on the preset's hue + background.
            fallbackSwatch
        }
    }

    /// Color fallback shown for the brief moment before the real thumbnail
    /// lands. Derived directly from the preset config so it feels related
    /// to the eventual render.
    private var fallbackSwatch: some View {
        let c = preset.config
        let bgColor = c.background.baseRGB.color
        let hueColor = Color(
            hue: c.hue / 360.0,
            saturation: max(c.saturation / 100.0, 0.4),
            brightness: c.background.isDark ? 0.75 : 0.55
        )
        return ZStack {
            bgColor
            Circle()
                .fill(hueColor)
                .frame(width: 36, height: 36)
                .blur(radius: 8)
                .opacity(0.7)
        }
    }
}
