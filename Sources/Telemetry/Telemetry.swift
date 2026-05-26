import Foundation

/// Lightweight telemetry abstraction. Call sites are sprinkled through the
/// app (export start/success/failure, app launch, preset save) and route to
/// whatever backend `current` points to.
///
/// The default backend (`NoOpTelemetry`) does nothing — the app ships
/// privacy-safe out of the box. To wire up a real backend later:
///
///   1. Add the SDK as a Swift Package dependency.
///   2. Implement `TelemetryBackend` in a thin adapter (see TelemetryDeck /
///      Sentry adapter notes below).
///   3. Set `Telemetry.current = MyAdapter(...)` in
///      `TrajectoryWallpaperApp.init()`.
///
/// Recommended: **TelemetryDeck** (https://telemetrydeck.com) — free up to
/// 100k signals/month, privacy-first (no PII, no IP logging), Swift SDK,
/// simple API. Perfect for an indie consumer app. Sentry is more powerful
/// (with stack traces + breadcrumbs) but more setup overhead.
enum Telemetry {
    /// Plug a backend here from `TrajectoryWallpaperApp.init()`. Defaults to
    /// a no-op so the app works fine with nothing wired up.
    nonisolated(unsafe) static var current: TelemetryBackend = NoOpTelemetry()

    /// Convenience — most call sites just need to send a named event with a
    /// small bag of string properties.
    static func track(_ event: TelemetryEvent, _ properties: [String: String] = [:]) {
        current.track(event: event.rawValue, properties: properties)
    }

    /// Record a non-fatal error. Use sparingly — only for errors that mean
    /// the app couldn't do what the user asked.
    static func recordError(_ error: Error, context: String = #function) {
        current.recordError(error: error, context: context)
    }
}

/// Strongly-typed event names. Add new ones here as we add tracked
/// interactions — keeps every dashboard event in one place.
enum TelemetryEvent: String {
    case appLaunched         = "app_launched"
    case exportStarted       = "export_started"
    case exportSucceeded     = "export_succeeded"
    case exportFailed        = "export_failed"
    case exportExpired       = "export_expired"   // backgrounded mid-render
    case presetSaved         = "preset_saved"
    case presetApplied       = "preset_applied"
    case randomizeUsed       = "randomize_used"
}

protocol TelemetryBackend: Sendable {
    func track(event: String, properties: [String: String])
    func recordError(error: Error, context: String)
}

/// No-op default. Logs to stdout in DEBUG builds so you can see events while
/// developing without sending anything to a server.
struct NoOpTelemetry: TelemetryBackend {
    func track(event: String, properties: [String: String]) {
        #if DEBUG
        let propsStr = properties.isEmpty ? ""
            : " " + properties.map { "\($0.key)=\($0.value)" }.joined(separator: " ")
        print("[Telemetry] \(event)\(propsStr)")
        #endif
    }

    func recordError(error: Error, context: String) {
        #if DEBUG
        print("[Telemetry] error in \(context): \(error.localizedDescription)")
        #endif
    }
}

// TelemetryDeck adapter lives in TelemetryDeckAdapter.swift, gated on
// `#if canImport(TelemetryDeck)`. Activate it from
// `TrajectoryWallpaperApp.init()` once the SDK is added.
