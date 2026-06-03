import SwiftUI

/// A row showing "LABEL [current value ▾]". Tap anywhere on the row to open
/// a menu with all options. Used for Pattern, Background, Aspect, Quality —
/// any single-selection field with > 2 options. Keeps the panel compact while
/// surfacing the current selection. Works on iOS / iPadOS / macOS.
struct MenuRow<Content: View>: View {
    let label: String
    let currentDisplay: String
    let accessoryImage: String?
    @ViewBuilder let menuContent: () -> Content

    init(
        label: String,
        currentDisplay: String,
        accessoryImage: String? = nil,
        @ViewBuilder menuContent: @escaping () -> Content
    ) {
        self.label = label
        self.currentDisplay = currentDisplay
        self.accessoryImage = accessoryImage
        self.menuContent = menuContent
    }

    var body: some View {
        Menu {
            menuContent()
        } label: {
            // Adapt to Dynamic Type. At normal sizes the label and value sit on
            // one line; at large accessibility text sizes — where a single line
            // would squeeze the value down to "Mit…" (as App Review-adjacent
            // testing showed on the narrow iPad mini) — the value drops beneath
            // the label and wraps, so the full selection stays readable on every
            // device and text size.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    labelText
                    Spacer(minLength: 8)
                    valueCapsule
                }
                VStack(alignment: .leading, spacing: 6) {
                    labelText
                    valueCapsule
                }
            }
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuOrder(.fixed)
    }

    private var labelText: some View {
        Text(label.uppercased())
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
    }

    private var valueCapsule: some View {
        HStack(spacing: 6) {
            Text(currentDisplay)
                .font(.callout.weight(.medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
            if let accessoryImage {
                Image(systemName: accessoryImage)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(Color.primary.opacity(0.08))
        )
    }
}
