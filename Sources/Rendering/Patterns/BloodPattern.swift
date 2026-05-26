import CoreGraphics
import Foundation

/// Hematopoiesis pattern. Uses the Wikipedia cell symbol library
/// (CC-BY-SA 3.0 — see HematopoiesisLibrary) rendered via Core Graphics.
///
/// Hue/sat/light sliders recolor the whole library coherently — each path's
/// fill is routed through paletteShift. At baseline (hue=0, sat=20, light=45)
/// the operation is a no-op so cells render in their exact Wikipedia colors.
enum BloodPattern {

    /// Roster weighted for wallpaper variety, mirroring the HTML reference.
    /// RBCs dominate, neutrophils next, rare types (megakaryocyte, blast,
    /// plasma) kept as occasional foreground heroes.
    static let roster: [String] = [
        "cell_erythrocyte", "cell_erythrocyte", "cell_erythrocyte",
        "cell_erythrocyte", "cell_erythrocyte", "cell_erythrocyte",
        "cell_neutrophil", "cell_neutrophil", "cell_neutrophil", "cell_neutrophil",
        "cell_eosinophil", "cell_eosinophil",
        "cell_basophil",
        "cell_mast_cell",
        "cell_monocyte", "cell_monocyte",
        "cell_macrophage",
        "cell_small_lymphocyte", "cell_small_lymphocyte", "cell_small_lymphocyte",
        "cell_natural_killer_cell", "cell_natural_killer_cell",
        "cell_t_lymphocyte", "cell_t_lymphocyte",
        "cell_b_lymphocyte", "cell_b_lymphocyte",
        "cell_plasma_cell",
        "cell_thrombocytes", "cell_thrombocytes",
        "cell_megakaryocyte",
        "cell_myeloblast",
        "cell_multipotential_hematopoietic_stem_cell",
        "cell_common_myeloid_progenitor",
        "cell_common_lymphoid_progenitor",
    ]

    /// Largest natural dimension across the roster (the megakaryocyte) — used
    /// to compute each cell's PROPORTIONAL size so Wikipedia's relative
    /// scaling is preserved (a megakaryocyte fills its slot; a thrombocyte
    /// at the same slot draws much smaller).
    private static let maxNatural: Double = {
        let cells = HematopoiesisLibrary.shared.cells.values
        return cells.map { max($0.width, $0.height) }.max() ?? 275
    }()

    static func draw(in cg: CGContext, size: CGSize, config: RenderConfig,
                     scale: Double, areaScale: Double, prng: PRNG) {
        let lib = HematopoiesisLibrary.shared
        guard !lib.cells.isEmpty else { return }

        PlacementEngine.place(in: cg, size: size, config: config,
                              scale: scale, areaScale: areaScale, prng: prng,
                              weighted: roster) { elemCG, _, _, type, slotSize, _ in
            drawCell(elemCG, id: type, slotSize: slotSize, config: config, lib: lib)
        }
    }

    private static func drawCell(_ cg: CGContext, id: String, slotSize: Double,
                                 config: RenderConfig, lib: HematopoiesisLibrary) {
        guard let cell = lib.cells[id] else { return }

        // Compress relative-size dynamic range with exponent 0.6 so small
        // cells (RBCs, thrombocytes) aren't dwarfed by megakaryocytes.
        let natMax = max(cell.width, cell.height)
        let rel = pow(natMax / maxNatural, 0.6)
        let drawSize = slotSize * rel
        let drawW = drawSize * (cell.width / natMax)
        let drawH = drawSize * (cell.height / natMax)

        // Alpha slider drives per-cell opacity. Multiplier 2.0 mirrors the
        // HTML's blood-specific sub-layer fix.
        let cellAlpha = min(1.0, config.alpha * 2.0)

        cg.saveGState()
        cg.setAlpha(CGFloat(cellAlpha))
        cg.beginTransparencyLayer(auxiliaryInfo: nil)

        // Center the symbol on the origin, then scale its viewBox to fit drawW × drawH.
        cg.translateBy(x: -drawW / 2, y: -drawH / 2)
        cg.scaleBy(x: drawW / cell.width, y: drawH / cell.height)

        for path in cell.paths {
            cg.saveGState()
            cg.concatenate(path.transform)
            let shifted = ColorMath.paletteShift(
                path.fill,
                hue: config.hue,
                sat: config.saturation,
                light: config.lightness
            )
            cg.setFillColor(shifted.cgColor)
            cg.addPath(path.cgPath)
            cg.fillPath()
            cg.restoreGState()
        }

        cg.endTransparencyLayer()
        cg.restoreGState()
    }
}
