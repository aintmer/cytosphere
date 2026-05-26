import CoreGraphics
import Foundation

/// Cell organelles — textbook style. Each organelle has a fixed palette
/// (fill / line / accent) routed through the same hue/sat/light shift the
/// procedural patterns use, so the sliders recolor everything coherently.
enum OrganellesTextbookPattern {

    // MARK: - Palette

    private struct Swatch { let fill: RGBA; let line: RGBA; let accent: RGBA }

    private static let palette: [String: (fill: String, line: String, accent: String)] = [
        "nucleus":       ("#c47dd0", "#6a2a80", "#3d1858"),
        "mitochondrion": ("#e85a5a", "#9a2020", "#5a1010"),
        "chloroplast":   ("#5cc77a", "#2a7a3d", "#1a4a25"),
        "golgi":         ("#f0a050", "#a05a1a", "#5a3010"),
        "rough_er":      ("#d088c0", "#7a3d70", "#3d1c38"),
        "smooth_er":     ("#e8b878", "#a06a30", "#5a3818"),
        "ribosome":      ("#a070b8", "#5a3878", "#2a1a3d"),
        "lysosome":      ("#f8b4c8", "#a04860", "#5a2030"),
        "vacuole":       ("#8acce8", "#3a7898", "#1a3848"),
        "centrosome":    ("#b8a878", "#7a6838", "#3a3018"),
        "peroxisome":    ("#88c8b8", "#3a8070", "#1c4038"),
        "microtubule":   ("#9890c8", "#4848a0", "#1c1c4a"),
        "flagellum":     ("#d8a0a0", "#884040", "#401818"),
    ]

    private static func swatch(_ key: String, config: RenderConfig) -> Swatch {
        let raw = palette[key]!
        let shift: (String) -> RGBA = {
            ColorMath.paletteShift($0, hue: config.hue,
                                   sat: config.saturation, light: config.lightness)
        }
        return Swatch(fill: shift(raw.fill), line: shift(raw.line), accent: shift(raw.accent))
    }

    // MARK: - Roster

    static let roster: [String] = [
        "nucleus", "nucleus",
        "mitochondrion", "mitochondrion", "mitochondrion",
        "chloroplast", "chloroplast", "chloroplast",
        "golgi", "golgi",
        "rough_er", "rough_er",
        "smooth_er",
        "ribosome", "ribosome",
        "lysosome", "lysosome",
        "vacuole",
        "centrosome",
        "peroxisome", "peroxisome",
        "microtubule",
        "flagellum",
    ]

    static func draw(in cg: CGContext, size: CGSize, config: RenderConfig,
                     scale: Double, areaScale: Double, prng: PRNG) {
        PlacementEngine.place(in: cg, size: size, config: config,
                              scale: scale, areaScale: areaScale, prng: prng,
                              weighted: roster) { elemCG, _, _, type, slotSize, prng in
            drawOrganelle(elemCG, type: type, size: slotSize,
                          config: config, prng: prng)
        }
    }

    private static func drawOrganelle(_ cg: CGContext, type: String, size: Double,
                                      config: RenderConfig, prng: PRNG) {
        let sw = max(1.0, size / 110)
        let seed = prng.next()
        let cellAlpha = min(1.0, config.alpha * 3.0)
        let p = swatch(type, config: config)

        cg.saveGState()
        cg.setAlpha(CGFloat(cellAlpha))
        cg.beginTransparencyLayer(auxiliaryInfo: nil)
        switch type {
        case "nucleus":       nucleus(cg, size, sw, seed, prng, p)
        case "mitochondrion": mitochondrion(cg, size, sw, seed, prng, p)
        case "chloroplast":   chloroplast(cg, size, sw, seed, prng, p)
        case "golgi":         golgi(cg, size, sw, seed, prng, p)
        case "rough_er":      roughER(cg, size, sw, seed, prng, p)
        case "smooth_er":     smoothER(cg, size, sw, seed, prng, p)
        case "ribosome":      ribosome(cg, size, sw, p)
        case "lysosome":      lysosome(cg, size, sw, seed, prng, p)
        case "vacuole":       vacuole(cg, size, sw, p)
        case "centrosome":    centrosome(cg, size, sw, p)
        case "peroxisome":    peroxisome(cg, size, sw, p)
        case "microtubule":   microtubule(cg, size, sw, p)
        case "flagellum":     flagellum(cg, size, sw, p)
        default: break
        }
        cg.endTransparencyLayer()
        cg.restoreGState()
    }

