import SwiftUI

@main
struct TrajectoryWallpaperApp: App {
    @State private var appState = AppState()
    @State private var presetStore = PresetStore()
    @State private var purchaseStore = PurchaseStore()
    @State private var thumbnailStore = PresetThumbnailStore()

    init() {
        // Telemetry is intentionally DISABLED for the App Store launch — the
        // Privacy nutrition label declares "Data Not Collected", so no
        // analytics signals are sent. The Telemetry abstraction stays in
        // place (calls route to NoOpTelemetry which only logs in DEBUG, never
        // hits a network), and `TelemetryDeckAdapter` is still in the
        // repo behind `#if canImport(TelemetryDeck)`. To re-enable later:
        // uncomment the assignment below + update the privacy declarations.
        //
        // #if canImport(TelemetryDeck)
        // Telemetry.current = TelemetryDeckAdapter(
        //     appID: "F9AFC066-2EFA-4D0C-AE7B-1C7B5F8AB6AF"
        // )
        // #endif

        Telemetry.track(.appLaunched)  // routes through NoOp → no network
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(presetStore)
                .environment(purchaseStore)
                .environment(thumbnailStore)
        }
        #if os(macOS)
        .defaultSize(width: 1100, height: 760)
        #endif
    }
}
