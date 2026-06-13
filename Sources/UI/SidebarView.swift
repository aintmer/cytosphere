import SwiftUI

/// The controls panel. On macOS it sits beside the canvas; on iOS it is
/// presented as a sheet.
struct SidebarView: View {
    @Bindable var state: AppState
    @Environment(PresetStore.self) private var presetStore
    @Environment(PurchaseStore.self) private var purchaseStore
    @State private var exportStatus: Exporter.Status = .idle
    @State private var showingAbout = false
    @State private var showingPaywall = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                PresetsView(state: state, store: presetStore)

                Divider()

                labeledPicker("Pattern", selection: $state.pattern) {
                    ForEach(Pattern.allCases) { pattern in
                        // Append a lock icon (🔒) on paid patterns when the
                        // user hasn't unlocked yet — surfaces the gating
                        // BEFORE they try to export.
                        let label = pattern.displayName +
                            (purchaseStore.canAccess(pattern) ? "" : " 🔒")
                        Text(label).tag(pattern)
                    }
                }
                labeledPicker("Background", selection: $state.background) {
                    ForEach(BackgroundPreset.allCases) { Text($0.displayName).tag($0) }
                }
                SliderRow(label: "Background lightness",
                          value: $state.backgroundLightness,
                          range: -100...100, step: 1) { v in
                    (v > 0 ? "+" : "") + String(Int(v))
                }
                labeledPicker("Aspect", selection: $state.aspect) {
                    ForEach(AspectPreset.allCases) { Text($0.displayName).tag($0) }
                }

                Divider()

                SliderRow(label: "Element scale", value: $state.elementScale,
                          range: 0.4...1.5, step: 0.05)
                SliderRow(label: "Density", value: $state.density,
                          range: 0.1...1.5, step: 0.05)
                SliderRow(label: "Hue base", value: $state.hue,
                          range: 0...360, step: 1) { "\(Int($0))°" }
                SliderRow(label: "Saturation", value: $state.saturation,
                          range: 0...60, step: 1) { "\(Int($0))" }
                SliderRow(label: "Lightness", value: $state.lightness,
                          range: 20...75, step: 1) { "\(Int($0))" }
                SliderRow(label: "Opacity", value: $state.alpha,
                          range: 0.05...0.7, step: 0.01)
                SliderRow(label: "Depth of field", value: $state.depthOfField,
                          range: 0...2, step: 0.05)

                Divider()

                HStack {
                    Text("SEED")
                        .font(.caption2).foregroundStyle(.secondary)
                    Spacer()
                    Text("\(state.seed)")
                        .font(.caption2.monospacedDigit())
                }
                HStack(spacing: 8) {
                    Button {
                        state.reroll()
                    } label: {
                        Label("Re-roll", systemImage: "dice")
                            .frame(maxWidth: .infinity)
                    }
                    .help("New random seed, same look")

                    Button {
                        state.randomize()
                    } label: {
                        Label("Surprise me", systemImage: "wand.and.stars")
                            .frame(maxWidth: .infinity)
                    }
                    .help("Random pattern + random everything")
                }

                Divider()

                labeledPicker("Export quality", selection: $state.exportQuality) {
                    ForEach(DeviceCapabilities.availableQualities) { quality in
                        // 🔒 on tiers above the free ceiling until unlocked —
                        // mirrors the pattern picker; export is gated below.
                        let label = quality.displayName +
                            (purchaseStore.canAccess(quality) ? "" : " 🔒")
                        Text(label).tag(quality)
                    }
                }
                Button(exportButtonLabel) {
                    // Gate export on the unlock entitlement — a paid pattern OR
                    // a paid resolution with no purchase opens the paywall
                    // instead of exporting.
                    guard purchaseStore.canAccess(state.pattern),
                          purchaseStore.canAccess(state.exportQuality) else {
                        showingPaywall = true
                        return
                    }
                    let config = state.config
                    let aspect = state.aspect
                    let quality = state.exportQuality
                    Task {
                        await Exporter.export(
                            config: config, aspect: aspect, quality: quality
                        ) { exportStatus = $0 }
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(isExporting)

                if let line = exportStatusLine {
                    Text(line.text)
                        .font(.caption2)
                        .foregroundStyle(line.color)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Divider()

                HStack {
                    Button {
                        state.resetToDefaults()
                    } label: {
                        Text("Reset")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)

                    Spacer()

                    Button {
                        showingAbout = true
                    } label: {
                        Text("About")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingAbout) {
            #if os(macOS)
            NavigationStack { AboutView() }
            #else
            NavigationStack { AboutView() }
                .presentationDetents([.medium, .large])
            #endif
        }
        .sheet(isPresented: $showingPaywall) {
            #if os(macOS)
            NavigationStack { PaywallView() }
            #else
            NavigationStack { PaywallView() }
                .presentationDetents([.large])
            #endif
        }
    }

    private var header: some View {
        HStack {
            Text("CYTOSPHERE")
                .font(.caption).bold()
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private var isExporting: Bool {
        switch exportStatus {
        case .rendering, .saving: return true
        default:                  return false
        }
    }

    private var exportButtonLabel: String {
        switch exportStatus {
        case .rendering: return "Rendering…"
        case .saving:    return "Saving…"
        default:
            return (purchaseStore.canAccess(state.pattern)
                    && purchaseStore.canAccess(state.exportQuality))
                ? "Export PNG"
                : "Unlock to export"
        }
    }

    private var exportStatusLine: (text: String, color: Color)? {
        switch exportStatus {
        case .success(let msg):  return ("Saved · \(msg)", .secondary)
        case .failure(let msg):  return (msg, .red)
        default:                 return nil
        }
    }

    @ViewBuilder
    private func labeledPicker<S: Hashable, Content: View>(
        _ title: String,
        selection: Binding<S>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2).foregroundStyle(.secondary)
            Picker(title, selection: selection, content: content)
                .labelsHidden()
                .pickerStyle(.menu)
        }
    }
}
