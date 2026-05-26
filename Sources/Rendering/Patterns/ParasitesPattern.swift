import CoreGraphics
import Foundation

/// Parasite colors — Giemsa-style staining, routed through the hue/sat/light
/// shift so the sliders recolor everything coherently.
struct ParasitePalette {
    let rbcFill, rbcOutline, rbcPale: RGBA
    let cytoPale, cytoMid, parasiteCyto, parasiteDark: RGBA
    let chromatinRed, kinetoplast: RGBA
    let eggDark, eggLight, eggPale, embryo: RGBA
    let flagellum, outline: RGBA

    init(config: RenderConfig) {
        func s(_ hex: String) -> RGBA {
            ColorMath.paletteShift(hex, hue: config.hue,
                                   sat: config.saturation, light: config.lightness)
        }
        rbcFill      = s("#e88060")
        rbcOutline   = s("#a04030")
        rbcPale      = s("#f0a890")
        cytoPale     = s("#d4b8e8")
        cytoMid      = s("#a888c8")
        parasiteCyto = s("#9870c0")
        parasiteDark = s("#4a2078")
        chromatinRed = s("#c8203a")
        kinetoplast  = s("#2a1048")
        eggDark      = s("#7a5028")
        eggLight     = s("#c8a070")
        eggPale      = s("#ecd8b0")
        embryo       = s("#a89070")
        flagellum    = s("#7858a8")
        outline      = s("#2a1838")
    }
}

/// Parasites — protozoa & helminth eggs. Procedural port of the HTML reference.
enum ParasitesPattern {

    static let roster: [String] = [
        "plasm_ring", "plasm_ring", "plasm_ring",
        "plasm_schiz",
        "plasm_gam", "plasm_gam",
        "trypanosome", "trypanosome",
        "giardia", "giardia",
        "ent_troph", "ent_troph",
        "ent_cyst",
        "toxoplasma", "toxoplasma",
        "leishmania",
        "ascaris", "ascaris",
        "schistosoma", "schistosoma",
        "trichuris",
        "hookworm",
        "pinworm",
        "troph_cluster",
    ]

    static func draw(in cg: CGContext, size: CGSize, config: RenderConfig,
                     scale: Double, areaScale: Double, prng: PRNG) {
        let pal = ParasitePalette(config: config)
        PlacementEngine.place(in: cg, size: size, config: config,
                              scale: scale, areaScale: areaScale, prng: prng,
                              weighted: roster) { elemCG, _, _, type, elemSize, prng in
            drawCell(elemCG, type: type, size: elemSize, config: config, pal: pal, prng: prng)
        }
    }

    private static func drawCell(_ cg: CGContext, type: String, size: Double,
                                 config: RenderConfig, pal: ParasitePalette, prng: PRNG) {
        let sw = max(1.0, size / 110)
        let seed = prng.next()
        let cellAlpha = min(1.0, config.alpha * 2.8)

        cg.saveGState()
        cg.setAlpha(CGFloat(cellAlpha))
        cg.beginTransparencyLayer(auxiliaryInfo: nil)
        drawByType(cg, type: type, size: size, sw: sw, seed: seed, prng: prng, pal: pal)
        cg.endTransparencyLayer()
        cg.restoreGState()
    }

    private static func drawByType(_ cg: CGContext, type: String, size: Double,
                                   sw: Double, seed: Double, prng: PRNG,
                                   pal: ParasitePalette) {
        switch type {
        case "plasm_ring":    plasmodiumRing(cg, size, sw, seed, prng, pal)
        case "plasm_schiz":   plasmodiumSchizont(cg, size, sw, seed, prng, pal)
        case "plasm_gam":     plasmodiumGametocyte(cg, size, sw, seed, prng, pal)
        case "trypanosome":   trypanosome(cg, size, sw, seed, prng, pal)
        case "giardia":       giardia(cg, size, sw, seed, prng, pal)
        case "ent_troph":     entamoebaTroph(cg, size, sw, seed, prng, pal)
        case "ent_cyst":      entamoebaCyst(cg, size, sw, seed, prng, pal)
        case "toxoplasma":    toxoplasma(cg, size, sw, seed, prng, pal)
        case "leishmania":    leishmania(cg, size, sw, seed, prng, pal)
        case "ascaris":       ascarisEgg(cg, size, sw, seed, prng, pal)
        case "schistosoma":   schistosomaEgg(cg, size, sw, seed, prng, pal)
        case "trichuris":     trichurisEgg(cg, size, sw, seed, prng, pal)
        case "hookworm":      hookwormEgg(cg, size, sw, seed, prng, pal)
        case "pinworm":       pinwormEgg(cg, size, sw, seed, prng, pal)
        case "troph_cluster": trophCluster(cg, size, sw, seed, prng, pal)
        default: break
        }
    }

