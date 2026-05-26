import SwiftUI

@main
struct TrajectoryWallpaperApp: App {
    @State private var appState = AppState()
    @State private var presetStore = PresetStore()
    @State private var purchaseStore = PurchaseStore()

    init() {
        // TelemetryDeck wired up: events route through the adapter once the
        // SwiftSDK package is added in Xcode. Until the package is present,
        // `TelemetryDeckAdapter` is excluded by `#if canImport(...)` and
        // this assignment falls back to the NoOp default.
        #if canImport(TelemetryDeck)
        Telemetry.current = TelemetryDeckAdapter(
            appID: "F9AFC066-2EFA-4D0C-AE7B-1C7B5F8AB6AF"
        )
        #endif

        Telemetry.track(.appLaunched)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(presetStore)
                .environment(purchaseStore)
        }
        #if os(macOS)
        .defaultSize(width: 1100, height: 760)
        #endif
    }
}
