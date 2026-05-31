import SwiftUI

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
                    Button {
                        state.exportQuality = quality
                    } label: {
                        Label(
                            quality.displayName,
                            systemImage: state.exportQuality == quality ? "checkmark" : ""
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

            if let line = exportStatusLine {
                Text(line.text)
                    .font(.caption2)
                    .foregroundStyle(line.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
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

    private var exportIconName: String {
        switch exportStatus {
        case .rendering, .saving: return "hourglass"
        default:                  return "square.and.arrow.up.fill"
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

    private var exportStatusLine: (text: String, color: Color)? {
        switch exportStatus {
        case .success(let msg): return ("Saved · \(msg)", .secondary)
        case .failure(let msg): return (msg, .red)
        default:                return nil
        }
    }
}
