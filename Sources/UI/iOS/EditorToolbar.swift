#if !os(macOS)
import SwiftUI
import UIKit

/// Persistent bottom toolbar — a row of category icons. Tapping toggles the
/// active category (re-tap collapses the panel). The toolbar is always
/// visible above the safe area; the active panel floats above it.
///
/// The whole bar is one interactive Liquid Glass capsule. The selected
/// category is marked by a tinted glass pill that *slides* between icons
/// (`matchedGeometryEffect`) rather than a flat fill fading in/out — the
/// liquid, system-tab-bar feel.
struct EditorToolbar: View {
    @Binding var selection: EditorCategory?

    @Namespace private var selectionNS
    private let selectionHaptic = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        HStack(spacing: 4) {
            ForEach(EditorCategory.allCases) { category in
                button(for: category)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .cytosphereCapsuleGlass(interactive: true)
        .onAppear { selectionHaptic.prepare() }
    }

    private func button(for category: EditorCategory) -> some View {
        let isSelected = selection == category
        return Button {
            selectionHaptic.impactOccurred(intensity: 0.6)
            withAnimation(.snappy(duration: 0.3, extraBounce: 0.16)) {
                selection = isSelected ? nil : category
            }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: category.systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .frame(height: 22)
                Text(category.title)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    SelectionPill()
                        .matchedGeometryEffect(id: "selectionPill", in: selectionNS)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(category.title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

/// The sliding indicator behind the selected category. A tinted glass capsule
/// on iOS 26 (glass-on-glass, like the system tab bar's selection), a soft
/// accent fill on older systems.
private struct SelectionPill: View {
    var body: some View {
        if #available(iOS 26.0, *) {
            Capsule(style: .continuous)
                .fill(.clear)
                .glassEffect(
                    .regular.tint(Color.accentColor.opacity(0.5)).interactive(),
                    in: Capsule(style: .continuous)
                )
        } else {
            Capsule(style: .continuous)
                .fill(Color.accentColor.opacity(0.16))
        }
    }
}
#endif
