import CoreGraphics
import Foundation

/// Mitosis stage colors — classic textbook palette, routed through the
/// hue/sat/light shift so the sliders recolor everything coherently.
struct MitosisPalette {
    let membrane, cytoplasm, envelope, nucFill: RGBA
    let chromatin, chromatinLt, microtubule, centrosome, nucleolus: RGBA

    init(config: RenderConfig) {
        func s(_ hex: String) -> RGBA {
            ColorMath.paletteShift(hex, hue: config.hue,
                                   sat: config.saturation, light: config.lightness)
        }
        membrane    = s("#7a5f9c")
        cytoplasm   = s("#ab92bf")
        envelope    = s("#5f4585")
        nucFill     = s("#9379ab")
        chromatin   = s("#3d1f70")
        chromatinLt = s("#6a3f9a")
        microtubule = s("#88d0d8")
        centrosome  = s("#f0c050")
        nucleolus   = s("#5a2890")
    }
}

/// Mitosis — cell-division stages. Procedural port of the HTML reference.
/// Every element is drawn centered at the origin; the placement engine handles
/// position, rotation and depth.
enum MitosisPattern {

    static let roster: [String] = [
        "interphase", "interphase",
        "prophase", "prophase",
        "prometaphase",
        "metaphase", "metaphase", "metaphase",
        "anaphase", "anaphase",
        "telophase", "telophase",
        "cytokinesis", "cytokinesis",
        "loose_chrom", "loose_chrom", "loose_chrom", "loose_chrom",
        "centrosomes",
    ]

    static func draw(in cg: CGContext, size: CGSize, config: RenderConfig,
                     scale: Double, areaScale: Double, prng: PRNG) {
        let pal = MitosisPalette(config: config)
        PlacementEngine.place(in: cg, size: size, config: config,
                              scale: scale, areaScale: areaScale, prng: prng,
                              weighted: roster) { elemCG, _, _, type, elemSize, prng in
            drawCell(elemCG, type: type, size: elemSize, config: config, pal: pal, prng: prng)
        }
    }

    /// Draws one mitosis cell, composited at the cell-opacity derived from the
    /// alpha slider (mirrors makeMitosisCell's group opacity).
    private static func drawCell(_ cg: CGContext, type: String, size: Double,
                                 config: RenderConfig, pal: MitosisPalette, prng: PRNG) {
        let sw = max(1.0, size / 110)
        let seed = prng.next()
        let cellAlpha = min(1.0, config.alpha * 2.8)

        cg.saveGState()
        cg.setAlpha(CGFloat(cellAlpha))
        cg.beginTransparencyLayer(auxiliaryInfo: nil)
        switch type {
        case "interphase":   interphase(cg, size, sw, seed, prng, pal)
        case "prophase":     prophase(cg, size, sw, seed, prng, pal)
        case "prometaphase": prometaphase(cg, size, sw, seed, prng, pal)
        case "metaphase":    metaphase(cg, size, sw, seed, prng, pal)
        case "anaphase":     anaphase(cg, size, sw, seed, prng, pal)
        case "telophase":    telophase(cg, size, sw, seed, prng, pal)
        case "cytokinesis":  cytokinesis(cg, size, sw, seed, prng, pal)
        case "loose_chrom":  looseChromosome(cg, size, sw, seed, prng, pal)
        case "centrosomes":  centrosomePair(cg, size, sw, seed, prng, pal)
        default: break
        }
        cg.endTransparencyLayer()
        cg.restoreGState()
    }

    // MARK: - Shape helpers

