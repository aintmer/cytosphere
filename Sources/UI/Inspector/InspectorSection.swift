import SwiftUI

/// A Lightroom-style disclosable inspector section. Header has a small label
/// + disclosure chevron on the right. Tapping anywhere on the header toggles
/// the expanded state with a smooth animation. The content is hidden when
/// collapsed.
struct InspectorSection<Content: View>: View {
    let title: String
    @Binding var isExpanded: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            header

            if isExpanded {
                content()
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Divider()
                .opacity(0.4)
        }
    }

    private var header: some View {
        Button {
            withAnimation(.snappy(duration: 0.22)) {
                isExpanded.toggle()
            }
        } label: {
            HStack {
                Text(title.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .kerning(0.6)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .rotationEffect(.degrees(isExpanded ? 0 : -90))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Persisted expansion state for the Lightroom-style inspector. Each section's
/// open/closed flag survives relaunch so users come back to whatever layout
/// they were last using.
@Observable
final class InspectorExpansion {
    private static let key = "TrajectoryWallpaper.inspectorExpansion"

    var pattern: Bool { didSet { persist() } }
    var color: Bool   { didSet { persist() } }
    var shape: Bool   { didSet { persist() } }
    var aspect: Bool  { didSet { persist() } }
    var presets: Bool { didSet { persist() } }
    var export: Bool  { didSet { persist() } }

    init() {
        // Defaults: the high-traffic sections start expanded. Shape and Aspect
        // stay collapsed since most users only tweak them occasionally.
        let saved = Self.load()
        self.pattern = saved?.pattern ?? true
        self.color   = saved?.color   ?? true
        self.shape   = saved?.shape   ?? false
        self.aspect  = saved?.aspect  ?? false
        self.presets = saved?.presets ?? true
        self.export  = saved?.export  ?? true
    }

    private struct Snapshot: Codable {
        var pattern: Bool, color: Bool, shape: Bool
        var aspect: Bool, presets: Bool, export: Bool
    }

    private func persist() {
        let snap = Snapshot(
            pattern: pattern, color: color, shape: shape,
            aspect: aspect, presets: presets, export: export
        )
        if let data = try? JSONEncoder().encode(snap) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }

    private static func load() -> Snapshot? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let snap = try? JSONDecoder().decode(Snapshot.self, from: data)
        else { return nil }
        return snap
    }
}
