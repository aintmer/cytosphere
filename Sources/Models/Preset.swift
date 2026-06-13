import Foundation
import Observation

/// A saved configuration the user can recall with one tap. Stores the full
/// RenderConfig snapshot so applying a preset gives an identical render.
struct Preset: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var config: RenderConfig
    var createdAt: Date

    init(id: UUID = UUID(),
         name: String,
         config: RenderConfig,
         createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.config = config
        self.createdAt = createdAt
    }
}

/// Owns the list of presets and persists them to UserDefaults as JSON.
/// Small enough that JSON-in-UserDefaults is the right call — no need for a
/// SQLite store or a separate file. Read-once-on-init, write-on-mutation.
@Observable
final class PresetStore {
    private(set) var presets: [Preset] = []
    private static let storeKey = "TrajectoryWallpaper.presets"

    init() {
        // First-launch bootstrap: ship starter presets ONLY when nothing has
        // ever been persisted. Keying on `isEmpty` would re-install them every
        // launch after the user deliberately deletes every preset; keying on
        // the existence of the storage key distinguishes a true first launch
        // from an intentionally-emptied list.
        if UserDefaults.standard.object(forKey: Self.storeKey) == nil {
            self.presets = Self.starterPresets
            persist()
        } else {
            self.presets = Self.load()
        }
    }

    // MARK: - Mutations

    func save(name: String, config: RenderConfig) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let final = trimmed.isEmpty ? "Untitled" : trimmed
        presets.append(Preset(name: final, config: config))
        persist()
        Telemetry.track(.presetSaved, ["pattern": config.pattern.rawValue])
    }

    func delete(_ preset: Preset) {
        presets.removeAll { $0.id == preset.id }
        persist()
    }

    func delete(at offsets: IndexSet) {
        presets.remove(atOffsets: offsets)
        persist()
    }

    func rename(_ preset: Preset, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let idx = presets.firstIndex(where: { $0.id == preset.id }) {
            presets[idx].name = trimmed
            persist()
        }
    }

    // MARK: - Storage

    private func persist() {
        guard let data = try? JSONEncoder().encode(presets) else { return }
        UserDefaults.standard.set(data, forKey: Self.storeKey)
    }

    private static func load() -> [Preset] {
        guard let data = UserDefaults.standard.data(forKey: storeKey),
              let decoded = try? JSONDecoder().decode([Preset].self, from: data)
        else { return [] }
        return decoded
    }

    // MARK: - Starter presets

    /// Hand-tuned starting points that showcase the range of the app. Each
    /// gives a strikingly different look — first-time users can browse them
    /// before even touching a slider.
    private static var starterPresets: [Preset] {
        [
            Preset(name: "Cell carnival",
                   config: RenderConfig(
                    pattern: .mitosis, background: .void,
                    aspect: .square6k, backgroundLightness: 0,
                    elementScale: 1.0, density: 1.0,
                    hue: 280, saturation: 35, lightness: 50,
                    alpha: 0.30, depthOfField: 1.0, seed: 1000)),
            Preset(name: "Bohr blueprint",
                   config: RenderConfig(
                    pattern: .bohr, background: .aurora,
                    aspect: .square6k, backgroundLightness: 0,
                    elementScale: 0.95, density: 0.9,
                    hue: 200, saturation: 40, lightness: 55,
                    alpha: 0.32, depthOfField: 0.9, seed: 4242)),
            Preset(name: "Forest molecules",
                   config: RenderConfig(
                    pattern: .molecules, background: .forest,
                    aspect: .square6k, backgroundLightness: 0,
                    elementScale: 0.85, density: 1.05,
                    hue: 140, saturation: 30, lightness: 55,
                    alpha: 0.30, depthOfField: 0.8, seed: 7777)),
            Preset(name: "Amber capsids",
                   config: RenderConfig(
                    pattern: .viruses, background: .amber,
                    aspect: .square6k, backgroundLightness: 0,
                    elementScale: 1.05, density: 0.85,
                    hue: 30, saturation: 45, lightness: 50,
                    alpha: 0.28, depthOfField: 1.1, seed: 8888)),
            Preset(name: "Coral hematopoiesis",
                   config: RenderConfig(
                    pattern: .blood, background: .coral,
                    aspect: .square6k, backgroundLightness: 0,
                    elementScale: 1.0, density: 0.95,
                    hue: 15, saturation: 25, lightness: 45,
                    alpha: 0.35, depthOfField: 0.7, seed: 12345)),
        ]
    }
}
