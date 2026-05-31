import CoreGraphics
import Foundation

/// Top-level renderer. Fills the background, then dispatches to the pattern.
/// The SAME function powers both the live Canvas preview and the full-resolution
/// PNG export — preview passes a small size, export passes the target size.
///
/// As each pattern is ported from the HTML reference, add its `case` below.
enum WallpaperRenderer {
    static func draw(in cg: CGContext, size: CGSize, config: RenderConfig) {
        // --- Background fill -------------------------------------------------
        let bg = config.background.baseRGB
            .lightnessShifted(config.backgroundLightness / 100)
        cg.setFillColor(bg.cgColor)
        cg.fill(CGRect(origin: .zero, size: size))

        // --- Scale factors --------------------------------------------------
        // Mirrors render() in the HTML reference.
        //   scale     — from the ACTUAL render size, so element sizes/spacing
        //               stay proportional whether previewing small or
        //               exporting huge (it self-corrects across resolutions).
        //   areaScale — anchored to a CANONICAL reference area so element
        //               COUNT is independent of the aspect. Earlier versions
        //               used the aspect's logical area, which made non-square
        //               aspects (iPhone/iPad/Mac) sparse because their logical
        //               areas are 5–10× smaller than the Square presets even
        //               though the user expects "density 1.0" to look the same
        //               across aspects. Element SIZE still scales with the
        //               actual render via `scale`, so preview ↔ export parity
        //               at a given aspect is preserved.
        let refArea = 2880.0 * 1864.0
        let canvasArea = Double(size.width) * Double(size.height)
        let canonicalLogicalArea = 6000.0 * 6000.0   // Square 6K — base tuning
        let scale = (sqrt(canvasArea) / sqrt(refArea)) * config.elementScale
        let areaScale = canonicalLogicalArea / refArea
            / (config.elementScale * config.elementScale)

        // Fresh PRNG per render — counter starts at 0, like resetSeedCounter().
        let prng = PRNG(seed: config.seed)

        // --- Pattern dispatch -----------------------------------------------
        switch config.pattern {
        case .mitosis:
            MitosisPattern.draw(in: cg, size: size, config: config,
                                scale: scale, areaScale: areaScale, prng: prng)
        case .blood:
            BloodPattern.draw(in: cg, size: size, config: config,
                              scale: scale, areaScale: areaScale, prng: prng)
        case .parasites:
            ParasitesPattern.draw(in: cg, size: size, config: config,
                                  scale: scale, areaScale: areaScale, prng: prng)
        case .bacteria:
            BacteriaPattern.draw(in: cg, size: size, config: config,
                                 scale: scale, areaScale: areaScale, prng: prng)
        case .bohr:
            BohrPattern.draw(in: cg, size: size, config: config,
                             scale: scale, areaScale: areaScale, prng: prng)
        case .feynman:
            FeynmanPattern.draw(in: cg, size: size, config: config,
                                scale: scale, areaScale: areaScale, prng: prng)
        case .molecules:
            MoleculesPattern.draw(in: cg, size: size, config: config,
                                  scale: scale, areaScale: areaScale, prng: prng)
        case .organellesTextbook:
            OrganellesTextbookPattern.draw(in: cg, size: size, config: config,
                                           scale: scale, areaScale: areaScale, prng: prng)
        case .organellesSketch:
            OrganellesSketchPattern.draw(in: cg, size: size, config: config,
                                         scale: scale, areaScale: areaScale, prng: prng)
        case .fields:
            FieldsPattern.draw(in: cg, size: size, config: config,
                               scale: scale, areaScale: areaScale, prng: prng)
        case .viruses:
            VirusesPattern.draw(in: cg, size: size, config: config,
                                scale: scale, areaScale: areaScale, prng: prng)
        case .orbitals:
            OrbitalsHybridPattern.draw(in: cg, size: size, config: config,
                                       scale: scale, areaScale: areaScale, prng: prng)
        case .orbitalsSchematic:
            OrbitalsSchematicPattern.draw(in: cg, size: size, config: config,
                                          scale: scale, areaScale: areaScale, prng: prng)
        default:
            PlaceholderPattern.draw(in: cg, size: size, config: config)
        }
    }
}
