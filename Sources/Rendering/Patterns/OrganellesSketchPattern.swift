import CoreGraphics
import Foundation

/// Cell organelles — sketch style. Same 13 organelles as the textbook pattern
/// but rendered with translucent fills + bold outlines, colored by canvas
/// position (radial palette).
enum OrganellesSketchPattern {

    static let roster: [String] = [
        "nucleus", "nucleus",
        "mitochondrion", "mitochondrion", "mitochondrion",
        "chloroplast", "chloroplast",
        "golgi", "golgi",
        "rough_er", "rough_er",
        "smooth_er",
        "ribosome", "ribosome", "ribosome",
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
                              weighted: roster) { elemCG, x, y, type, slotSize, prng in
            let color = radialPalette(x: x, y: y,
                                      w: Double(size.width), h: Double(size.height),
                                      config: config)
            drawOrganelle(elemCG, type: type, size: slotSize,
                          color: color, config: config, prng: prng)
        }
    }

    private static func drawOrganelle(_ cg: CGContext, type: String, size: Double,
                                      color: RadialColor, config: RenderConfig, prng: PRNG) {
        let a = min(1.0, config.alpha * 2.2)
        let sw = max(0.9, size / 180)
        let seed = prng.next()
        switch type {
        case "nucleus":       nucleus(cg, size, color, a, sw, seed, prng)
        case "mitochondrion": mitochondrion(cg, size, color, a, sw, seed, prng)
        case "chloroplast":   chloroplast(cg, size, color, a, sw, seed, prng)
        case "golgi":         golgi(cg, size, color, a, sw, seed, prng)
        case "rough_er":      er(cg, size, color, a, sw, seed, prng, rough: true)
        case "smooth_er":     er(cg, size, color, a, sw, seed, prng, rough: false)
        case "ribosome":      ribosome(cg, size, color, a, sw)
        case "lysosome":      lysosome(cg, size, color, a, sw, seed, prng)
        case "vacuole":       vacuole(cg, size, color, a, sw)
        case "centrosome":    centrosome(cg, size, color, a, sw)
        case "peroxisome":    peroxisome(cg, size, color, a, sw)
        case "microtubule":   microtubule(cg, size, color, a, sw)
        case "flagellum":     flagellum(cg, size, color, a, sw)
        default: break
        }
    }

    // MARK: - Helpers

    private static func fillStroke(_ cg: CGContext, fill: RGBA, stroke: RGBA,
                                   lineWidth: Double) {
        cg.setFillColor(fill.cgColor)
        cg.setStrokeColor(stroke.cgColor)
        cg.setLineWidth(CGFloat(lineWidth))
        cg.drawPath(using: .fillStroke)
    }

    private static func addEllipseRect(_ cg: CGContext, cx: Double, cy: Double,
                                       rx: Double, ry: Double) {
        cg.addEllipse(in: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2))
    }

    // MARK: - Nucleus

    private static func nucleus(_ cg: CGContext, _ size: Double, _ c: RadialColor,
                                _ a: Double, _ sw: Double, _ seed: Double, _ prng: PRNG) {
        let r = size * 0.42
        addEllipseRect(cg, cx: 0, cy: 0, rx: r, ry: r)
        fillStroke(cg, fill: c.pos.withAlpha(a * 0.55),
                   stroke: c.line.withAlpha(min(1.0, a * 1.5)),
                   lineWidth: sw * 1.4)
        // Nucleolus
        addEllipseRect(cg, cx: r * 0.1, cy: r * 0.05, rx: r * 0.3, ry: r * 0.3)
        fillStroke(cg, fill: c.neg.withAlpha(min(1.0, a)),
                   stroke: c.line.withAlpha(min(1.0, a * 1.5)),
                   lineWidth: sw * 0.9)
        // Specks
        cg.setFillColor(c.line.withAlpha(min(1.0, a)).cgColor)
        let speckR = sw
        for i in 0..<12 {
            let fi = Double(i)
            let ang = prng.random(seed + fi * 0.31) * 2 * .pi
            let dist = (0.5 + prng.random(seed + fi * 0.47) * 0.3) * r
            cg.fillEllipse(in: CGRect(
                x: dist * cos(ang) - speckR, y: dist * sin(ang) - speckR,
                width: speckR * 2, height: speckR * 2
            ))
        }
    }

    // MARK: - Mitochondrion

    private static func mitochondrion(_ cg: CGContext, _ size: Double, _ c: RadialColor,
                                      _ a: Double, _ sw: Double, _ seed: Double, _ prng: PRNG) {
        let L = size * 0.95, W = size * 0.5
        let r = W / 2, bend = size * 0.04
        let x1 = -L / 2 + r, x2 = L / 2 - r
        let body = CGMutablePath()
        body.move(to: CGPoint(x: x1, y: -r))
        body.addQuadCurve(to: CGPoint(x: x2, y: -r), control: CGPoint(x: 0, y: -r - bend))
        body.addArc(center: CGPoint(x: x2, y: 0), radius: r,
                    startAngle: -.pi / 2, endAngle: .pi / 2, clockwise: false)
        body.addQuadCurve(to: CGPoint(x: x1, y: r), control: CGPoint(x: 0, y: r + bend))
        body.addArc(center: CGPoint(x: x1, y: 0), radius: r,
                    startAngle: .pi / 2, endAngle: -.pi / 2, clockwise: false)
        body.closeSubpath()
        cg.addPath(body)
        cg.setLineJoin(.round)
        fillStroke(cg, fill: c.pos.withAlpha(a * 0.55),
                   stroke: c.line.withAlpha(min(1.0, a * 1.5)),
                   lineWidth: sw * 1.4)
        // Cristae loops
        let numLoops = 5
        let loopSpacing = (L * 0.78) / Double(numLoops)
        let loopStartX = -L * 0.39 + loopSpacing / 2
        let loopAmp = r * 0.78
        let loopHalfW = loopSpacing * 0.42
        cg.saveGState()
        cg.setStrokeColor(c.line.withAlpha(min(1.0, a * 1.4)).cgColor)
        cg.setLineWidth(CGFloat(sw * 1.2))
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
            _ = prng.random(seed + Double(i) * 0.1)
        }
        cg.restoreGState()
    }

    // MARK: - Chloroplast

    private static func chloroplast(_ cg: CGContext, _ size: Double, _ c: RadialColor,
                                    _ a: Double, _ sw: Double, _ seed: Double, _ prng: PRNG) {
        let L = size * 0.9, W = size * 0.55
        addEllipseRect(cg, cx: 0, cy: 0, rx: L / 2, ry: W / 2)
        fillStroke(cg, fill: c.pos.withAlpha(a * 0.55),
                   stroke: c.line.withAlpha(min(1.0, a * 1.5)),
                   lineWidth: sw * 1.4)
        var stacks: [(cx: Double, cy: Double)] = []
        for s in 0..<3 {
            let t = (Double(s) + 0.5) / 3
            let cx = -L * 0.32 + t * L * 0.64
            let cy = (prng.random(seed + Double(s) * 0.31) - 0.5) * W * 0.25
            stacks.append((cx, cy))
        }
        if stacks.count >= 2 {
            cg.saveGState()
            cg.setStrokeColor(c.line.withAlpha(min(1.0, a)).cgColor)
            cg.setLineWidth(CGFloat(sw * 0.9))
            cg.move(to: CGPoint(x: stacks[0].cx, y: stacks[0].cy))
            for i in 1..<stacks.count {
                cg.addLine(to: CGPoint(x: stacks[i].cx, y: stacks[i].cy))
            }
            cg.strokePath()
            cg.restoreGState()
        }
        for pos in stacks {
            let numDisks = 5
            let diskW = W * 0.22
            let diskH = sw * 1.8
            let stackTotal = diskH * Double(numDisks) * 1.5
            for d in 0..<numDisks {
                let dy = -stackTotal / 2 + Double(d) * diskH * 1.5 + diskH * 0.75
                addEllipseRect(cg, cx: pos.cx, cy: pos.cy + dy,
                               rx: diskW, ry: diskH * 0.65)
                fillStroke(cg, fill: c.neg.withAlpha(min(1.0, a * 1.1)),
                           stroke: c.line.withAlpha(min(1.0, a * 1.4)),
                           lineWidth: sw * 0.7)
            }
        }
    }

    // MARK: - Golgi

    private static func golgi(_ cg: CGContext, _ size: Double, _ c: RadialColor,
                              _ a: Double, _ sw: Double, _ seed: Double, _ prng: PRNG) {
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
            fillStroke(cg, fill: c.pos.withAlpha(a * 0.6),
                       stroke: c.line.withAlpha(min(1.0, a * 1.5)),
                       lineWidth: sw * 1.1)
        }
        for i in 0..<8 {
            let fi = Double(i)
            let sideSign: Double = prng.random(seed + fi * 0.21) > 0.5 ? 1 : -1
            let vy = (prng.random(seed + fi * 0.37) - 0.5) * size * 0.45
            let vx = sideSign * (wBase * 0.5 + size * 0.05
                                 + prng.random(seed + fi * 0.43) * size * 0.06)
            let vesR = size * (0.025 + prng.random(seed + fi * 0.59) * 0.018)
            addEllipseRect(cg, cx: vx, cy: vy, rx: vesR, ry: vesR)
            fillStroke(cg, fill: c.pos.withAlpha(a * 0.7),
                       stroke: c.line.withAlpha(min(1.0, a * 1.4)),
                       lineWidth: sw * 0.9)
        }
    }

    // MARK: - ER (rough + smooth)

    private static func er(_ cg: CGContext, _ size: Double, _ c: RadialColor,
                           _ a: Double, _ sw: Double, _ seed: Double, _ prng: PRNG,
                           rough: Bool) {
        let W = size * 0.85, H = size * 0.6
        let numPoints = rough ? 6 : 7
        var pts: [(Double, Double)] = []
        for i in 0..<numPoints {
            let t = Double(i) / Double(numPoints - 1)
            let x = -W / 2 + t * W
            let ySign: Double = (i % 2 == 0) ? -1 : 1
            let yMag = H * 0.32 * (0.7 + prng.random(seed + Double(i) * 0.13) * 0.3)
            pts.append((x, ySign * yMag))
        }
        let tubePath = CGMutablePath()
        tubePath.move(to: CGPoint(x: pts[0].0, y: pts[0].1))
        for i in 1..<pts.count {
            let prev = pts[i - 1], curr = pts[i]
            let cx = (prev.0 + curr.0) / 2
            let cy = prev.1
            tubePath.addQuadCurve(to: CGPoint(x: curr.0, y: curr.1),
                                  control: CGPoint(x: cx, y: cy))
        }
        cg.saveGState()
        cg.setLineCap(.round); cg.setLineJoin(.round)
        cg.setStrokeColor(c.pos.withAlpha(a * 0.7).cgColor)
        cg.setLineWidth(CGFloat(size * 0.1))
        cg.addPath(tubePath); cg.strokePath()
        cg.setStrokeColor(c.line.withAlpha(min(1.0, a * 1.5)).cgColor)
        cg.setLineWidth(CGFloat(sw))
        cg.addPath(tubePath); cg.strokePath()
        cg.restoreGState()

        if rough {
            let numDots = 24
            cg.setFillColor(c.line.withAlpha(min(1.0, a * 1.4)).cgColor)
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
                let dx = x + nx * offset * sideSign
                let dy = y + ny * offset * sideSign
                let dr = sw * 1.6
                cg.fillEllipse(in: CGRect(x: dx - dr, y: dy - dr,
                                          width: dr * 2, height: dr * 2))
            }
        } else {
            for i in 0..<3 {
                let tParam = 0.2 + Double(i) * 0.3
                let segIdx = min(numPoints - 2, Int(tParam * Double(numPoints - 1)))
                let segT = tParam * Double(numPoints - 1) - Double(segIdx)
                let p0 = pts[segIdx], p1 = pts[segIdx + 1]
                let cx = (p0.0 + p1.0) / 2, cy = p0.1
                let x = (1-segT)*(1-segT)*p0.0 + 2*(1-segT)*segT*cx + segT*segT*p1.0
                let y = (1-segT)*(1-segT)*p0.1 + 2*(1-segT)*segT*cy + segT*segT*p1.1
                let branchLen = size * 0.13
                let branchAng = prng.random(seed + Double(i) * 0.41) * 2 * .pi
                let bx = x + cos(branchAng) * branchLen
                let by = y + sin(branchAng) * branchLen
                cg.saveGState()
                cg.setStrokeColor(c.pos.withAlpha(a * 0.7).cgColor)
                cg.setLineWidth(CGFloat(size * 0.06))
                cg.setLineCap(.round)
                cg.move(to: CGPoint(x: x, y: y))
                cg.addLine(to: CGPoint(x: bx, y: by))
                cg.strokePath()
                cg.restoreGState()
            }
        }
    }

    // MARK: - Ribosome

    private static func ribosome(_ cg: CGContext, _ size: Double, _ c: RadialColor,
                                 _ a: Double, _ sw: Double) {
        let largeR = size * 0.26
        let smallR = size * 0.2
        let largeY = -size * 0.05
        let smallY = size * 0.16
        addEllipseRect(cg, cx: 0, cy: largeY, rx: largeR, ry: largeR)
        fillStroke(cg, fill: c.pos.withAlpha(a * 0.65),
                   stroke: c.line.withAlpha(min(1.0, a * 1.5)),
                   lineWidth: sw * 1.2)
        cg.setFillColor(c.line.withAlpha(min(1.0, a)).cgColor)
        for i in 0..<6 {
            let ang = (Double(i) / 6) * 2 * .pi - .pi / 2
            let bx = largeR * 0.7 * cos(ang)
            let by = largeY + largeR * 0.7 * sin(ang)
            let br = sw * 1.4
            cg.fillEllipse(in: CGRect(x: bx - br, y: by - br,
                                      width: br * 2, height: br * 2))
        }
        addEllipseRect(cg, cx: 0, cy: smallY, rx: smallR, ry: smallR)
        fillStroke(cg, fill: c.neg.withAlpha(a * 0.65),
                   stroke: c.line.withAlpha(min(1.0, a * 1.5)),
                   lineWidth: sw * 1.2)
    }

    // MARK: - Lysosome

    private static func lysosome(_ cg: CGContext, _ size: Double, _ c: RadialColor,
                                 _ a: Double, _ sw: Double, _ seed: Double, _ prng: PRNG) {
        let r = size * 0.36
        addEllipseRect(cg, cx: 0, cy: 0, rx: r, ry: r)
        fillStroke(cg, fill: c.pos.withAlpha(a * 0.55),
                   stroke: c.line.withAlpha(min(1.0, a * 1.5)),
                   lineWidth: sw * 1.4)
        cg.setFillColor(c.neg.withAlpha(min(1.0, a * 1.1)).cgColor)
        for i in 0..<20 {
            let fi = Double(i)
            let ang = prng.random(seed + fi * 0.31) * 2 * .pi
            let dist = prng.random(seed + fi * 0.47).squareRoot() * r * 0.78
            let granR = sw * (1.4 + prng.random(seed + fi * 0.71) * 0.7)
            cg.fillEllipse(in: CGRect(
                x: dist * cos(ang) - granR, y: dist * sin(ang) - granR,
                width: granR * 2, height: granR * 2
            ))
        }
    }

    // MARK: - Vacuole

    private static func vacuole(_ cg: CGContext, _ size: Double, _ c: RadialColor,
                                _ a: Double, _ sw: Double) {
        let rx = size * 0.5, ry = size * 0.4
        addEllipseRect(cg, cx: 0, cy: 0, rx: rx, ry: ry)
        fillStroke(cg, fill: c.pos.withAlpha(a * 0.3),
                   stroke: c.line.withAlpha(min(1.0, a * 1.5)),
                   lineWidth: sw * 1.4)
        cg.setFillColor(c.pos.withAlpha(a * 0.55).cgColor)
        cg.fillEllipse(in: CGRect(x: -rx * 0.2 - rx * 0.55, y: -ry * 0.3 - ry * 0.3,
                                  width: rx * 1.1, height: ry * 0.6))
        cg.setFillColor(c.pos.withAlpha(a * 0.85).cgColor)
        cg.fillEllipse(in: CGRect(x: -rx * 0.35 - rx * 0.18, y: -ry * 0.4 - ry * 0.08,
                                  width: rx * 0.36, height: ry * 0.16))
    }

    // MARK: - Centrosome

    private static func centrosome(_ cg: CGContext, _ size: Double, _ c: RadialColor,
                                   _ a: Double, _ sw: Double) {
        let outerR = size * 0.4
        let innerR = size * 0.1
        let numSpokes = 9
        addEllipseRect(cg, cx: 0, cy: 0, rx: outerR, ry: outerR)
        fillStroke(cg, fill: c.pos.withAlpha(a * 0.25),
                   stroke: c.line.withAlpha(min(1.0, a * 1.3)),
                   lineWidth: sw * 0.9)
        cg.saveGState()
        cg.setStrokeColor(c.pos.withAlpha(min(1.0, a * 1.3)).cgColor)
        cg.setLineWidth(CGFloat(sw * 0.7))
        cg.setLineCap(.round)
        for i in 0..<numSpokes {
            let ang = (Double(i) / Double(numSpokes)) * 2 * .pi
            let x1 = innerR * cos(ang), y1 = innerR * sin(ang)
            let x2 = outerR * cos(ang), y2 = outerR * sin(ang)
            let px = -sin(ang) * sw * 1.6
            let py = cos(ang) * sw * 1.6
            for j in -1...1 {
                let fj = Double(j)
                cg.move(to: CGPoint(x: x1 + px * fj, y: y1 + py * fj))
                cg.addLine(to: CGPoint(x: x2 + px * fj, y: y2 + py * fj))
                cg.strokePath()
            }
        }
        cg.restoreGState()
        addEllipseRect(cg, cx: 0, cy: 0, rx: innerR, ry: innerR)
        fillStroke(cg, fill: c.neg.withAlpha(min(1.0, a * 1.1)),
                   stroke: c.line.withAlpha(min(1.0, a * 1.5)),
                   lineWidth: sw * 0.8)
    }

    // MARK: - Peroxisome

    private static func peroxisome(_ cg: CGContext, _ size: Double, _ c: RadialColor,
                                   _ a: Double, _ sw: Double) {
        let r = size * 0.32
        addEllipseRect(cg, cx: 0, cy: 0, rx: r, ry: r)
        fillStroke(cg, fill: c.pos.withAlpha(a * 0.55),
                   stroke: c.line.withAlpha(min(1.0, a * 1.5)),
                   lineWidth: sw * 1.4)
        let coreR = r * 0.5
        cg.saveGState()
        cg.rotate(by: .pi / 4)
        cg.addRect(CGRect(x: -coreR, y: -coreR, width: coreR * 2, height: coreR * 2))
        fillStroke(cg, fill: c.neg.withAlpha(min(1.0, a * 1.1)),
                   stroke: c.line.withAlpha(min(1.0, a * 1.5)),
                   lineWidth: sw)
        cg.restoreGState()
    }

    // MARK: - Microtubule

    private static func microtubule(_ cg: CGContext, _ size: Double, _ c: RadialColor,
                                    _ a: Double, _ sw: Double) {
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
            fillStroke(cg, fill: c.pos.withAlpha(a * 0.65),
                       stroke: c.line.withAlpha(min(1.0, a * 1.5)),
                       lineWidth: sw)
        }
    }

    // MARK: - Flagellum

    private static func flagellum(_ cg: CGContext, _ size: Double, _ c: RadialColor,
                                  _ a: Double, _ sw: Double) {
        let basalR = size * 0.1
        let basalX = -size * 0.4
        addEllipseRect(cg, cx: basalX, cy: 0, rx: basalR, ry: basalR)
        fillStroke(cg, fill: c.neg.withAlpha(min(1.0, a)),
                   stroke: c.line.withAlpha(min(1.0, a * 1.5)),
                   lineWidth: sw * 1.2)
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
        cg.setStrokeColor(c.pos.withAlpha(a * 0.6).cgColor)
        cg.setLineWidth(CGFloat(sw * 2.4))
        cg.addPath(path); cg.strokePath()
        cg.setStrokeColor(c.line.withAlpha(min(1.0, a * 1.5)).cgColor)
        cg.setLineWidth(CGFloat(sw * 0.9))
        cg.addPath(path); cg.strokePath()
        cg.restoreGState()
    }
}
