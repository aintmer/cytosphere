import Foundation

/// Export resolution tiers. The "Ultra" tier is only offered on devices with
/// enough RAM to hold a 16000×16000 RGBA bitmap (~1 GB) comfortably.
enum ExportQuality: String, CaseIterable, Identifiable, Hashable, Codable {
    case standard
    case high
    case ultra

    var id: String { rawValue }

    /// Longest-side pixel dimension.
    var dimension: Int {
        switch self {
        case .standard: return 6000
        case .high:     return 10000
        case .ultra:    return 16000
        }
    }

    var displayName: String {
        switch self {
        case .standard: return "Standard — 6K"
        case .high:     return "High — 10K"
        case .ultra:    return "Ultra — 16K"
        }
    }

    /// The highest tier available without the in-app unlock. Tiers above this
    /// require `unlock_all` — this mirrors the paywall + StoreKit promise that
    /// the full export-resolution range is part of the purchase. Gating is
    /// applied centrally via `PurchaseStore.canAccess(_:)`.
    static let freeCeiling: ExportQuality = .standard

    /// Whether this tier is usable without the unlock.
    var isFreeTier: Bool { dimension <= ExportQuality.freeCeiling.dimension }
}

/// Picks the export tiers a device can handle, based on physical RAM.
enum DeviceCapabilities {
    static var memoryGB: Double {
        Double(ProcessInfo.processInfo.physicalMemory) / 1_073_741_824
    }

    /// Highest tier this device may offer.
    ///
    /// `ProcessInfo.physicalMemory` under-reports vs marketed RAM: an "8 GB"
    /// iPhone returns ~7.4 GiB here, a "6 GB" device ~5.6 GiB, a "4 GB" device
    /// ~3.7 GiB. The thresholds sit in the GAPS between those clusters so each
    /// RAM class buckets correctly. (The previous 7.5 cutoff sat just above
    /// what 8 GB phones report, silently demoting them to High and hiding the
    /// 16K tier — observed on an iPhone 16 Pro Max, which has 8 GB.)
    static var maxQuality: ExportQuality {
        let gb = memoryGB
        if gb >= 7.0 { return .ultra }   // 8 GB devices (~7.4 GiB reported)
        if gb >= 5.0 { return .high }    // 6 GB devices (~5.6 GiB reported)
        return .standard                 // 4 GB and below
    }

    static var availableQualities: [ExportQuality] {
        let cap = maxQuality.dimension
        return ExportQuality.allCases.filter { $0.dimension <= cap }
    }
}
