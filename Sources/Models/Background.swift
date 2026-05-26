import Foundation

/// Background presets. Mirrors the BACKGROUNDS table from the HTML reference
/// (white + light-paper dropped, 5 warm lights added).
enum BackgroundPreset: String, CaseIterable, Identifiable, Hashable, Codable {
    case void
    case dusk
    case aurora
    case forest
    case amber
    case black
    case cream
    case butter
    case peach
    case coral
    case blush

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .void:   return "Deep void"
        case .dusk:   return "Warm dusk"
        case .aurora: return "Cool aurora"
        case .forest: return "Deep forest"
        case .amber:  return "Dark amber"
        case .black:  return "Pure black"
        case .cream:  return "Warm cream"
        case .butter: return "Soft butter"
        case .peach:  return "Soft peach"
        case .coral:  return "Warm coral"
        case .blush:  return "Pale blush"
        }
    }

    var baseRGB: RGBA {
        switch self {
        case .void:   return RGBA(hex: "#0d1019")
        case .dusk:   return RGBA(hex: "#1a0a14")
        case .aurora: return RGBA(hex: "#0a1828")
        case .forest: return RGBA(hex: "#0a1810")
        case .amber:  return RGBA(hex: "#1a1208")
        case .black:  return RGBA(hex: "#000000")
        case .cream:  return RGBA(hex: "#f4ead2")
        case .butter: return RGBA(hex: "#f4dca0")
        case .peach:  return RGBA(hex: "#f3cbab")
        case .coral:  return RGBA(hex: "#f1b4a3")
        case .blush:  return RGBA(hex: "#ecc7c5")
        }
    }

    var isDark: Bool {
        switch self {
        case .cream, .butter, .peach, .coral, .blush: return false
        default: return true
        }
    }

    var vignetteOpacity: Double {
        switch self {
        case .void, .aurora, .forest: return 0.45
        case .dusk:                   return 0.55
        case .amber:                  return 0.50
        case .black:                  return 0.0
        default:                      return 0.25
        }
    }
}
