import CoreGraphics

/// Canvas proportions. The preview uses the ratio; export uses the longest
/// side scaled to the chosen ExportQuality tier (see PNGExporter).
enum AspectPreset: String, CaseIterable, Identifiable, Hashable, Codable {
    case square3k
    case square4k
    case square5k
    case square6k
    case iPhonePortrait
    case iPadPortrait

    var id: String { rawValue }

    /// Reference pixel size — also the aspect ratio source.
    var size: CGSize {
        switch self {
        case .square3k:       return CGSize(width: 3000, height: 3000)
        case .square4k:       return CGSize(width: 4000, height: 4000)
        case .square5k:       return CGSize(width: 5000, height: 5000)
        case .square6k:       return CGSize(width: 6000, height: 6000)
        case .iPhonePortrait: return CGSize(width: 1320, height: 2868)
        case .iPadPortrait:   return CGSize(width: 2048, height: 2732)
        }
    }

    var ratio: CGFloat { size.width / size.height }

    var displayName: String {
        switch self {
        case .square3k:       return "Square — 3000×3000"
        case .square4k:       return "Square — 4000×4000"
        case .square5k:       return "Square — 5000×5000"
        case .square6k:       return "Square — 6000×6000"
        case .iPhonePortrait: return "iPhone portrait — 1320×2868"
        case .iPadPortrait:   return "iPad portrait — 2048×2732"
        }
    }
}