    // MARK: - Shape helpers

    private static func ellipse(_ cg: CGContext, _ cx: Double, _ cy: Double,
                                _ rx: Double, _ ry: Double,
                                fill: RGBA? = nil, stroke: RGBA? = nil,
                                lineWidth: Double = 1, dash: [CGFloat]? = nil) {
        cg.saveGState()
        if let dash { cg.setLineDash(phase: 0, lengths: dash) }
        cg.addEllipse(in: CGRect(x: cx - rx, y: cy - ry, width: 2 * rx, height: 2 * ry))
        paint(cg, fill: fill, stroke: stroke, lineWidth: lineWidth)
        cg.restoreGState()
    }

    private static func path(_ cg: CGContext, _ p: CGPath,
                             fill: RGBA? = nil, stroke: RGBA? = nil,
                             lineWidth: Double = 1, lineJoin: CGLineJoin = .round,
                             lineCap: CGLineCap = .butt) {
        cg.saveGState()
        cg.setLineJoin(lineJoin)
        cg.setLineCap(lineCap)
        cg.addPath(p)
        paint(cg, fill: fill, stroke: stroke, lineWidth: lineWidth)
        cg.restoreGState()
    }

    private static func paint(_ cg: CGContext, fill: RGBA?, stroke: RGBA?, lineWidth: Double) {
        if let fill, let stroke {
            cg.setFillColor(fill.cgColor)
            cg.setStrokeColor(stroke.cgColor)
            cg.setLineWidth(CGFloat(lineWidth))
            cg.drawPath(using: .fillStroke)
        } else if let fill {
            cg.setFillColor(fill.cgColor)
            cg.fillPath()
        } else if let stroke {
            cg.setStrokeColor(stroke.cgColor)
            cg.setLineWidth(CGFloat(lineWidth))
            cg.strokePath()
        }
    }

    private static func rbc(_ cg: CGContext, _ r: Double, _ sw: Double, _ pal: ParasitePalette) {
        ellipse(cg, 0, 0, r, r, fill: pal.rbcFill, stroke: pal.rbcOutline, lineWidth: sw)
        ellipse(cg, 0, 0, r * 0.42, r * 0.42, fill: pal.rbcPale.withAlpha(0.55))
    }

    // MARK: - Protozoa

    private static func plasmodiumRing(_ cg: CGContext, _ size: Double, _ sw: Double,
                                       _ seed: Double, _ prng: PRNG, _ pal: ParasitePalette) {
        let r = size * 0.42
        rbc(cg, r, sw, pal)
        let offX = r * 0.2 * (prng.random(seed) - 0.5)
        let offY = r * 0.2 * (prng.random(seed + 0.13) - 0.5)
        let ringR = r * 0.27
        ellipse(cg, offX, offY, ringR, ringR, stroke: pal.parasiteCyto, lineWidth: sw * 1.6)
        let dotAng = prng.random(seed + 0.27) * 2 * .pi
        ellipse(cg, offX + ringR * cos(dotAng), offY + ringR * sin(dotAng),
                sw * 1.6, sw * 1.6, fill: pal.chromatinRed)
    }

    private static func plasmodiumSchizont(_ cg: CGContext, _ size: Double, _ sw: Double,
                                           _ seed: Double, _ prng: PRNG, _ pal: ParasitePalette) {
        let r = size * 0.42
        rbc(cg, r, sw, pal)
        let numMero = 12 + Int(prng.random(seed) * 5)
        for i in 0..<numMero {
            let fi = Double(i)
            let a = prng.random(seed + fi * 0.13) * 2 * .pi
            let d = sqrt(prng.random(seed + fi * 0.17)) * r * 0.6
            ellipse(cg, d * cos(a), d * sin(a), sw * 1.4, sw * 1.4, fill: pal.parasiteDark)
        }
    }

