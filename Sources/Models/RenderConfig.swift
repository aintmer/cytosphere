import Foundation

/// An immutable snapshot of every render-affecting setting. Built from AppState
/// for each frame. Being a plain Equatable value type, SwiftUI can cheaply
/// diff it — the Canvas only re-renders when something actually changed, and
/// the export pipeline reuses the exact same struct.
///
/// `Codable` so it round-trips via UserDefaults (for last-used config) and
/// JSON (for the presets store).
struct RenderConfig: Equatable, Codable {
    var pattern: Pattern
    var background: BackgroundPreset
    var aspect: AspectPreset          // drives density math (logical canvas size)
    var backgroundLightness: Double   // -100...100
    var elementScale: Double          // 0.4...1.5
    var density: Double               // 0.1...1.5
    var hue: Double                   // 0...360
    var saturation: Double            // 0...60   (baseline 20)
    var lightness: Double             // 20...75  (baseline 45)
    var alpha: Double                 // 0.05...0.7
    var depthOfField: Double          // 0...2
    var seed: Int
}
