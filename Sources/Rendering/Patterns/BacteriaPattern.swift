import CoreGraphics
import Foundation

/// Bacterial morphology. Procedural port of the HTML reference. Each shape is
/// drawn with a translucent fill + outline; color comes from canvas position
/// via the shared `radialPalette` helper.
enum BacteriaPattern {

    static let roster: [String] = [
        "rod", "rod", "rod",
        "coccus",
        "diplococcus", "diplococcus",
        "staph", "staph",
        "strepto", "strepto",
        "tetrad",
        "fusiform", "fusiform",
        "filamentous",
        "coccobacillus", "coccobacillus",
        "spirochete", "spirochete",
        "vibrio", "vibrio",
        "branching",
    ]

    static func draw(in cg: CGContext, size: CGSize, config: RenderConfig,
                     scale: Double, areaScale: Double, prng: PRNG) {
        PlacementEngine.place(in: cg, size: size, config: config,
                              scale: scale, areaScale: areaScale, prng: prng,
                              weighted: roster) { elemCG, x, y, type, elemSize, prng in
            let color = radialPalette(x: x, y: y,
                                      w: Double(size.width), h: Double(size.height),
                                      config: config)
            drawBacterium(elemCG, type: type, size: elemSize,
                          color: color, config: config, prng: prng)
        }
    }

    private static func drawBacterium(_ cg: CGContext, type: String, size: Double,
                                      color: RadialColor, config: RenderConfig, prng: PRNG) {
        let a = min(1.0, config.alpha * 1.8)
        let sw = max(0.8, size / 200)
        let seed = prng.next()
        let fill = color.pos.withAlpha(a * 0.5)
        let stroke = color.line.withAlpha(min(1.0, a * 1.3))

        switch type {
        case "rod":
            rod(cg, size, fill: fill, stroke: stroke, lw: sw)
        case "coccus":
            coccus(cg, size, 0.3, 0, 0, fill: fill, stroke: stroke, lw: sw)
        case "diplococcus":
            let sep = size * 0.22 * 1.85
            coccus(cg, size, 0.22, -sep / 2, 0, fill: fill, stroke: stroke, lw: sw)
            coccus(cg, size, 0.22,  sep / 2, 0, fill: fill, stroke: stroke, lw: sw)
        case "staph":
            staph(cg, size, seed, prng, fill: fill, stroke: stroke, lw: sw)
        case "strepto":
            strepto(cg, size, seed, prng, fill: fill, stroke: stroke, lw: sw)
        case "tetrad":
            let sep = size * 0.17 * 1.85
            for (ox, oy) in [(-sep/2, -sep/2), (sep/2, -sep/2),
                             (-sep/2, sep/2), (sep/2, sep/2)] {
                coccus(cg, size, 0.17, ox, oy, fill: fill, stroke: stroke, lw: sw)
            }
        case "coccobacillus":
            rod(cg, size, fill: fill, stroke: stroke, lw: sw, length: 0.45, width: 0.32)
        case "fusiform":
            fusiform(cg, size, fill: fill, stroke: stroke, lw: sw)
        case "filamentous":
            filamentous(cg, size, seed, prng, fill: fill, stroke: stroke, lw: sw)
        case "spirochete":
            spirochete(cg, size, seed, prng, fill: fill, stroke: stroke, lw: sw)
        case "vibrio":
            vibrio(cg, size, seed, prng, fill: fill, stroke: stroke, lw: sw)
        case "branching":
            branching(cg, size, seed, prng, fill: fill, stroke: stroke, lw: sw)
        default:
            break
        }
    }

    // MARK: - Painting

    private static func paint(_ cg: CGContext, fill: RGBA?, stroke: RGBA?, lineWidth: Double) {
        if let fill, let stroke {
            cg.setFillColor(fill.cgColor)
            cg.setStrokeColor(stroke.cgColor)
            cg.setLineWidth(CGFloat(lineWidth))
            cg.drawPath(using: .fillStroke)
        } else if let fill {
            cg.setFillColor(fill.cgColor); cg.fillPath()
        } else if let stroke {
            cg.setStrokeColor(stroke.cgColor)
            cg.setLineWidth(CGFloat(lineWidth)); cg.strokePath()
        }
    }

    private static func fillStrokePath(_ cg: CGContext, _ p: CGPath,
                                       fill: RGBA?, stroke: RGBA?, lw: Double) {
        cg.saveGState()
        cg.setLineJoin(.round)
        cg.addPath(p)
        paint(cg, fill: fill, stroke: stroke, lineWidth: lw)
        cg.restoreGState()
    }

    // MARK: - Primitives

    private static func rod(_ cg: CGContext, _ size: Double,
                            fill: RGBA, stroke: RGBA, lw: Double,
                            length: Double = 0.85, width: Double = 0.22) {
        let L = size * length, W = size * width
        let rect = CGRect(x: -L / 2, y: -W / 2, width: L, height: W)
        let p = CGPath(roundedRect: rect, cornerWidth: W / 2, cornerHeight: W / 2, transform: nil)
        fillStrokePath(cg, p, fill: fill, stroke: stroke, lw: lw)
    }

