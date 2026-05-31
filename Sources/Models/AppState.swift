import SwiftUI
import Observation

/// The single source of truth for the UI. SwiftUI controls bind to these
/// properties; `config` produces an immutable snapshot for the renderer.
///
/// All render-affecting fields are persisted to UserDefaults on every change
/// (via `didSet`), and reloaded on launch, so users come back to whatever
/// they were last looking at. The export-quality preference is persisted too.
@Observable
final class AppState {
    // didSet on every property is verbose but explicit — when ANY render
    // setting changes, we re-snapshot the config and write it to UserDefaults.
    var pattern: Pattern                    { didSet { persistConfig() } }
    var background: BackgroundPreset        { didSet { persistConfig() } }
    var backgroundLightness: Double         { didSet { persistConfig() } }
    var aspect: AspectPreset                { didSet { persistConfig() } }
    var elementScale: Double                { didSet { persistConfig() } }
    var density: Double                     { didSet { persistConfig() } }
    var hue: Double                         { didSet { persistConfig() } }
    var saturation: Double                  { didSet { persistConfig() } }
    var lightness: Double                   { didSet { persistConfig() } }
    var alpha: Double                       { didSet { persistConfig() } }
    var depthOfField: Double                { didSet { persistConfig() } }
    var seed: Int                           { didSet { persistConfig() } }
    var exportQuality: ExportQuality        { didSet { persistExportQuality() } }

    /// Immutable snapshot for the renderer.
    var config: RenderConfig {
        RenderConfig(
            pattern: pattern,
            background: background,
            aspect: aspect,
            backgroundLightness: backgroundLightness,
            elementScale: elementScale,
            density: density,
            hue: hue,
            saturation: saturation,
            lightness: lightness,
            alpha: alpha,
            depthOfField: depthOfField,
            seed: seed
        )
    }

    // MARK: - Init / persistence

    init() {
        // Load saved config if present, otherwise use defaults. The fallback
        // values match the original AppState defaults — `mitosis` pattern,
        // `void` background, etc.
        let loaded = Self.loadPersistedConfig()
        self.pattern             = loaded?.pattern             ?? .mitosis
        self.background          = loaded?.background          ?? .void
        self.backgroundLightness = loaded?.backgroundLightness ?? 0
        // Default aspect varies by platform — iPhone fills the screen with
        // a portrait wallpaper, Mac/iPad default to a square so the export
        // works generally. Once the user picks an aspect, that wins.
        #if os(iOS)
        self.aspect              = loaded?.aspect              ?? .iPhonePortrait
        #else
        self.aspect              = loaded?.aspect              ?? .square6k
        #endif
        self.elementScale        = loaded?.elementScale        ?? 1.0
        self.density             = loaded?.density             ?? 1.0
        self.hue                 = loaded?.hue                 ?? 0
        self.saturation          = loaded?.saturation          ?? 20
        self.lightness           = loaded?.lightness           ?? 45
        self.alpha               = loaded?.alpha               ?? 0.30
        self.depthOfField        = loaded?.depthOfField        ?? 1.0
        self.seed                = loaded?.seed                ?? 1000
        self.exportQuality       = Self.loadPersistedExportQuality()
            ?? (DeviceCapabilities.availableQualities.first ?? .standard)
    }

    private static let configKey = "TrajectoryWallpaper.config"
    private static let exportQualityKey = "TrajectoryWallpaper.exportQuality"

    private func persistConfig() {
        guard let data = try? JSONEncoder().encode(config) else { return }
        UserDefaults.standard.set(data, forKey: Self.configKey)
    }

    private func persistExportQuality() {
        UserDefaults.standard.set(exportQuality.rawValue,
                                  forKey: Self.exportQualityKey)
    }

    private static func loadPersistedConfig() -> RenderConfig? {
        guard let data = UserDefaults.standard.data(forKey: configKey) else {
            return nil
        }
        return try? JSONDecoder().decode(RenderConfig.self, from: data)
    }

    private static func loadPersistedExportQuality() -> ExportQuality? {
        guard let raw = UserDefaults.standard.string(forKey: exportQualityKey)
        else { return nil }
        let parsed = ExportQuality(rawValue: raw)
        // Don't restore a quality the current device can't handle (e.g. user
        // restored a backup to an older device).
        if let parsed, DeviceCapabilities.availableQualities.contains(parsed) {
            return parsed
        }
        return nil
    }

    // MARK: - Actions

    /// New random seed only — preserves the user's color, pattern, and slider
    /// choices. Useful for cycling variations of the same look.
    func reroll() {
        seed = Int.random(in: 0...999_999)
    }

    /// Full "surprise me" — picks a random pattern and randomizes every
    /// continuous slider within a tasteful range (avoids extreme values that
    /// produce visually unappealing results). Also picks a fresh seed.
    func randomize() {
        Telemetry.track(.randomizeUsed)
        // Picks weighted toward patterns that hold up well at default settings;
        // every pattern still has a chance to appear.
        pattern              = Pattern.allCases.randomElement() ?? .mitosis
        background           = BackgroundPreset.allCases.randomElement() ?? .void
        backgroundLightness  = Double.random(in: -30...30)
        elementScale         = Double.random(in: 0.7...1.3)
        density              = Double.random(in: 0.5...1.2)
        hue                  = Double.random(in: 0...360)
        saturation           = Double.random(in: 10...50)
        lightness            = Double.random(in: 30...65)
        alpha                = Double.random(in: 0.18...0.5)
        depthOfField         = Double.random(in: 0.3...1.6)
        seed                 = Int.random(in: 0...999_999)
        // aspect + exportQuality intentionally NOT randomised — those are
        // user-intent decisions, not aesthetic.
    }

    /// Restore the original "out-of-the-box" config.
    func resetToDefaults() {
        pattern              = .mitosis
        background           = .void
        backgroundLightness  = 0
        elementScale         = 1.0
        density              = 1.0
        hue                  = 0
        saturation           = 20
        lightness            = 45
        alpha                = 0.30
        depthOfField         = 1.0
        seed                 = 1000
        // aspect + exportQuality preserved.
    }

    /// Apply a saved preset's settings (everything except aspect + quality,
    /// since those are output-shape decisions independent of look).
    func apply(_ preset: Preset) {
        Telemetry.track(.presetApplied, ["name": preset.name])
        let c = preset.config
        pattern              = c.pattern
        background           = c.background
        backgroundLightness  = c.backgroundLightness
        elementScale         = c.elementScale
        density              = c.density
        hue                  = c.hue
        saturation           = c.saturation
        lightness            = c.lightness
        alpha                = c.alpha
        depthOfField         = c.depthOfField
        seed                 = c.seed
    }
}
