#if !os(macOS)
import SwiftUI
import UIKit

/// The iOS editor — photo-editor pattern with a *native* bottom bar.
///
/// Preview is always full-bleed behind everything. The category selector is a
/// genuine `.bottomBar` toolbar, so the system renders its Liquid Glass and
/// manages layout / scroll-edge behavior (hybrid: native bar chrome, but we
/// keep the floating panel + persistent live preview rather than letting a
/// TabView swap the whole screen per category).
struct EditorScreen: View {
    @Environment(AppState.self) private var state
    @Environment(PresetStore.self) private var presetStore
    @Environment(PurchaseStore.self) private var purchaseStore

    @State private var selectedCategory: EditorCategory? = .pattern
    @State private var showingAbout = false
    @State private var showingPaywall = false
    @State private var exportStatus: Exporter.Status = .idle

    private let selectionHaptic = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        @Bindable var state = state

        NavigationStack {
            ZStack(alignment: .topTrailing) {
                // Preview — full-bleed behind everything. Pinch to zoom / drag
                // to pan / double-tap to reset live in CanvasView. A single tap
                // dismisses an open panel — passed as `onSingleTap` (and only
                // wired when a panel is open, so it never competes with the
                // floating buttons otherwise).
                CanvasView(config: state.config, aspect: state.aspect,
                           onSingleTap: selectedCategory == nil ? nil : {
                               withAnimation(.snappy(duration: 0.3, extraBounce: 0.12)) {
                                   selectedCategory = nil
                               }
                           })
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                    .ignoresSafeArea()

                // Top-right floating glass cluster: Re-roll · Surprise · About.
                topCluster
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
            }
            // The active category panel floats just above the native bottom bar.
            .safeAreaInset(edge: .bottom) { panelInset }
            .toolbar(.hidden, for: .navigationBar)
            .toolbar { bottomBarContent }
            .onAppear { selectionHaptic.prepare() }
        }
        .sheet(isPresented: $showingAbout) {
            NavigationStack { AboutView() }
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingPaywall) {
            NavigationStack { PaywallView() }
                .presentationDetents([.large])
        }
    }

    // MARK: - Top cluster

    private var topCluster: some View {
        @Bindable var state = state
        return CytosphereGlassContainer(spacing: 14) {
            HStack(spacing: 8) {
                FloatingActions(state: state)
                GlassIconButton(systemImage: "info.circle",
                                accessibilityLabel: "About Cytosphere") {
                    showingAbout = true
                }
            }
        }
    }

    // MARK: - Floating panel (above the native bar)

    @ViewBuilder
    private var panelInset: some View {
        if let category = selectedCategory {
            panel(for: category)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .cytospherePanelGlass()
                .padding(.horizontal, 12)
                .padding(.bottom, 6)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - Native bottom bar

    @ToolbarContentBuilder
    private var bottomBarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            ForEach(Array(EditorCategory.allCases.enumerated()), id: \.element) { idx, category in
                categoryButton(category)
                if idx < EditorCategory.allCases.count - 1 {
                    Spacer()
                }
            }
        }
    }

    private func categoryButton(_ category: EditorCategory) -> some View {
        let isSelected = selectedCategory == category
        return Button {
            selectionHaptic.impactOccurred(intensity: 0.6)
            withAnimation(.snappy(duration: 0.3, extraBounce: 0.16)) {
                selectedCategory = isSelected ? nil : category
            }
        } label: {
            Image(systemName: category.systemImage)
                .font(.system(size: 18, weight: isSelected ? .bold : .semibold))
                .symbolRenderingMode(.hierarchical)
        }
        .tint(isSelected ? Color.accentColor : .secondary)
        .accessibilityLabel(category.title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: - Panel routing

    @ViewBuilder
    private func panel(for category: EditorCategory) -> some View {
        @Bindable var s = state
        VStack(alignment: .leading, spacing: 14) {
            switch category {
            case .pattern: PatternPanel(state: s)
            case .colors:  ColorPanel(state: s)
            case .shape:   ShapePanel(state: s)
            case .aspect:  AspectPanel(state: s)
            case .presets: PresetsPanel(state: s)
            case .export:  ExportPanel(
                state: s,
                showingPaywall: $showingPaywall,
                exportStatus: $exportStatus
            )
            }
        }
    }
}
#endif
