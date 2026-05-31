import SwiftUI

/// Root layout — routes by platform and (on iOS) horizontal size class:
/// - iPhone (compact)  → `EditorScreen` (photo-editor: bottom toolbar + floating panel)
/// - iPad   (regular)  → `InspectorScreen` (side panel with category tabs)
/// - macOS             → `InspectorScreen`
///
/// The Mac and iPad paths share `InspectorScreen`. Same `EditorCategory`
/// enum and per-category panel components drive both that and the iPhone
/// layout, so behavior stays in sync.
struct ContentView: View {
    #if !os(macOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    var body: some View {
        #if os(macOS)
        // On Mac, `.toolbar` on the root view attaches to the window's
        // NSToolbar automatically — no NavigationStack needed.
        InspectorScreen()
        #else
        if horizontalSizeClass == .regular {
            // iPad in landscape, full-screen, or wide split — use the
            // Mac-style inspector. iPad in compact (narrow split) falls
            // through to the iPhone layout.
            //
            // NavigationStack wrapper is required on iOS for `.toolbar`
            // items to actually render — iOS doesn't have a window-level
            // toolbar like Mac, so toolbar items live in a navigation bar.
            NavigationStack {
                InspectorScreen()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarTitleDisplayMode(.inline)
            }
        } else {
            EditorScreen()
        }
        #endif
    }
}
