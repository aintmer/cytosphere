import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Export category — primary CTA. Quality picker (menu button) + big Export
/// PNG button + status line.
struct ExportPanel: View {
    @Bindable var state: AppState
    @Environment(PurchaseStore.self) private var purchaseStore
    @Binding var showingPaywall: Bool
    @Binding var exportStatus: Exporter.Status

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            MenuRow(
                label: "Quality",
                currentDisplay: state.exportQuality.displayName
            ) {
                ForEach(DeviceCapabilities.availableQualities) { quality in
                    let locked = !purchaseStore.canAccess(quality)
                    Button {
                        // Selecting a locked tier opens the paywall rather than
                        // silently switching to a resolution the user can't
                        // actually export — keeps the upsell discoverable.
                        if locked {
                            showingPaywall = true
                        } else {
                            state.exportQuality = quality
                        }
                    } label: {
                        Label(
                            locked ? "\(quality.displayName) — Unlock" : quality.displayName,
                            systemImage: locked
                                ? "lock.fill"
                                : (state.exportQuality == quality ? "checkmark" : "")
                        )
                    }
                }
            }

            Button(action: exportTapped) {
                HStack {
                    Image(systemName: exportIconName)
                        .font(.system(size: 17, weight: .semibold))
                    Text(exportButtonLabel)
                        .font(.body.weight(.semibold))
                }
                .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.accentColor)
            .disabled(isExporting)

            statusFooter
        }
    }

    private func exportTapped() {
        guard canExport else {
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

    private var exportIconName: String {
        switch exportStatus {
        case .rendering, .saving: return "hourglass"
        default:                  return "square.and.arrow.up.fill"
        }
    }

    /// Export is allowed only when BOTH the pattern and the chosen export
    /// resolution are accessible to the current user.
    private var canExport: Bool {
        purchaseStore.canAccess(state.pattern)
            && purchaseStore.canAccess(state.exportQuality)
    }

    private var exportButtonLabel: String {
        switch exportStatus {
        case .rendering: return "Rendering…"
        case .saving:    return "Saving…"
        default:         return canExport ? "Export PNG" : "Unlock to export"
        }
    }

    private var isExporting: Bool {
        switch exportStatus {
        case .rendering, .saving: return true
        default:                  return false
        }
    }

    @ViewBuilder
    private var statusFooter: some View {
        switch exportStatus {
        case .failurePhotosDenied:
            VStack(alignment: .leading, spacing: 6) {
                Text("Photos access is off, so the export can't be saved. Turn it on in Settings.")
                    .font(.caption2)
                    .foregroundStyle(.red)
                #if canImport(UIKit)
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.caption2.weight(.semibold))
                .buttonStyle(.bordered)
                .controlSize(.small)
                #endif
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .transition(.opacity.combined(with: .move(edge: .top)))
        case .success(let msg):
            statusLine("Saved · \(msg)", color: .secondary)
        case .failure(let msg):
            statusLine(msg, color: .red)
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func statusLine(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2)
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .transition(.opacity.combined(with: .move(edge: .top)))
    }
}
