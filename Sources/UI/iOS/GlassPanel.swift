import SwiftUI

/// Liquid Glass on iOS 26+ / macOS 26+, falls back to `.thinMaterial` on
/// older systems. The deployment targets stay at iOS 17 / macOS 14 — every
/// caller goes through one of these helpers so the availability fork lives
/// in one place.
///
/// For genuine system-quality Liquid Glass (the kind the native tab bar
/// renders) two things matter beyond just calling `.glassEffect`:
///   1. Sibling glass elements must live inside a `GlassEffectContainer`
///      (`CytosphereGlassContainer` below) so they composite and morph as
///      one liquid surface instead of rendering as flat, isolated panes.
///   2. Anything tappable should use `.interactive()` so the glass lenses
///      and brightens under touch like the system controls.
extension View {
    /// Apply a glass-style background using an arbitrary shape.
    /// Uses `.regular` Liquid Glass on iOS 26+ — Apple's standard frosted
    /// material. Older systems fall back to `.thinMaterial`, which has a
    /// similar perceived opacity.
    @ViewBuilder
    func cytosphereGlass<S: Shape>(in shape: S, interactive: Bool = false) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            self.glassEffect(interactive ? .regular.interactive() : .regular, in: shape)
        } else {
            self.background(.thinMaterial, in: shape)
        }
    }

    /// Default panel shape — a generous rounded rect tuned for the floating
    /// control panel.
    func cytospherePanelGlass() -> some View {
        cytosphereGlass(
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
    }

    /// Pill / capsule glass — used by the toolbar bar.
    func cytosphereCapsuleGlass(interactive: Bool = false) -> some View {
        cytosphereGlass(in: Capsule(style: .continuous), interactive: interactive)
    }

    /// Circular glass — used by the floating action buttons.
    func cytosphereCircleGlass(interactive: Bool = true) -> some View {
        cytosphereGlass(in: Circle(), interactive: interactive)
    }
}

/// A circular Liquid Glass icon button.
///
/// On iOS / macOS 26 it uses the **native `.glass` button style**, which gives
/// the lively *interactive* Liquid Glass (lensing/press) AND handles taps
/// correctly. Manually layering `.glassEffect(.interactive())` on a
/// `.plain` button looks the same at rest but installs its own press
/// recognizer that competes with the button's tap and drops taps — which is
/// why "Surprise me" needed several taps. Older systems fall back to a
/// `.thinMaterial` circle.
struct GlassIconButton: View {
    let systemImage: String
    var accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Group {
            if #available(iOS 26.0, macOS 26.0, *) {
                Button(action: action) {
                    Image(systemName: systemImage)
                        .font(.system(size: 17, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .controlSize(.large)
            } else {
                Button(action: action) {
                    Image(systemName: systemImage)
                        .font(.system(size: 18, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .frame(width: 44, height: 44)
                        .foregroundStyle(.primary)
                        .background(.thinMaterial, in: Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .accessibilityLabel(accessibilityLabel)
    }
}

/// Wraps content in a `GlassEffectContainer` on iOS / macOS 26 so the glass
/// elements inside composite and morph together as one genuine Liquid Glass
/// surface (the difference between "real" and "I slapped `.glassEffect` on a
/// view"). A transparent pass-through on older systems where the children
/// fall back to `.thinMaterial`.
struct CytosphereGlassContainer<Content: View>: View {
    var spacing: CGFloat = 18
    @ViewBuilder var content: () -> Content

    var body: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) { content() }
        } else {
            content()
        }
    }
}
