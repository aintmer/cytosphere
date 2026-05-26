import Foundation

/// Every wallpaper pattern. Mirrors the <option> list from the HTML reference.
enum Pattern: String, CaseIterable, Identifiable, Hashable, Codable {
    case blood
    case mitosis
    case parasites
    case fields
    case orbitals
    case orbitalsSchematic
    case bohr
    case feynman
    case molecules
    case bacteria
    case viruses
    case organellesSketch
    case organellesTextbook

    var id: String { rawValue }

    /// Free patterns ship with the app and are always available. Everything
    /// else is gated behind the `unlock_all` IAP. Chosen to give first-time
    /// users a clear taste of what the app does — Mitosis showcases the
    /// procedural-bio style, Sketch Organelles shows the hand-drawn
    /// illustrative style.
    var isFree: Bool {
        switch self {
        case .mitosis, .organellesSketch: return true
        default:                          return false
        }
    }

    var displayName: String {
        switch self {
        case .blood:              return "Blood elements — hematopoiesis"
        case .mitosis:            return "Mitosis — cell division"
        case .parasites:          return "Parasites — protozoa & helminth eggs"
        case .fields:             return "Electric & magnetic fields"
        case .orbitals:           return "Atomic orbitals — hybrid"
        case .orbitalsSchematic:  return "Atomic orbitals — schematic"
        case .bohr:               return "Bohr atoms"
        case .feynman:            return "Feynman diagrams"
        case .molecules:          return "Molecular structures"
        case .bacteria:           return "Bacterial morphology"
        case .viruses:            return "Viral capsids"
        case .organellesSketch:   return "Cell organelles — sketch"
        case .organellesTextbook: return "Cell organelles — textbook"
        }
    }
}
