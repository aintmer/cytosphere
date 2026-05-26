import Foundation

// The TelemetryDeck adapter is wrapped in `#if canImport(TelemetryDeck)` so
// this file is a no-op until the SDK is actually added as a Swift Package
// dependency. That keeps the project building cleanly out of the box while
// the activation step is still pending.
//
// To activate:
//   1. Sign up at telemetrydeck.com (free, no card).
//   2. Create an app there, copy its App ID (a UUID).
//   3. In Xcode → File → Add Package Dependencies…
//        URL: https://github.com/TelemetryDeck/SwiftSDK
//        Add to target: TrajectoryWallpaper
//   4. In TrajectoryWallpaperApp.init(), uncomment:
//        Telemetry.current = TelemetryDeckAdapter(appID: "YOUR-APP-ID-HERE")
//
// Network destination: nom.telemetrydeck.com (declared so privacy review can
// list the data sent — see TelemetryDeck's docs for the on-the-wire format).

#if canImport(TelemetryDeck)
import TelemetryDeck

struct TelemetryDeckAdapter: TelemetryBackend {
    init(appID: String) {
        let config = TelemetryDeck.Config(appID: appID)
        TelemetryDeck.initialize(config: config)
    }

    func track(event: String, properties: [String: String]) {
        TelemetryDeck.signal(event, parameters: properties)
    }

    func recordError(error: Error, context: String) {
        TelemetryDeck.signal("error", parameters: [
            "context": context,
            "description": error.localizedDescription,
        ])
    }
}
#endif