    private static func plasmodiumGametocyte(_ cg: CGContext, _ size: Double, _ sw: Double,
                                             _ seed: Double, _ prng: PRNG, _ pal: ParasitePalette) {
        let r = size * 0.42
        ellipse(cg, 0, 0, r * 1.1, r * 0.78, fill: pal.rbcFill, stroke: pal.rbcOutline, lineWidth: sw)
        let len = r * 1.6
        let banana = CGMutablePath()
        banana.move(to: CGPoint(x: -len / 2, y: 0))
        banana.addQuadCurve(to: CGPoint(x: len / 2, y: 0), control: CGPoint(x: 0, y: -r * 0.55))
        banana.addQuadCurve(to: CGPoint(x: -len / 2, y: 0), control: CGPoint(x: 0, y: r * 0.25))
        banana.closeSubpath()
        path(cg, banana, fill: pal.parasiteCyto, stroke: pal.parasiteDark, lineWidth: sw * 0.7)
        ellipse(cg, 0, -r * 0.05, sw * 2.2, sw * 2.2, fill: pal.parasiteDark)
    }

    private static func trypanosome(_ cg: CGContext, _ size: Double, _ sw: Double,
                                    _ seed: Double, _ prng: PRNG, _ pal: ParasitePalette) {
        let len = size * 0.9
        let width = size * 0.13
        let body = CGMutablePath()
        body.move(to: CGPoint(x: -len / 2, y: 0))
        body.addCurve(to: CGPoint(x: len * 0.18, y: 0),
                      control1: CGPoint(x: -len * 0.28, y: -width * 1.3),
                      control2: CGPoint(x: -len * 0.05, y: width * 1.3))
        body.addCurve(to: CGPoint(x: len * 0.5, y: 0),
                      control1: CGPoint(x: len * 0.32, y: -width * 0.9),
                      control2: CGPoint(x: len * 0.45, y: width * 0.3))
        path(cg, body, stroke: pal.parasiteCyto, lineWidth: width, lineCap: .round)
        path(cg, body, stroke: pal.parasiteDark.withAlpha(0.6), lineWidth: sw * 0.5, lineCap: .round)
        ellipse(cg, -len * 0.05, 0, width * 0.52, width * 0.52, fill: pal.parasiteDark)
        ellipse(cg, len * 0.28, 0, width * 0.3, width * 0.3, fill: pal.kinetoplast)
        let flag = CGMutablePath()
        flag.move(to: CGPoint(x: len / 2, y: 0))
        flag.addCurve(to: CGPoint(x: len * 0.88, y: -width * 0.4),
                      control1: CGPoint(x: len * 0.6, y: -width * 1.5),
                      control2: CGPoint(x: len * 0.7, y: width * 1.2))
        path(cg, flag, stroke: pal.flagellum, lineWidth: sw * 0.9, lineCap: .round)
    }

