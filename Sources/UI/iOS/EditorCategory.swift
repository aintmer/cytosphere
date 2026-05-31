import SwiftUI

/// Categories shown in the iOS bottom toolbar. Each maps to a single panel of
/// controls floating above the toolbar. The Mac sidebar shows everything at
/// once; iOS focuses on one category at a time so the wallpaper preview stays
/// visible during edits.
enum EditorCategory: String, CaseIterable, Identifiable, Hashable {
    case pattern
    case colors
    case shape
    case aspect
    case presets
    case export

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pattern: return "Pattern"
        case .colors:  return "Colors"
        case .shape:   return "Shape"
        case .aspect:  return "Aspect"
        case .presets: return "Presets"
        case .export:  return "Export"
        }
    }

    var systemImage: String {
        switch self {
        case .pattern: return "square.grid.3x3.fill"
        case .colors:  return "paintpalette.fill"
        case .shape:   return "circle.dotted"
        case .aspect:  return "aspectratio.fill"
        case .presets: return "star.fill"
        case .export:  return "square.and.arrow.up.fill"
        }
    }
}