    private static func coccus(_ cg: CGContext, _ size: Double, _ rFactor: Double,
                               _ ox: Double, _ oy: Double,
                               fill: RGBA, stroke: RGBA, lw: Double) {
        let r = size * rFactor
        cg.saveGState()
        cg.addEllipse(in: CGRect(x: ox - r, y: oy - r, width: 2 * r, height: 2 * r))
        paint(cg, fill: fill, stroke: stroke, lineWidth: lw)
        cg.restoreGState()
    }

    // MARK: - Composite morphologies

    private static func staph(_ cg: CGContext, _ size: Double, _ seed: Double, _ prng: PRNG,
                              fill: RGBA, stroke: RGBA, lw: Double) {
        let numCells = 6 + Int(prng.random(seed) * 7)
        let cellR = size * 0.13
        var placed: [(Double, Double)] = []
        var attempts = 0
        while placed.count < numCells && attempts < 200 {
            attempts += 1
            let ang = prng.random(seed + Double(attempts) * 0.13) * 2 * .pi
            let dist = sqrt(prng.random(seed + Double(attempts) * 0.27)) * size * 0.4
            let x = dist * cos(ang), y = dist * sin(ang)
            var close = false
            for p in placed where hypot(p.0 - x, p.1 - y) < cellR * 1.5 { close = true; break }
            if close { continue }
            placed.append((x, y))
            coccus(cg, size, 0.13, x, y, fill: fill, stroke: stroke, lw: lw)
        }
    }

    private static func strepto(_ cg: CGContext, _ size: Double, _ seed: Double, _ prng: PRNG,
                                fill: RGBA, stroke: RGBA, lw: Double) {
        let numCells = 5 + Int(prng.random(seed) * 6)
        let spacing = size * 0.1 * 1.95
        let curveAmp = (prng.random(seed + 0.13) - 0.5) * size * 0.2
        for i in 0..<numCells {
            let denom = Double(max(1, numCells - 1))
            let t = (Double(i) - Double(numCells - 1) / 2) / denom
            let x = t * spacing * Double(numCells - 1)
            let y = curveAmp * (1 - 4 * t * t)
            coccus(cg, size, 0.1, x, y, fill: fill, stroke: stroke, lw: lw)
        }
    }

    private static func fusiform(_ cg: CGContext, _ size: Double,
                                 fill: RGBA, stroke: RGBA, lw: Double) {
        let L = size * 0.85, W = size * 0.2, E = size * 0.04
        let xL = -L / 2, xR = L / 2
        let p = CGMutablePath()
        p.move(to: CGPoint(x: xL, y: -E / 2))
        p.addQuadCurve(to: CGPoint(x: 0, y: -W / 2), control: CGPoint(x: -L / 4, y: -W / 2))
        p.addQuadCurve(to: CGPoint(x: xR, y: -E / 2), control: CGPoint(x: L / 4, y: -W / 2))
        p.addQuadCurve(to: CGPoint(x: xR, y: E / 2), control: CGPoint(x: xR + E * 0.15, y: 0))
        p.addQuadCurve(to: CGPoint(x: 0, y: W / 2), control: CGPoint(x: L / 4, y: W / 2))
        p.addQuadCurve(to: CGPoint(x: xL, y: E / 2), control: CGPoint(x: -L / 4, y: W / 2))
        p.addQuadCurve(to: CGPoint(x: xL, y: -E / 2), control: CGPoint(x: xL - E * 0.15, y: 0))
        p.closeSubpath()
        fillStrokePath(cg, p, fill: fill, stroke: stroke, lw: lw)
    }

    private static func filamentous(_ cg: CGContext, _ size: Double, _ seed: Double, _ prng: PRNG,
                                    fill: RGBA, stroke: RGBA, lw: Double) {
        let segLen = size * 0.15, segW = size * 0.07
        let numSegs = 5 + Int(prng.random(seed) * 3)
        let totalLen = segLen * Double(numSegs) * 0.95
        let curveAmp = (prng.random(seed + 0.17) - 0.5) * size * 0.12
        let denom = Double(max(1, numSegs - 1))
        for i in 0..<numSegs {
            let t = (Double(i) - Double(numSegs - 1) / 2) / denom
            let x = t * totalLen
            let y = curveAmp * (1 - 4 * t * t)
            let tangentY = curveAmp * (-8 * t / denom)
            let angle = atan2(tangentY, totalLen / Double(numSegs))
            cg.saveGState()
            cg.translateBy(x: x, y: y)
            cg.rotate(by: angle)
            let sL = segLen * 0.92
            let rect = CGRect(x: -sL / 2, y: -segW / 2, width: sL, height: segW)
            let p = CGPath(roundedRect: rect, cornerWidth: segW / 2,
                           cornerHeight: segW / 2, transform: nil)
            fillStrokePath(cg, p, fill: fill, stroke: stroke, lw: lw * 0.85)
            cg.restoreGState()
        }
    }