    private static func giardia(_ cg: CGContext, _ size: Double, _ sw: Double,
                                _ seed: Double, _ prng: PRNG, _ pal: ParasitePalette) {
        let w = size * 0.5, h = size * 0.7
        let body = CGMutablePath()
        body.move(to: CGPoint(x: 0, y: -h / 2))
        body.addQuadCurve(to: CGPoint(x: w / 2, y: h * 0.1), control: CGPoint(x: w / 2, y: -h * 0.35))
        body.addQuadCurve(to: CGPoint(x: 0, y: h / 2), control: CGPoint(x: w / 2, y: h / 2))
        body.addQuadCurve(to: CGPoint(x: -w / 2, y: h * 0.1), control: CGPoint(x: -w / 2, y: h / 2))
        body.addQuadCurve(to: CGPoint(x: 0, y: -h / 2), control: CGPoint(x: -w / 2, y: -h * 0.35))
        body.closeSubpath()
        path(cg, body, fill: pal.cytoPale, stroke: pal.parasiteDark, lineWidth: sw)
        for side in [-1.0, 1.0] {
            ellipse(cg, side * w * 0.18, -h * 0.15, w * 0.14, w * 0.14,
                    fill: pal.parasiteCyto, stroke: pal.parasiteDark, lineWidth: sw * 0.5)
            ellipse(cg, side * w * 0.18, -h * 0.15, w * 0.045, w * 0.045, fill: pal.parasiteDark)
        }
        for side in [-1.0, 1.0] {
            let mb = CGPath(roundedRect: CGRect(x: side * w * 0.04 - w * 0.05, y: h * 0.08,
                                                width: w * 0.1, height: h * 0.08),
                            cornerWidth: w * 0.03, cornerHeight: w * 0.03, transform: nil)
            path(cg, mb, fill: pal.parasiteDark.withAlpha(0.65))
        }
        let flagPairs: [(Double, Double, Double, Double)] = [
            (-w*0.28, -h*0.22, -w*0.55, -h*0.48), (w*0.28, -h*0.22, w*0.55, -h*0.48),
            (-w*0.22,  h*0.28, -w*0.42,  h*0.55), (w*0.22,  h*0.28, w*0.42,  h*0.55),
            (-w*0.08,  h*0.48, -w*0.18,  h*0.7),  (w*0.08,  h*0.48, w*0.18,  h*0.7),
        ]
        cg.saveGState()
        cg.setStrokeColor(pal.flagellum.cgColor)
        cg.setLineWidth(CGFloat(sw * 0.6))
        cg.setLineCap(.round)
        for (x1, y1, x2, y2) in flagPairs {
            cg.move(to: CGPoint(x: x1, y: y1))
            cg.addLine(to: CGPoint(x: x2, y: y2))
            cg.strokePath()
        }
        cg.restoreGState()
    }

    private static func entamoebaTroph(_ cg: CGContext, _ size: Double, _ sw: Double,
                                       _ seed: Double, _ prng: PRNG, _ pal: ParasitePalette) {
        let r = size * 0.38
        let n = 9
        var pts: [(Double, Double)] = []
        for i in 0..<n {
            let a = (Double(i) / Double(n)) * 2 * .pi
            let radius = r * (0.72 + prng.random(seed + Double(i) * 0.13) * 0.45)
            pts.append((radius * cos(a), radius * sin(a)))
        }
        let blob = CGMutablePath()
        blob.move(to: CGPoint(x: (pts[0].0 + pts[1].0) / 2, y: (pts[0].1 + pts[1].1) / 2))
        for i in 0..<n {
            let cur = pts[(i + 1) % n]
            let nxt = pts[(i + 2) % n]
            blob.addQuadCurve(to: CGPoint(x: (cur.0 + nxt.0) / 2, y: (cur.1 + nxt.1) / 2),
                              control: CGPoint(x: cur.0, y: cur.1))
        }
        blob.closeSubpath()
        path(cg, blob, fill: pal.cytoMid, stroke: pal.parasiteDark, lineWidth: sw)
        let nx = r * 0.15 * (prng.random(seed + 0.4) - 0.5)
        let ny = r * 0.15 * (prng.random(seed + 0.5) - 0.5)
        ellipse(cg, nx, ny, r * 0.28, r * 0.28,
                fill: pal.cytoPale, stroke: pal.parasiteDark, lineWidth: sw * 0.5)
        ellipse(cg, nx, ny, r * 0.07, r * 0.07, fill: pal.parasiteDark)
    }

    private static func entamoebaCyst(_ cg: CGContext, _ size: Double, _ sw: Double,
                                      _ seed: Double, _ prng: PRNG, _ pal: ParasitePalette) {
        let r = size * 0.4
        ellipse(cg, 0, 0, r, r, fill: pal.cytoPale, stroke: pal.parasiteDark, lineWidth: sw * 1.2)
        let positions: [(Double, Double)] = [
            (-r*0.42, -r*0.28), (r*0.42, -r*0.28),
            (-r*0.28,  r*0.42), (r*0.28,  r*0.42),
        ]
        for (x, y) in positions {
            ellipse(cg, x, y, r * 0.13, r * 0.13,
                    fill: pal.parasiteCyto, stroke: pal.parasiteDark, lineWidth: sw * 0.4)
            ellipse(cg, x, y, r * 0.04, r * 0.04, fill: pal.parasiteDark)
        }
        for i in 0..<2 {
            let ang = i == 0 ? Double.pi * 0.25 : Double.pi * 1.25
            let dist = r * 0.05
            cg.saveGState()
            cg.translateBy(x: dist * cos(ang), y: dist * sin(ang))
            cg.rotate(by: ang)
            let bar = CGPath(roundedRect: CGRect(x: -r * 0.18, y: -r * 0.05,
                                                 width: r * 0.36, height: r * 0.10),
                             cornerWidth: r * 0.05, cornerHeight: r * 0.05, transform: nil)
            path(cg, bar, fill: pal.parasiteDark.withAlpha(0.7))
            cg.restoreGState()
        }
    }

