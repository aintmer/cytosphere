import SwiftUI

/// Root layout. macOS: canvas + sidebar side by side. iOS: full-bleed canvas
/// with the controls in a bottom sheet.
struct ContentView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        #if os(macOS)
        HSplitView {
            CanvasView(config: state.config, aspect: state.aspect)
                .frame(minWidth: 420)
                .padding()
            SidebarView(state: state)
                .frame(width: 320)
        }
        .frame(minWidth: 920, minHeight: 660)
        #else
        iosLayout
        #endif
    }

    #if !os(macOS)
    @State private var showControls = true

    private var iosLayout: some View {
        CanvasView(config: state.config, aspect: state.aspect)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .ignoresSafeArea()
            .overlay(alignment: .bottomTrailing) {
                Button {
                    showControls.toggle()
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title3)
                        .padding(14)
                        .background(.thinMaterial, in: Circle())
                }
                .padding()
            }
            .sheet(isPresented: $showControls) {
                SidebarView(state: state)
                    .presentationDetents([.medium, .large])
                    .presentationBackgroundInteraction(.enabled)
            }
    }
    #endif
}