    private static func spirochete(_ cg: CGContext, _ size: Double, _ seed: Double, _ prng: PRNG,
                                   fill: RGBA, stroke: RGBA, lw: Double) {
        let n = 120
        let amp = size * 0.1, length = size * 0.85
        let turns = 4 + Int(prng.random(seed) * 3)
        let wave = CGMutablePath()
        for i in 0...n {
            let t = Double(i) / Double(n)
            let pt = CGPoint(x: -length / 2 + t * length,
                             y: sin(t * Double(turns) * 2 * .pi) * amp)
            if i == 0 { wave.move(to: pt) } else { wave.addLine(to: pt) }
        }
        // Thick body, then a thin inner line.
        cg.saveGState()
        cg.setLineCap(.round); cg.setLineJoin(.round)
        cg.addPath(wave)
        cg.setStrokeColor(fill.cgColor)
        cg.setLineWidth(CGFloat(size * 0.08))
        cg.strokePath()
        cg.addPath(wave)
        cg.setStrokeColor(stroke.cgColor)
        cg.setLineWidth(CGFloat(lw * 0.9))
        cg.strokePath()
        cg.restoreGState()
    }

    private static func vibrio(_ cg: CGContext, _ size: Double, _ seed: Double, _ prng: PRNG,
                               fill: RGBA, stroke: RGBA, lw: Double) {
        let length = size * 0.7, width = size * 0.18
        let arcR = length / (1.4 + prng.random(seed) * 0.6)
        let sagitta = arcR - sqrt(arcR * arcR - (length / 2) * (length / 2))
        let n = 24
        let centerline = CGMutablePath()
        for i in 0...n {
            let t = Double(i) / Double(n)
            let halfAng = asin((length / 2) / arcR)
            let ang = -halfAng + t * 2 * halfAng + .pi / 2
            let px = arcR * cos(ang)
            let py = (sagitta - arcR) + arcR * sin(ang)
            if i == 0 { centerline.move(to: CGPoint(x: px, y: py)) }
            else { centerline.addLine(to: CGPoint(x: px, y: py)) }
        }
        // Curved capsule: thick outline stroke, then a slightly thinner fill stroke.
        cg.saveGState()
        cg.setLineCap(.round); cg.setLineJoin(.round)
        cg.addPath(centerline)
        cg.setStrokeColor(stroke.cgColor)
        cg.setLineWidth(CGFloat(width + lw))
        cg.strokePath()
        cg.addPath(centerline)
        cg.setStrokeColor(fill.cgColor)
        cg.setLineWidth(CGFloat(width - lw))
        cg.strokePath()
        cg.restoreGState()
    }

    private static func branching(_ cg: CGContext, _ size: Double, _ seed: Double, _ prng: PRNG,
                                  fill: RGBA, stroke: RGBA, lw: Double) {
        func segment(_ x: Double, _ y: Double, _ angle: Double,
                     _ length: Double, _ width: Double, _ depth: Int, _ branchSeed: Double) {
            cg.saveGState()
            cg.translateBy(x: x, y: y)
            cg.rotate(by: angle)
            cg.translateBy(x: length / 2, y: 0)
            let rect = CGRect(x: -length / 2, y: -width / 2, width: length, height: width)
            let p = CGPath(roundedRect: rect, cornerWidth: width / 2,
                           cornerHeight: width / 2, transform: nil)
            fillStrokePath(cg, p, fill: fill, stroke: stroke,
                           lw: lw * max(0.5, width / (size * 0.1)))
            cg.restoreGState()
            if depth <= 0 { return }
            let numChildren = 1 + Int(prng.random(branchSeed + 0.13) * 2)
            for i in 0..<numChildren {
                let fi = Double(i)
                let tAlong = 0.4 + prng.random(branchSeed + fi * 0.27) * 0.4
                let attachX = x + cos(angle) * length * tAlong
                let attachY = y + sin(angle) * length * tAlong
                let sideSign = prng.random(branchSeed + fi * 0.41) > 0.5 ? 1.0 : -1.0
                let delta = (.pi / 180) * (30 + prng.random(branchSeed + fi * 0.53) * 20) * sideSign
                let childLen = length * (0.45 + prng.random(branchSeed + fi * 0.67) * 0.25)
                let childW = width * (0.65 + prng.random(branchSeed + fi * 0.79) * 0.15)
                segment(attachX, attachY, angle + delta, childLen, childW,
                        depth - 1, branchSeed + fi * 1.13 + 17.31)
            }
        }
        let trunkLen = size * 0.55, trunkW = size * 0.11
        segment(-trunkLen / 2, 0, 0, trunkLen, trunkW, 2, seed)
    }
}