    private static func filledCircle(_ cg: CGContext, _ cx: Double, _ cy: Double,
                                     _ r: Double, fill: RGBA) {
        cg.setFillColor(fill.cgColor)
        cg.fillEllipse(in: CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r))
    }

    private static func strokedCircle(_ cg: CGContext, _ cx: Double, _ cy: Double,
                                      _ r: Double, fill: RGBA, stroke: RGBA,
                                      lineWidth: Double, dash: [CGFloat]? = nil) {
        cg.saveGState()
        cg.setFillColor(fill.cgColor)
        cg.setStrokeColor(stroke.cgColor)
        cg.setLineWidth(CGFloat(lineWidth))
        if let dash { cg.setLineDash(phase: 0, lengths: dash) }
        cg.addEllipse(in: CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r))
        cg.drawPath(using: .fillStroke)
        cg.restoreGState()
    }

    private static func cellMembrane(_ cg: CGContext, _ r: Double, _ sw: Double,
                                     _ pal: MitosisPalette) {
        strokedCircle(cg, 0, 0, r, fill: pal.cytoplasm, stroke: pal.membrane, lineWidth: sw)
    }

    private static func nuclearEnvelope(_ cg: CGContext, _ r: Double, _ sw: Double,
                                        _ pal: MitosisPalette, dashed: Bool = false) {
        let dash: [CGFloat]? = dashed ? [CGFloat(sw * 2.5), CGFloat(sw * 4)] : nil
        strokedCircle(cg, 0, 0, r, fill: pal.nucFill, stroke: pal.envelope,
                      lineWidth: sw * 1.1, dash: dash)
    }

    private static func chromatinSpecks(_ cg: CGContext, _ r: Double, _ count: Int,
                                        _ sw: Double, _ seed: Double, _ prng: PRNG,
                                        color: RGBA) {
        for i in 0..<count {
            let fi = Double(i)
            let ang = prng.random(seed + fi * 0.13) * 2 * .pi
            let dist = sqrt(prng.random(seed + fi * 0.31)) * r * 0.88
            let dotR = sw * (0.5 + prng.random(seed + fi * 0.19) * 0.6)
            let op = 0.55 + prng.random(seed + fi * 0.41) * 0.35
            filledCircle(cg, dist * cos(ang), dist * sin(ang), dotR,
                         fill: color.withAlpha(op))
        }
    }

    private static func centrosome(_ cg: CGContext, _ cx: Double, _ cy: Double,
                                   _ size: Double, color: RGBA) {
        filledCircle(cg, cx, cy, size * 1.5, fill: color.withAlpha(0.28))
        filledCircle(cg, cx, cy, size * 0.55, fill: color)
    }

    private static func chromosome(_ cg: CGContext, _ cx: Double, _ cy: Double,
                                   _ length: Double, color: RGBA, rotation: Double,
                                   _ seed: Double, _ prng: PRNG, _ pal: MitosisPalette) {
        cg.saveGState()
        cg.translateBy(x: cx, y: cy)
        cg.rotate(by: rotation * .pi / 180)
        let armW = length * 0.24
        let splay = 7 + prng.random(seed) * 5
        for s in [-1.0, 1.0] {
            cg.saveGState()
            cg.rotate(by: s * splay * .pi / 180)
            let rect = CGRect(x: -armW / 2, y: -length / 2, width: armW, height: length)
            let path = CGPath(roundedRect: rect, cornerWidth: armW / 2,
                              cornerHeight: armW / 2, transform: nil)
            cg.setFillColor(color.cgColor)
            cg.addPath(path)
            cg.fillPath()
            cg.restoreGState()
        }
        filledCircle(cg, 0, 0, armW * 0.45, fill: pal.chromatinLt.withAlpha(0.85))
        cg.restoreGState()
    }

    private static func chromatidV(_ cg: CGContext, _ cx: Double, _ cy: Double,
                                   _ size: Double, direction: Double, color: RGBA) {
        let apexX = cx + direction * size * 0.55
        cg.saveGState()
        cg.setStrokeColor(color.cgColor)
        cg.setLineWidth(CGFloat(size * 0.32))
        cg.setLineCap(.round)
        for ang in [22.0, -22.0] {
            let dx = -direction * cos(ang * .pi / 180) * size * 1.1
            let dy = sin(ang * .pi / 180) * size * 1.1
            cg.move(to: CGPoint(x: apexX, y: cy))
            cg.addLine(to: CGPoint(x: apexX + dx, y: cy + dy))
            cg.strokePath()
        }
        cg.restoreGState()
    }

    private static func spindleRays(_ cg: CGContext, _ ox: Double, _ oy: Double,
                                    _ tx: Double, _ ty: Double, spread: Double,
                                    count: Int, length: Double, sw: Double, color: RGBA) {
        let baseAng = atan2(ty - oy, tx - ox)
        cg.saveGState()
        cg.setStrokeColor(color.withAlpha(0.55).cgColor)
        cg.setLineWidth(CGFloat(sw))
        cg.setLineCap(.round)
        for i in 0..<count {
            let t = count == 1 ? 0.5 : Double(i) / Double(count - 1)
            let ang = baseAng - spread / 2 + t * spread
            cg.move(to: CGPoint(x: ox, y: oy))
            cg.addLine(to: CGPoint(x: ox + length * cos(ang), y: oy + length * sin(ang)))
            cg.strokePath()
        }
        cg.restoreGState()
    }

    // MARK: - Stage drawings

    private static func interphase(_ cg: CGContext, _ size: Double, _ sw: Double,
                                   _ seed: Double, _ prng: PRNG, _ pal: MitosisPalette) {
        let r = size * 0.42
        cellMembrane(cg, r, sw, pal)
        let nucR = r * 0.58
        nuclearEnvelope(cg, nucR, sw, pal)
        chromatinSpecks(cg, nucR, 30, sw, seed, prng, color: pal.chromatin)
        let numNucleoli = 1 + Int(prng.random(seed + 0.7))
        for i in 0..<numNucleoli {
            let fi = Double(i)
            let a = prng.random(seed + 0.2 + fi * 0.5) * 2 * .pi
            let d = prng.random(seed + 0.4 + fi * 0.5) * nucR * 0.45
            let rr = nucR * (0.14 + prng.random(seed + 0.9 + fi * 0.3) * 0.05)
            filledCircle(cg, d * cos(a), d * sin(a), rr, fill: pal.nucleolus.withAlpha(0.85))
        }
    }

    private static func prophase(_ cg: CGContext, _ size: Double, _ sw: Double,
                                 _ seed: Double, _ prng: PRNG, _ pal: MitosisPalette) {
        let r = size * 0.42
        cellMembrane(cg, r, sw, pal)
        let nucR = r * 0.62
        nuclearEnvelope(cg, nucR, sw, pal)
        for i in 0..<6 {
            let fi = Double(i)
            let a = prng.random(seed + fi * 0.13) * 2 * .pi
            let d = prng.random(seed + fi * 0.27) * nucR * 0.6
            chromosome(cg, d * cos(a), d * sin(a), nucR * 0.55, color: pal.chromatin,
                       rotation: prng.random(seed + fi * 0.41) * 360, seed + fi * 0.07, prng, pal)
        }
        centrosome(cg, 0, -r * 0.88, sw * 1.6, color: pal.centrosome)
        centrosome(cg, 0,  r * 0.88, sw * 1.6, color: pal.centrosome)
    }

    private static func prometaphase(_ cg: CGContext, _ size: Double, _ sw: Double,
                                     _ seed: Double, _ prng: PRNG, _ pal: MitosisPalette) {
        let r = size * 0.42
        cellMembrane(cg, r, sw, pal)
        let nucR = r * 0.68
        nuclearEnvelope(cg, nucR, sw, pal, dashed: true)
        for i in 0..<7 {
            let fi = Double(i)
            let a = prng.random(seed + fi * 0.13) * 2 * .pi
            let d = prng.random(seed + fi * 0.27) * r * 0.6
            chromosome(cg, d * cos(a), d * sin(a), r * 0.45, color: pal.chromatin,
                       rotation: prng.random(seed + fi * 0.41) * 360, seed + fi * 0.07, prng, pal)
        }
        centrosome(cg, 0, -r * 0.92, sw * 1.6, color: pal.centrosome)
        centrosome(cg, 0,  r * 0.92, sw * 1.6, color: pal.centrosome)
        spindleRays(cg, 0, -r * 0.92, 0, 0, spread: .pi * 0.6, count: 9,
                    length: r * 1.1, sw: sw * 0.55, color: pal.microtubule)
        spindleRays(cg, 0,  r * 0.92, 0, 0, spread: .pi * 0.6, count: 9,
                    length: r * 1.1, sw: sw * 0.55, color: pal.microtubule)
    }

    private static func metaphase(_ cg: CGContext, _ size: Double, _ sw: Double,
                                  _ seed: Double, _ prng: PRNG, _ pal: MitosisPalette) {
        let r = size * 0.42
        cellMembrane(cg, r, sw, pal)
        centrosome(cg, -r * 0.98, 0, sw * 1.6, color: pal.centrosome)
        centrosome(cg,  r * 0.98, 0, sw * 1.6, color: pal.centrosome)
        spindleRays(cg, -r * 0.98, 0, 0, 0, spread: .pi * 0.32, count: 11,
                    length: r * 1.15, sw: sw * 0.55, color: pal.microtubule)
        spindleRays(cg,  r * 0.98, 0, 0, 0, spread: .pi * 0.32, count: 11,
                    length: r * 1.15, sw: sw * 0.55, color: pal.microtubule)
        let numChrom = 6 + Int(prng.random(seed) * 3)
        let plateH = r * 1.25
        for i in 0..<numChrom {
            let fi = Double(i)
            let t = (fi + 0.5) / Double(numChrom)
            let cy = -plateH / 2 + t * plateH
            let cx = (prng.random(seed + fi * 0.17) - 0.5) * r * 0.12
            let rot = 80 + prng.random(seed + fi * 0.29) * 20
            chromosome(cg, cx, cy, r * 0.4, color: pal.chromatin,
                       rotation: rot, seed + fi * 0.07, prng, pal)
        }
    }

    private static func anaphase(_ cg: CGContext, _ size: Double, _ sw: Double,
                                 _ seed: Double, _ prng: PRNG, _ pal: MitosisPalette) {
        let r = size * 0.42
        cg.saveGState()
        cg.setFillColor(pal.cytoplasm.cgColor)
        cg.setStrokeColor(pal.membrane.cgColor)
        cg.setLineWidth(CGFloat(sw))
        cg.addEllipse(in: CGRect(x: -r * 1.08, y: -r * 0.92,
                                 width: r * 2.16, height: r * 1.84))
        cg.drawPath(using: .fillStroke)
        cg.restoreGState()
        centrosome(cg, -r * 1.02, 0, sw * 1.6, color: pal.centrosome)
        centrosome(cg,  r * 1.02, 0, sw * 1.6, color: pal.centrosome)
        spindleRays(cg, -r * 1.02, 0, 0, 0, spread: .pi * 0.22, count: 8,
                    length: r * 1.25, sw: sw * 0.5, color: pal.microtubule)
        spindleRays(cg,  r * 1.02, 0, 0, 0, spread: .pi * 0.22, count: 8,
                    length: r * 1.25, sw: sw * 0.5, color: pal.microtubule)
        let numChrom = 5 + Int(prng.random(seed) * 3)
        for i in 0..<numChrom {
            let fi = Double(i)
            let t = (fi + 0.5) / Double(numChrom)
            let cy = -r * 0.55 + t * r * 1.1
            chromatidV(cg, -r * 0.55 - prng.random(seed + fi * 0.13) * r * 0.12, cy,
                       r * 0.16, direction: -1, color: pal.chromatin)
            chromatidV(cg,  r * 0.55 + prng.random(seed + fi * 0.17) * r * 0.12, cy,
                       r * 0.16, direction: 1, color: pal.chromatin)
        }
    }

    private static func telophase(_ cg: CGContext, _ size: Double, _ sw: Double,
                                  _ seed: Double, _ prng: PRNG, _ pal: MitosisPalette) {
        let r = size * 0.42
        let w = r * 1.08, h = r * 0.95, pinch = 0.88
        let p = CGMutablePath()
        p.move(to: CGPoint(x: -w, y: 0))
        p.addQuadCurve(to: CGPoint(x: 0, y: -h * pinch), control: CGPoint(x: -w, y: -h))
        p.addQuadCurve(to: CGPoint(x: w, y: 0), control: CGPoint(x: w, y: -h))
        p.addQuadCurve(to: CGPoint(x: 0, y: h * pinch), control: CGPoint(x: w, y: h))
        p.addQuadCurve(to: CGPoint(x: -w, y: 0), control: CGPoint(x: -w, y: h))
        p.closeSubpath()
        cg.saveGState()
        cg.setFillColor(pal.cytoplasm.cgColor)
        cg.setStrokeColor(pal.membrane.cgColor)
        cg.setLineWidth(CGFloat(sw))
        cg.addPath(p)
        cg.drawPath(using: .fillStroke)
        cg.restoreGState()
        for side in [-1.0, 1.0] {
            let nx = side * r * 0.58
            let nucR = r * 0.32
            cg.saveGState()
            cg.translateBy(x: nx, y: 0)
            nuclearEnvelope(cg, nucR, sw, pal, dashed: true)
            chromatinSpecks(cg, nucR, 14, sw, seed + side * 0.5, prng, color: pal.chromatin)
            cg.restoreGState()
        }
    }

    private static func cytokinesis(_ cg: CGContext, _ size: Double, _ sw: Double,
                                    _ seed: Double, _ prng: PRNG, _ pal: MitosisPalette) {
        let r = size * 0.42
        let sep = r * 0.95
        for side in [-1.0, 1.0] {
            let cx = side * sep / 2
            cg.saveGState()
            cg.translateBy(x: cx, y: 0)
            cellMembrane(cg, r * 0.62, sw, pal)
            let nucR = r * 0.34
            nuclearEnvelope(cg, nucR, sw, pal)
            chromatinSpecks(cg, nucR, 14, sw, seed + side * 0.5, prng, color: pal.chromatin)
            cg.restoreGState()
        }
    }

    private static func looseChromosome(_ cg: CGContext, _ size: Double, _ sw: Double,
                                        _ seed: Double, _ prng: PRNG, _ pal: MitosisPalette) {
        chromosome(cg, 0, 0, size * 0.7, color: pal.chromatin,
                   rotation: prng.random(seed) * 180, seed, prng, pal)
    }

    private static func centrosomePair(_ cg: CGContext, _ size: Double, _ sw: Double,
                                       _ seed: Double, _ prng: PRNG, _ pal: MitosisPalette) {
        let r = size * 0.32
        for side in [-1.0, 1.0] {
            let cx = side * r * 0.45
            centrosome(cg, cx, 0, sw * 2.2, color: pal.centrosome)
            let numRays = 11
            cg.saveGState()
            cg.setStrokeColor(pal.microtubule.withAlpha(0.7).cgColor)
            cg.setLineWidth(CGFloat(sw * 0.55))
            cg.setLineCap(.round)
            for i in 0..<numRays {
                let fi = Double(i)
                let ang = (fi / Double(numRays)) * 2 * .pi
                    + prng.random(seed + side * 0.3 + fi * 0.13) * 0.15
                let len = r * (0.7 + prng.random(seed + side * 0.5 + fi * 0.19) * 0.45)
                cg.move(to: CGPoint(x: cx, y: 0))
                cg.addLine(to: CGPoint(x: cx + len * cos(ang), y: len * sin(ang)))
                cg.strokePath()
            }
            cg.restoreGState()
        }
    }
}