    private static func toxoplasma(_ cg: CGContext, _ size: Double, _ sw: Double,
                                   _ seed: Double, _ prng: PRNG, _ pal: ParasitePalette) {
        let len = size * 0.7, thickness = size * 0.16
        let banana = CGMutablePath()
        banana.move(to: CGPoint(x: -len / 2, y: 0))
        banana.addQuadCurve(to: CGPoint(x: len / 2, y: 0), control: CGPoint(x: 0, y: -len * 0.35))
        banana.addQuadCurve(to: CGPoint(x: -len / 2, y: 0), control: CGPoint(x: 0, y: thickness))
        banana.closeSubpath()
        path(cg, banana, fill: pal.parasiteCyto, stroke: pal.parasiteDark, lineWidth: sw)
        ellipse(cg, len * 0.1, -thickness * 0.05, thickness * 0.55, thickness * 0.55,
                fill: pal.parasiteDark)
    }

    private static func leishmania(_ cg: CGContext, _ size: Double, _ sw: Double,
                                   _ seed: Double, _ prng: PRNG, _ pal: ParasitePalette) {
        let w = size * 0.3, h = size * 0.5
        ellipse(cg, 0, 0, w / 2, h / 2, fill: pal.cytoPale, stroke: pal.parasiteDark, lineWidth: sw)
        ellipse(cg, 0, -h * 0.15, w * 0.32, w * 0.32, fill: pal.parasiteDark)
        let kin = CGPath(roundedRect: CGRect(x: -w * 0.22, y: h * 0.13,
                                             width: w * 0.44, height: w * 0.1),
                         cornerWidth: w * 0.05, cornerHeight: w * 0.05, transform: nil)
        path(cg, kin, fill: pal.kinetoplast)
    }

    // MARK: - Helminth eggs

    private static func ascarisEgg(_ cg: CGContext, _ size: Double, _ sw: Double,
                                   _ seed: Double, _ prng: PRNG, _ pal: ParasitePalette) {
        let w = size * 0.5, h = size * 0.62
        let numBumps = 18
        let outer = CGMutablePath()
        for i in 0...numBumps {
            let t = Double(i) / Double(numBumps)
            let a = t * 2 * .pi
            let bump = 1.0 + cos(a * 6) * 0.06
            let pt = CGPoint(x: w / 2 * bump * cos(a), y: h / 2 * bump * sin(a))
            if i == 0 { outer.move(to: pt) } else { outer.addLine(to: pt) }
        }
        outer.closeSubpath()
        path(cg, outer, fill: pal.eggDark, stroke: pal.outline, lineWidth: sw * 0.8)
        ellipse(cg, 0, 0, w * 0.38, h * 0.42, fill: pal.eggPale, stroke: pal.outline, lineWidth: sw * 0.4)
        ellipse(cg, 0, 0, w * 0.24, h * 0.28, fill: pal.embryo.withAlpha(0.85))
    }

    private static func schistosomaEgg(_ cg: CGContext, _ size: Double, _ sw: Double,
                                       _ seed: Double, _ prng: PRNG, _ pal: ParasitePalette) {
        let w = size * 0.55, h = size * 0.34
        ellipse(cg, 0, 0, w / 2, h / 2, fill: pal.eggLight, stroke: pal.outline, lineWidth: sw)
        let sx = w * 0.42, sy = -h * 0.05
        let spine = CGMutablePath()
        spine.move(to: CGPoint(x: sx, y: sy))
        spine.addLine(to: CGPoint(x: sx + w * 0.22, y: sy + h * 0.05))
        spine.addLine(to: CGPoint(x: sx, y: sy + h * 0.2))
        spine.closeSubpath()
        path(cg, spine, fill: pal.eggLight, stroke: pal.outline, lineWidth: sw)
        ellipse(cg, 0, 0, w * 0.28, h * 0.32, fill: pal.embryo.withAlpha(0.75))
    }