    // MARK: - Shape helpers

    private static func fillStroke(_ cg: CGContext, fill: RGBA, stroke: RGBA,
                                   lineWidth: Double, fillOpacity: Double = 1) {
        cg.setFillColor(fill.withAlpha(fillOpacity).cgColor)
        cg.setStrokeColor(stroke.cgColor)
        cg.setLineWidth(CGFloat(lineWidth))
        cg.drawPath(using: .fillStroke)
    }

    private static let white = RGBA(r: 255, g: 255, b: 255)

    private static func addEllipseRect(_ cg: CGContext, cx: Double, cy: Double,
                                       rx: Double, ry: Double) {
        cg.addEllipse(in: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2))
    }

    // MARK: - Nucleus

    private static func nucleus(_ cg: CGContext, _ size: Double, _ sw: Double,
                                _ seed: Double, _ prng: PRNG, _ p: Swatch) {
        let r = size * 0.42
        // Envelope
        addEllipseRect(cg, cx: 0, cy: 0, rx: r, ry: r)
        fillStroke(cg, fill: p.fill, stroke: p.line, lineWidth: sw * 1.3, fillOpacity: 0.85)
        // White highlight
        cg.setFillColor(white.withAlpha(0.18).cgColor)
        cg.fillEllipse(in: CGRect(x: -r * 0.3 - r * 0.35, y: -r * 0.3 - r * 0.25,
                                  width: r * 0.7, height: r * 0.5))
        // Nucleolus
        addEllipseRect(cg, cx: r * 0.1, cy: r * 0.05, rx: r * 0.32, ry: r * 0.32)
        fillStroke(cg, fill: p.accent, stroke: p.line, lineWidth: sw)
        // Specks
        cg.setFillColor(p.line.withAlpha(0.7).cgColor)
        let specR = sw * 0.9
        for i in 0..<14 {
            let fi = Double(i)
            let ang = prng.random(seed + fi * 0.31) * 2 * .pi
            let dist = (0.45 + prng.random(seed + fi * 0.47) * 0.35) * r
            cg.fillEllipse(in: CGRect(
                x: dist * cos(ang) - specR, y: dist * sin(ang) - specR,
                width: specR * 2, height: specR * 2
            ))
        }
    }

    // MARK: - Mitochondrion

    private static func mitochondrion(_ cg: CGContext, _ size: Double, _ sw: Double,
                                      _ seed: Double, _ prng: PRNG, _ p: Swatch) {
        let L = size * 0.95, W = size * 0.5
        let r = W / 2, bend = size * 0.04
        let x1 = -L / 2 + r, x2 = L / 2 - r
        // Body — pill bent in at the long sides
        let path = CGMutablePath()
        path.move(to: CGPoint(x: x1, y: -r))
        path.addQuadCurve(to: CGPoint(x: x2, y: -r), control: CGPoint(x: 0, y: -r - bend))
        path.addArc(center: CGPoint(x: x2, y: 0), radius: r,
                    startAngle: -.pi / 2, endAngle: .pi / 2, clockwise: false)
        path.addQuadCurve(to: CGPoint(x: x1, y: r), control: CGPoint(x: 0, y: r + bend))
        path.addArc(center: CGPoint(x: x1, y: 0), radius: r,
                    startAngle: .pi / 2, endAngle: -.pi / 2, clockwise: false)
        path.closeSubpath()
        cg.addPath(path)
        cg.setLineJoin(.round)
        fillStroke(cg, fill: p.fill, stroke: p.line, lineWidth: sw * 1.3, fillOpacity: 0.9)

        // White highlight stroke
        let hl = CGMutablePath()
        hl.move(to: CGPoint(x: x1 + r * 0.3, y: -r * 0.6))
        hl.addQuadCurve(to: CGPoint(x: x2 - r * 0.3, y: -r * 0.6),
                        control: CGPoint(x: 0, y: -r - bend * 0.5))
        cg.saveGState()
        cg.setStrokeColor(white.withAlpha(0.25).cgColor)
        cg.setLineWidth(CGFloat(sw * 1.5))
        cg.setLineCap(.round)
        cg.addPath(hl)
        cg.strokePath()
        cg.restoreGState()

        // Cristae loops
        let numLoops = 5
        let loopSpacing = (L * 0.78) / Double(numLoops)
        let loopStartX = -L * 0.39 + loopSpacing / 2
        let loopAmp = r * 0.78
        let loopHalfW = loopSpacing * 0.42
        cg.saveGState()
        cg.setStrokeColor(p.line.cgColor)
        cg.setLineWidth(CGFloat(sw * 0.9))
        cg.setLineCap(.round); cg.setLineJoin(.round)
        for i in 0..<numLoops {
            let cx = loopStartX + Double(i) * loopSpacing
            let q = CGMutablePath()
            q.move(to: CGPoint(x: cx - loopHalfW, y: -r * 0.95))
            q.addQuadCurve(to: CGPoint(x: cx + loopHalfW, y: -r * 0.95),
                           control: CGPoint(x: cx, y: -r * 0.95 + loopAmp))
            cg.addPath(q); cg.strokePath()
            let cxb = cx + loopSpacing * 0.5
            if cxb > -L * 0.42 && cxb < L * 0.42 {
                let qb = CGMutablePath()
                qb.move(to: CGPoint(x: cxb - loopHalfW, y: r * 0.95))
                qb.addQuadCurve(to: CGPoint(x: cxb + loopHalfW, y: r * 0.95),
                                control: CGPoint(x: cxb, y: r * 0.95 - loopAmp))
                cg.addPath(qb); cg.strokePath()
            }
            _ = prng.random(seed + Double(i) * 0.1)  // keep seed advancement parity
        }
        cg.restoreGState()
    }

    // MARK: - Chloroplast

    private static func chloroplast(_ cg: CGContext, _ size: Double, _ sw: Double,
                                    _ seed: Double, _ prng: PRNG, _ p: Swatch) {
        let L = size * 0.9, W = size * 0.55
        addEllipseRect(cg, cx: 0, cy: 0, rx: L / 2, ry: W / 2)
        fillStroke(cg, fill: p.fill, stroke: p.line, lineWidth: sw * 1.3, fillOpacity: 0.9)
        // Highlight
        cg.setFillColor(white.withAlpha(0.22).cgColor)
        cg.fillEllipse(in: CGRect(x: -L * 0.1 - L * 0.3, y: -W * 0.25 - W * 0.15,
                                  width: L * 0.6, height: W * 0.3))
        // Thylakoid stacks
        let numStacks = 3
        var stacks: [(cx: Double, cy: Double)] = []
        for s in 0..<numStacks {
            let t = (Double(s) + 0.5) / Double(numStacks)
            let cx = -L * 0.32 + t * L * 0.64
            let cy = (prng.random(seed + Double(s) * 0.31) - 0.5) * W * 0.25
            stacks.append((cx, cy))
        }
        // Lamellae line through stacks
        if stacks.count >= 2 {
            cg.saveGState()
            cg.setStrokeColor(p.accent.withAlpha(0.7).cgColor)
            cg.setLineWidth(CGFloat(sw * 0.8))
            cg.move(to: CGPoint(x: stacks[0].cx, y: stacks[0].cy))
            for i in 1..<stacks.count {
                cg.addLine(to: CGPoint(x: stacks[i].cx, y: stacks[i].cy))
            }
            cg.strokePath()
            cg.restoreGState()
        }
        // Disk stacks
        for pos in stacks {
            let numDisks = 5 + Int(prng.random(seed + pos.cx * 0.13) * 2)
            let diskW = W * 0.22
            let diskH = sw * 1.8
            let stackTotal = diskH * Double(numDisks) * 1.5
            for d in 0..<numDisks {
                let dy = -stackTotal / 2 + Double(d) * diskH * 1.5 + diskH * 0.75
                addEllipseRect(cg, cx: pos.cx, cy: pos.cy + dy,
                               rx: diskW, ry: diskH * 0.65)
                fillStroke(cg, fill: p.accent, stroke: p.line, lineWidth: sw * 0.6)
            }
        }
    }

    // MARK: - Golgi

    private static func golgi(_ cg: CGContext, _ size: Double, _ sw: Double,
                              _ seed: Double, _ prng: PRNG, _ p: Swatch) {
        let numCisternae = 5
        let wBase = size * 0.78
        let sagitta = size * 0.08
        let cisternaH = size * 0.06
        let spacing = size * 0.085
        for i in 0..<numCisternae {
            let t = Double(i) / Double(numCisternae - 1)
            let widthFactor = 1.0 - abs(t - 0.5) * 0.18
            let cw = wBase * widthFactor
            let cy = -(Double(numCisternae - 1) * spacing) / 2 + Double(i) * spacing
            let path = CGMutablePath()
            path.move(to: CGPoint(x: -cw / 2, y: cy))
            path.addQuadCurve(to: CGPoint(x: cw / 2, y: cy),
                              control: CGPoint(x: 0, y: cy + sagitta))
            path.addLine(to: CGPoint(x: cw / 2, y: cy + cisternaH))
            path.addQuadCurve(to: CGPoint(x: -cw / 2, y: cy + cisternaH),
                              control: CGPoint(x: 0, y: cy + sagitta + cisternaH))
            path.closeSubpath()
            cg.addPath(path)
            cg.setLineJoin(.round)
            fillStroke(cg, fill: p.fill, stroke: p.line, lineWidth: sw * 1.1, fillOpacity: 0.92)
        }
        // Vesicles
        for i in 0..<8 {
            let fi = Double(i)
            let sideSign: Double = prng.random(seed + fi * 0.21) > 0.5 ? 1 : -1
            let vy = (prng.random(seed + fi * 0.37) - 0.5) * size * 0.45
            let vx = sideSign * (wBase * 0.5 + size * 0.05
                                 + prng.random(seed + fi * 0.43) * size * 0.08)
            let vesR = size * (0.025 + prng.random(seed + fi * 0.59) * 0.02)
            addEllipseRect(cg, cx: vx, cy: vy, rx: vesR, ry: vesR)
            fillStroke(cg, fill: p.fill, stroke: p.line, lineWidth: sw * 0.85)
        }
    }

    // MARK: - Rough ER

    private static func roughER(_ cg: CGContext, _ size: Double, _ sw: Double,
                                _ seed: Double, _ prng: PRNG, _ p: Swatch) {
        let pts = erTubePoints(size: size, seed: seed, prng: prng, numPoints: 6)
        let tubePath = erTubePath(pts: pts)
        // Thick body
        cg.saveGState()
        cg.setStrokeColor(p.fill.cgColor)
        cg.setLineWidth(CGFloat(size * 0.1))
        cg.setLineCap(.round); cg.setLineJoin(.round)
        cg.addPath(tubePath); cg.strokePath()
        // Outline
        cg.setStrokeColor(p.line.cgColor)
        cg.setLineWidth(CGFloat(sw * 0.9))
        cg.addPath(tubePath); cg.strokePath()
        cg.restoreGState()
        // Ribosome dots offset perpendicular to tube
        let numDots = 26
        let numPoints = pts.count
        for i in 0..<numDots {
            let t = Double(i) / Double(numDots - 1)
            let segIdx = min(numPoints - 2, Int(t * Double(numPoints - 1)))
            let segT = t * Double(numPoints - 1) - Double(segIdx)
            let p0 = pts[segIdx], p1 = pts[segIdx + 1]
            let cx = (p0.0 + p1.0) / 2, cy = p0.1
            let x = (1-segT)*(1-segT)*p0.0 + 2*(1-segT)*segT*cx + segT*segT*p1.0
            let y = (1-segT)*(1-segT)*p0.1 + 2*(1-segT)*segT*cy + segT*segT*p1.1
            let tx = 2*(1-segT)*(cx - p0.0) + 2*segT*(p1.0 - cx)
            let ty = 2*(1-segT)*(cy - p0.1) + 2*segT*(p1.1 - cy)
            let tlen = (tx*tx + ty*ty).squareRoot() + 0.001
            let nx = -ty / tlen, ny = tx / tlen
            let sideSign: Double = (i % 2 == 0) ? 1 : -1
            let offset = size * 0.058
            addEllipseRect(cg, cx: x + nx * offset * sideSign,
                           cy: y + ny * offset * sideSign,
                           rx: sw * 1.4, ry: sw * 1.4)
            fillStroke(cg, fill: p.accent, stroke: p.line, lineWidth: sw * 0.5)
        }
    }

    // MARK: - Smooth ER

    private static func smoothER(_ cg: CGContext, _ size: Double, _ sw: Double,
                                 _ seed: Double, _ prng: PRNG, _ p: Swatch) {
        let pts = erTubePoints(size: size, seed: seed, prng: prng, numPoints: 7)
        let tubePath = erTubePath(pts: pts)
        cg.saveGState()
        cg.setStrokeColor(p.fill.cgColor)
        cg.setLineWidth(CGFloat(size * 0.09))
        cg.setLineCap(.round); cg.setLineJoin(.round)
        cg.addPath(tubePath); cg.strokePath()
        cg.setStrokeColor(p.line.cgColor)
        cg.setLineWidth(CGFloat(sw * 0.9))
        cg.addPath(tubePath); cg.strokePath()
        cg.restoreGState()
        // Branches
        let numBranches = 3
        let numPoints = pts.count
        for i in 0..<numBranches {
            let tParam = 0.2 + Double(i) * 0.3
            let segIdx = min(numPoints - 2, Int(tParam * Double(numPoints - 1)))
            let segT = tParam * Double(numPoints - 1) - Double(segIdx)
            let p0 = pts[segIdx], p1 = pts[segIdx + 1]
            let cx = (p0.0 + p1.0) / 2, cy = p0.1
            let x = (1-segT)*(1-segT)*p0.0 + 2*(1-segT)*segT*cx + segT*segT*p1.0
            let y = (1-segT)*(1-segT)*p0.1 + 2*(1-segT)*segT*cy + segT*segT*p1.1
            let branchLen = size * 0.12
            let branchAng = prng.random(seed + Double(i) * 0.41) * 2 * .pi
            let bx = x + cos(branchAng) * branchLen
            let by = y + sin(branchAng) * branchLen
            // Thick body + thin outline
            cg.saveGState()
            cg.setStrokeColor(p.fill.cgColor)
            cg.setLineWidth(CGFloat(size * 0.05))
            cg.setLineCap(.round)
            cg.move(to: CGPoint(x: x, y: y))
            cg.addLine(to: CGPoint(x: bx, y: by))
            cg.strokePath()
            cg.setStrokeColor(p.line.cgColor)
            cg.setLineWidth(CGFloat(sw * 0.7))
            cg.move(to: CGPoint(x: x, y: y))
            cg.addLine(to: CGPoint(x: bx, y: by))
            cg.strokePath()
            cg.restoreGState()
        }
    }

    /// Zigzag control points used by both ER tubules.
    private static func erTubePoints(size: Double, seed: Double, prng: PRNG,
                                     numPoints: Int) -> [(Double, Double)] {
        let W = size * 0.85, H = size * 0.6
        var pts: [(Double, Double)] = []
        for i in 0..<numPoints {
            let t = Double(i) / Double(numPoints - 1)
            let x = -W / 2 + t * W
            let ySign: Double = (i % 2 == 0) ? -1 : 1
            let yMag = H * 0.32 * (0.7 + prng.random(seed + Double(i) * 0.13) * 0.3)
            pts.append((x, ySign * yMag))
        }
        return pts
    }

    private static func erTubePath(pts: [(Double, Double)]) -> CGPath {
        let path = CGMutablePath()
        guard let first = pts.first else { return path }
        path.move(to: CGPoint(x: first.0, y: first.1))
        for i in 1..<pts.count {
            let prev = pts[i - 1], curr = pts[i]
            let cx = (prev.0 + curr.0) / 2
            let cy = prev.1
            path.addQuadCurve(to: CGPoint(x: curr.0, y: curr.1),
                              control: CGPoint(x: cx, y: cy))
        }
        return path
    }

    // MARK: - Ribosome

    private static func ribosome(_ cg: CGContext, _ size: Double, _ sw: Double, _ p: Swatch) {
        let largeR = size * 0.26
        let smallR = size * 0.2
        let largeY = -size * 0.05
        let smallY = size * 0.16
        addEllipseRect(cg, cx: 0, cy: largeY, rx: largeR, ry: largeR)
        fillStroke(cg, fill: p.fill, stroke: p.line, lineWidth: sw * 1.2, fillOpacity: 0.9)
        cg.setFillColor(p.accent.withAlpha(0.7).cgColor)
        for i in 0..<6 {
            let ang = (Double(i) / 6) * 2 * .pi - .pi / 2
            let x = largeR * 0.7 * cos(ang)
            let y = largeY + largeR * 0.7 * sin(ang)
            cg.fillEllipse(in: CGRect(x: x - sw * 1.5, y: y - sw * 1.5,
                                      width: sw * 3, height: sw * 3))
        }
        addEllipseRect(cg, cx: 0, cy: smallY, rx: smallR, ry: smallR)
        fillStroke(cg, fill: p.line, stroke: p.accent, lineWidth: sw * 1.2, fillOpacity: 0.9)
        cg.setFillColor(p.accent.withAlpha(0.8).cgColor)
        for i in 0..<4 {
            let ang = (Double(i) / 4) * 2 * .pi
            let x = smallR * 0.65 * cos(ang)
            let y = smallY + smallR * 0.65 * sin(ang)
            cg.fillEllipse(in: CGRect(x: x - sw * 1.2, y: y - sw * 1.2,
                                      width: sw * 2.4, height: sw * 2.4))
        }
    }

    // MARK: - Lysosome

    private static func lysosome(_ cg: CGContext, _ size: Double, _ sw: Double,
                                 _ seed: Double, _ prng: PRNG, _ p: Swatch) {
        let r = size * 0.36
        addEllipseRect(cg, cx: 0, cy: 0, rx: r, ry: r)
        fillStroke(cg, fill: p.fill, stroke: p.line, lineWidth: sw * 1.3, fillOpacity: 0.9)
        // Highlight
        cg.setFillColor(white.withAlpha(0.3).cgColor)
        cg.fillEllipse(in: CGRect(x: -r * 0.3 - r * 0.3, y: -r * 0.3 - r * 0.2,
                                  width: r * 0.6, height: r * 0.4))
        // Granules
        cg.setFillColor(p.line.withAlpha(0.85).cgColor)
        for i in 0..<18 {
            let fi = Double(i)
            let ang = prng.random(seed + fi * 0.31) * 2 * .pi
            let dist = prng.random(seed + fi * 0.47).squareRoot() * r * 0.78
            let granR = sw * (1.2 + prng.random(seed + fi * 0.71) * 0.6)
            cg.fillEllipse(in: CGRect(
                x: dist * cos(ang) - granR, y: dist * sin(ang) - granR,
                width: granR * 2, height: granR * 2
            ))
        }
    }

    // MARK: - Vacuole

    private static func vacuole(_ cg: CGContext, _ size: Double, _ sw: Double, _ p: Swatch) {
        let rx = size * 0.5, ry = size * 0.4
        addEllipseRect(cg, cx: 0, cy: 0, rx: rx, ry: ry)
        fillStroke(cg, fill: p.fill, stroke: p.line, lineWidth: sw * 1.3, fillOpacity: 0.85)
        cg.setFillColor(white.withAlpha(0.35).cgColor)
        cg.fillEllipse(in: CGRect(x: -rx * 0.2 - rx * 0.55, y: -ry * 0.3 - ry * 0.3,
                                  width: rx * 1.1, height: ry * 0.6))
        cg.setFillColor(white.withAlpha(0.5).cgColor)
        cg.fillEllipse(in: CGRect(x: -rx * 0.35 - rx * 0.18, y: -ry * 0.4 - ry * 0.08,
                                  width: rx * 0.36, height: ry * 0.16))
    }

    // MARK: - Centrosome

    private static func centrosome(_ cg: CGContext, _ size: Double, _ sw: Double, _ p: Swatch) {
        let outerR = size * 0.4
        let innerR = size * 0.1
        let numSpokes = 9
        addEllipseRect(cg, cx: 0, cy: 0, rx: outerR, ry: outerR)
        fillStroke(cg, fill: p.fill, stroke: p.line, lineWidth: sw * 1.1, fillOpacity: 0.5)
        cg.saveGState()
        cg.setStrokeColor(p.line.cgColor)
        cg.setLineWidth(CGFloat(sw * 0.7))
        cg.setLineCap(.round)
        for i in 0..<numSpokes {
            let ang = (Double(i) / Double(numSpokes)) * 2 * .pi
            let x1 = innerR * cos(ang), y1 = innerR * sin(ang)
            let x2 = outerR * cos(ang), y2 = outerR * sin(ang)
            // Microtubule bundle — three parallel lines per spoke.
            let px = -sin(ang) * sw * 1.8
            let py = cos(ang) * sw * 1.8
            for j in -1...1 {
                let fj = Double(j)
                cg.move(to: CGPoint(x: x1 + px * fj, y: y1 + py * fj))
                cg.addLine(to: CGPoint(x: x2 + px * fj, y: y2 + py * fj))
                cg.strokePath()
            }
        }
        cg.restoreGState()
        addEllipseRect(cg, cx: 0, cy: 0, rx: innerR, ry: innerR)
        fillStroke(cg, fill: p.accent, stroke: p.line, lineWidth: sw * 0.9)
    }

    // MARK: - Peroxisome

    private static func peroxisome(_ cg: CGContext, _ size: Double, _ sw: Double, _ p: Swatch) {
        let r = size * 0.32
        addEllipseRect(cg, cx: 0, cy: 0, rx: r, ry: r)
        fillStroke(cg, fill: p.fill, stroke: p.line, lineWidth: sw * 1.3, fillOpacity: 0.9)
        cg.setFillColor(white.withAlpha(0.3).cgColor)
        cg.fillEllipse(in: CGRect(x: -r * 0.3 - r * 0.3, y: -r * 0.3 - r * 0.2,
                                  width: r * 0.6, height: r * 0.4))
        // Diamond core (square rotated 45°)
        let coreR = r * 0.5
        cg.saveGState()
        cg.rotate(by: .pi / 4)
        cg.addRect(CGRect(x: -coreR, y: -coreR, width: coreR * 2, height: coreR * 2))
        fillStroke(cg, fill: p.accent, stroke: p.line, lineWidth: sw * 0.9)
        // Hatch lines across the diamond (in rotated frame)
        cg.setStrokeColor(p.fill.withAlpha(0.7).cgColor)
        cg.setLineWidth(CGFloat(sw * 0.5))
        for i in -1...1 {
            let fi = Double(i)
            let hx = fi * coreR * 0.4
            cg.move(to: CGPoint(x: hx - coreR * 0.6, y: hx + coreR * 0.6))
            cg.addLine(to: CGPoint(x: hx + coreR * 0.6, y: hx - coreR * 0.6))
            cg.strokePath()
        }
        cg.restoreGState()
    }

    // MARK: - Microtubule

    private static func microtubule(_ cg: CGContext, _ size: Double, _ sw: Double, _ p: Swatch) {
        let L = size * 0.92
        let tubeW = size * 0.075
        let numTubes = 3
        let totalH = Double(numTubes) * tubeW * 1.5
        for i in 0..<numTubes {
            let cy = -totalH / 2 + Double(i) * tubeW * 1.5 + tubeW * 0.75
            let tubeRect = CGRect(x: -L / 2, y: cy - tubeW / 2, width: L, height: tubeW)
            cg.addPath(CGPath(roundedRect: tubeRect,
                              cornerWidth: tubeW / 2, cornerHeight: tubeW / 2,
                              transform: nil))
            fillStroke(cg, fill: p.fill, stroke: p.line, lineWidth: sw * 1.0, fillOpacity: 0.92)
            // White inner highlight
            cg.setFillColor(white.withAlpha(0.25).cgColor)
            let hlRect = CGRect(x: -L / 2 + tubeW * 0.5, y: cy - tubeW * 0.3,
                                width: L - tubeW, height: tubeW * 0.2)
            cg.addPath(CGPath(roundedRect: hlRect,
                              cornerWidth: tubeW * 0.1, cornerHeight: tubeW * 0.1,
                              transform: nil))
            cg.fillPath()
        }
    }

    // MARK: - Flagellum

    private static func flagellum(_ cg: CGContext, _ size: Double, _ sw: Double, _ p: Swatch) {
        let basalR = size * 0.1
        let basalX = -size * 0.4
        addEllipseRect(cg, cx: basalX, cy: 0, rx: basalR, ry: basalR)
        fillStroke(cg, fill: p.line, stroke: p.accent, lineWidth: sw * 1.2)
        // Sinusoidal tail
        let tailLen = size * 0.85
        let cycles = 3.5
        let amp = size * 0.09
        let N = 80
        let path = CGMutablePath()
        path.move(to: CGPoint(x: basalX + basalR, y: 0))
        for i in 1...N {
            let t = Double(i) / Double(N)
            let x = (basalX + basalR) + t * tailLen
            let y = sin(t * cycles * 2 * .pi) * amp * (1 - t * 0.3)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        cg.saveGState()
        cg.setLineCap(.round); cg.setLineJoin(.round)
        cg.setStrokeColor(p.fill.cgColor)
        cg.setLineWidth(CGFloat(sw * 2.4))
        cg.addPath(path); cg.strokePath()
        cg.setStrokeColor(p.line.cgColor)
        cg.setLineWidth(CGFloat(sw * 0.8))
        cg.addPath(path); cg.strokePath()
        cg.restoreGState()
    }
}
