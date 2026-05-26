import SwiftUI

/// Small "About" sheet — version, credits, attribution. Required reading on
/// the App Store; required by CC-BY-SA 3.0 for the Wikipedia hematopoiesis
/// cell art used in the Blood pattern.
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PurchaseStore.self) private var purchaseStore
    @State private var isRestoring = false
    @State private var restoreMessage: String?

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }
    private var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                Group {
                    section("About") {
                        Text("Cytosphere generates large-format scientific wallpapers — twelve generative patterns drawn from biology, chemistry, and physics, all rendered natively at up to 16K.")
                    }

                    section("Patterns") {
                        Text("Blood elements (hematopoiesis), mitosis, parasites, electric & magnetic fields, atomic orbitals (hybrid + schematic), Bohr atoms, Feynman diagrams, molecular structures, bacterial morphology, viral capsids, and cell organelles (sketch + textbook).")
                    }

                    section("Attribution") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("The Blood pattern's cell illustrations are derived from File:Hematopoiesis_simple.svg by A. Rad and Mikael Häggström, via Wikimedia Commons, licensed under Creative Commons Attribution-ShareAlike 3.0 (CC-BY-SA 3.0).")
                            Link("Wikimedia source",
                                 destination: URL(string: "https://commons.wikimedia.org/wiki/File:Hematopoiesis_simple.svg")!)
                                .font(.footnote)
                        }
                    }

                    section("Made by") {
                        Text("Aintmer")
                    }

                    section("Purchase") {
                        VStack(alignment: .leading, spacing: 10) {
                            if purchaseStore.isUnlocked {
                                Label("All patterns unlocked",
                                      systemImage: "checkmark.seal.fill")
                                    .foregroundStyle(.tint)
                            } else {
                                Text("Mitosis and Sketch Organelles are free. The remaining ten patterns are available with a one-time in-app purchase.")
                            }
                            Button {
                                Task { await tapRestore() }
                            } label: {
                                HStack {
                                    if isRestoring {
                                        ProgressView().controlSize(.small)
                                    } else {
                                        Text("Restore purchases")
                                    }
                                }
                            }
                            .buttonStyle(.bordered)
                            .disabled(isRestoring)
                            if let restoreMessage {
                                Text(restoreMessage)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: 540, alignment: .leading)
        }
        #if os(macOS)
        .frame(minWidth: 480, minHeight: 520)
        #endif
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Cytosphere")
                .font(.title.bold())
            Text("Version \(version) (\(build))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func tapRestore() async {
        isRestoring = true
        defer { isRestoring = false }
        await purchaseStore.restorePurchases()
        restoreMessage = purchaseStore.isUnlocked
            ? "Restored — all patterns unlocked."
            : "No previous purchase found for this Apple ID."
    }

    @ViewBuilder
    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            content()
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