    private static func trichurisEgg(_ cg: CGContext, _ size: Double, _ sw: Double,
                                     _ seed: Double, _ prng: PRNG, _ pal: ParasitePalette) {
        let w = size * 0.32, h = size * 0.58
        ellipse(cg, 0, 0, w / 2, h / 2, fill: pal.eggDark, stroke: pal.outline, lineWidth: sw)
        for side in [-1.0, 1.0] {
            ellipse(cg, 0, side * h * 0.42, w * 0.22, h * 0.11,
                    fill: pal.eggPale, stroke: pal.outline, lineWidth: sw * 0.6)
        }
    }

    private static func hookwormEgg(_ cg: CGContext, _ size: Double, _ sw: Double,
                                    _ seed: Double, _ prng: PRNG, _ pal: ParasitePalette) {
        let w = size * 0.5, h = size * 0.3
        ellipse(cg, 0, 0, w / 2, h / 2, fill: pal.eggPale, stroke: pal.outline, lineWidth: sw * 0.8)
        let positions: [(Double, Double)] = [
            (-w*0.18, -h*0.12), (w*0.18, -h*0.12),
            (-w*0.18,  h*0.12), (w*0.18,  h*0.12),
            (0, -h*0.05), (0, h*0.05), (-w*0.3, 0), (w*0.3, 0),
        ]
        for (x, y) in positions {
            ellipse(cg, x, y, w * 0.085, w * 0.085,
                    fill: pal.embryo, stroke: pal.outline, lineWidth: sw * 0.3)
        }
    }

    private static func pinwormEgg(_ cg: CGContext, _ size: Double, _ sw: Double,
                                   _ seed: Double, _ prng: PRNG, _ pal: ParasitePalette) {
        let w = size * 0.32, h = size * 0.5
        let egg = CGMutablePath()
        egg.move(to: CGPoint(x: -w * 0.3, y: -h / 2))
        egg.addQuadCurve(to: CGPoint(x: w / 2, y: 0), control: CGPoint(x: w / 2, y: -h / 2))
        egg.addQuadCurve(to: CGPoint(x: -w * 0.3, y: h / 2), control: CGPoint(x: w / 2, y: h / 2))
        egg.addLine(to: CGPoint(x: -w * 0.3, y: -h / 2))
        egg.closeSubpath()
        path(cg, egg, fill: pal.eggLight, stroke: pal.outline, lineWidth: sw)
        let larva = CGMutablePath()
        larva.move(to: CGPoint(x: -w * 0.1, y: -h * 0.3))
        larva.addQuadCurve(to: CGPoint(x: w * 0.15, y: 0), control: CGPoint(x: w * 0.2, y: -h * 0.2))
        larva.addQuadCurve(to: CGPoint(x: -w * 0.1, y: h * 0.3), control: CGPoint(x: w * 0.1, y: h * 0.2))
        path(cg, larva, stroke: pal.embryo, lineWidth: w * 0.18, lineCap: .round)
    }

    private static func trophCluster(_ cg: CGContext, _ size: Double, _ sw: Double,
                                     _ seed: Double, _ prng: PRNG, _ pal: ParasitePalette) {
        for i in 0..<4 {
            let fi = Double(i)
            let a = prng.random(seed + fi * 0.17) * 2 * .pi
            let d = sqrt(prng.random(seed + fi * 0.23)) * size * 0.32
            let pick = Int(prng.random(seed + fi * 0.31) * 3)
            let subSize = size * 0.4
            let subSw = max(0.7, subSize / 110)
            cg.saveGState()
            cg.translateBy(x: d * cos(a), y: d * sin(a))
            cg.rotate(by: prng.random(seed + fi * 0.37) * 360 * .pi / 180)
            switch pick {
            case 0:  leishmania(cg, subSize, subSw, seed + fi, prng, pal)
            case 1:  toxoplasma(cg, subSize, subSw, seed + fi, prng, pal)
            default: entamoebaTroph(cg, subSize, subSw, seed + fi, prng, pal)
            }
            cg.restoreGState()
        }
    }
}
