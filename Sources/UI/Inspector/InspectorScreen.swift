import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Lightroom-style canvas + inspector. Used on macOS and iPad (regular size
/// class). One scrollable right inspector with stacked, collapsible sections
/// — Pattern, Color, Shape, Aspect, Presets, Export. Primary actions
/// (Re-roll, Surprise, Reset, Export) live in a native `.toolbar` so the
/// app picks up the platform's expected chrome (NSToolbar on Mac).
struct InspectorScreen: View {
    @Environment(AppState.self) private var state
    @Environment(PresetStore.self) private var presetStore
    @Environment(PurchaseStore.self) private var purchaseStore
    @State private var expansion = InspectorExpansion()

    @State private var showingAbout = false
    @State private var showingPaywall = false
    @State private var exportStatus: Exporter.Status = .idle

    var body: some View {
        @Bindable var state = state

        canvasAndInspector
            // Window-sizing floor is a macOS concern. On iPad this forced the
            // canvas+inspector wider than the screen (e.g. 920 > 834pt on an
            // iPad Air 11" in portrait), pushing the inspector's right edge —
            // sliders, menu values, the export button — off-screen and
            // truncating text. App Review flagged exactly this (Guideline 4).
            #if os(macOS)
            .frame(minWidth: 920, minHeight: 660)
            #endif
            .toolbar { toolbarContent }
            .sheet(isPresented: $showingAbout) {
                #if os(macOS)
                NavigationStack { AboutView() }
                    .frame(minWidth: 480, minHeight: 540)
                #else
                NavigationStack { AboutView() }
                    .presentationDetents([.medium, .large])
                #endif
            }
            .sheet(isPresented: $showingPaywall) {
                #if os(macOS)
                NavigationStack { PaywallView() }
                    .frame(minWidth: 480, minHeight: 600)
                #else
                NavigationStack { PaywallView() }
                    .presentationDetents([.large])
                #endif
            }
    }

    // MARK: - Layout

    @ViewBuilder
    private var canvasAndInspector: some View {
        #if os(macOS)
        HSplitView {
            canvas
                .frame(minWidth: 440)
            inspector
                .frame(minWidth: 300, idealWidth: 320, maxWidth: 380)
        }
        #else
        HStack(spacing: 0) {
            canvas
            inspector
                .frame(width: 320)
        }
        #endif
    }

    private var canvas: some View {
        @Bindable var state = state
        return CanvasView(config: state.config, aspect: state.aspect)
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var inspector: some View {
        @Bindable var state = state

        return ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                InspectorSection(title: "Pattern",
                                 isExpanded: $expansion.pattern) {
                    PatternPanel(state: state)
                }
                InspectorSection(title: "Color",
                                 isExpanded: $expansion.color) {
                    ColorPanel(state: state)
                }
                InspectorSection(title: "Shape",
                                 isExpanded: $expansion.shape) {
                    ShapePanel(state: state)
                }
                InspectorSection(title: "Aspect & seed",
                                 isExpanded: $expansion.aspect) {
                    AspectPanel(state: state)
                }
                InspectorSection(title: "Presets",
                                 isExpanded: $expansion.presets) {
                    PresetsPanel(state: state)
                }
                InspectorSection(title: "Export",
                                 isExpanded: $expansion.export) {
                    ExportPanel(state: state,
                                showingPaywall: $showingPaywall,
                                exportStatus: $exportStatus)
                }
            }
        }
        .background(inspectorBackground)
    }

    @ViewBuilder
    private var inspectorBackground: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            Rectangle().fill(.clear).glassEffect(.regular, in: Rectangle())
        } else {
            Rectangle().fill(.thinMaterial)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        @Bindable var state = state

        ToolbarItem(placement: toolbarPlacement) {
            Button {
                withAnimation(.snappy(duration: 0.35, extraBounce: 0.15)) {
                    state.reroll()
                }
            } label: {
                Label("Re-roll seed", systemImage: "dice")
            }
            .help("Re-roll the seed — new variation of the same look (⌘R)")
            .keyboardShortcut("r", modifiers: [.command])
        }

        ToolbarItem(placement: toolbarPlacement) {
            Button {
                withAnimation(.snappy(duration: 0.45, extraBounce: 0.18)) {
                    state.randomize()
                }
            } label: {
                Label("Surprise me", systemImage: "wand.and.stars")
            }
            .help("Random pattern + every slider (⇧⌘R)")
            .keyboardShortcut("r", modifiers: [.command, .shift])
        }

        ToolbarItem(placement: toolbarPlacement) {
            Button {
                state.resetToDefaults()
            } label: {
                Label("Reset", systemImage: "arrow.counterclockwise")
            }
            .help("Reset to defaults")
        }

        #if os(macOS)
        ToolbarItem(placement: .primaryAction) {
            exportButton
        }
        #else
        ToolbarItem(placement: .topBarTrailing) {
            exportButton
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showingAbout = true
            } label: {
                Label("About", systemImage: "info.circle")
            }
        }
        #endif
    }

    private var toolbarPlacement: ToolbarItemPlacement {
        #if os(macOS)
        .automatic
        #else
        .topBarLeading
        #endif
    }

    private var exportButton: some View {
        @Bindable var state = state

        return Button(action: exportTapped) {
            Label(exportButtonLabel, systemImage: exportIcon)
                .labelStyle(.titleAndIcon)
        }
        .help("Export PNG (⌘E)")
        .keyboardShortcut("e", modifiers: [.command])
        .disabled(isExporting)
    }

    private func exportTapped() {
        guard purchaseStore.canAccess(state.pattern) else {
            showingPaywall = true
            return
        }
        let config = state.config
        let aspect = state.aspect
        let quality = state.exportQuality
        Task {
            await Exporter.export(
                config: config, aspect: aspect, quality: quality
            ) { status in
                withAnimation(.snappy(duration: 0.2)) {
                    exportStatus = status
                }
            }
        }
    }

    private var exportIcon: String {
        switch exportStatus {
        case .rendering, .saving: return "hourglass"
        default:                  return "square.and.arrow.up"
        }
    }

    private var exportButtonLabel: String {
        switch exportStatus {
        case .rendering: return "Rendering…"
        case .saving:    return "Saving…"
        default:
            return purchaseStore.canAccess(state.pattern)
                ? "Export PNG"
                : "Unlock to export"
        }
    }

    private var isExporting: Bool {
        switch exportStatus {
        case .rendering, .saving: return true
        default:                  return false
        }
    }
}
