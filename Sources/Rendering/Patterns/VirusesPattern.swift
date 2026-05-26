import CoreGraphics
import Foundation

/// Viral capsids — eight morphologies: icosahedral, helical, phage,
/// enveloped (spiked sphere), filovirus (curved filament), bullet (rabies-like),
/// geminate (twin icosahedra), poxvirus (brick with surface tubules).
/// Colored by canvas position via the shared radial palette.
enum VirusesPattern {

    static let roster: [String] = [
        "icosahedral", "icosahedral", "icosahedral",
        "enveloped", "enveloped", "enveloped",
        "phage", "phage",
        "helical", "helical",
        "filovirus", "filovirus",
        "bullet",
        "geminate",
        "poxvirus",
    ]

    static func draw(in cg: CGContext, size: CGSize, config: RenderConfig,
                     scale: Double, areaScale: Double, prng: PRNG) {
        PlacementEngine.place(in: cg, size: size, config: config,
                              scale: scale, areaScale: areaScale, prng: prng,
                              weighted: roster) { elemCG, x, y, type, slotSize, prng in
            let color = radialPalette(x: x, y: y,
                                      w: Double(size.width), h: Double(size.height),
                                      config: config)
            drawVirus(elemCG, type: type, size: slotSize,
                      color: color, config: config, prng: prng)
        }
    }

    private static func drawVirus(_ cg: CGContext, type: String, size: Double,
                                  color: RadialColor, config: RenderConfig, prng: PRNG) {
        let a = min(1.0, config.alpha * 1.8)
        let sw = max(0.8, size / 200)
        let seed = prng.next()
        switch type {
        case "icosahedral": icosahedral(cg, size, color, a, sw)
        case "helical":     helical(cg, size, color, a, sw)
        case "phage":       phage(cg, size, color, a, sw)
        case "enveloped":   enveloped(cg, size, color, a, sw)
        case "filovirus":   filovirus(cg, size, color, a, sw, seed, prng)
        case "bullet":      bullet(cg, size, color, a, sw)
        case "geminate":    geminate(cg, size, color, a, sw)
        case "poxvirus":    poxvirus(cg, size, color, a, sw, seed, prng)
        default: break
        }
    }

    // MARK: - Shape helpers

    private static func hexagonPath(cx: Double, cy: Double, r: Double,
                                    rotationOffset: Double = -.pi / 6) -> CGPath {
        let path = CGMutablePath()
        for i in 0..<6 {
            let ang = Double(i) * .pi / 3 + rotationOffset
            let p = CGPoint(x: cx + r * cos(ang), y: cy + r * sin(ang))
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }

    private static func fillStroke(_ cg: CGContext, path: CGPath,
                                   fill: RGBA, stroke: RGBA,
                                   lineWidth: Double) {
        cg.saveGState()
        cg.setLineJoin(.round)
        cg.setFillColor(fill.cgColor)
        cg.setStrokeColor(stroke.cgColor)
        cg.setLineWidth(CGFloat(lineWidth))
        cg.addPath(path)
        cg.drawPath(using: .fillStroke)
        cg.restoreGState()
    }

    // MARK: - Icosahedral

    private static func icosahedral(_ cg: CGContext, _ size: Double, _ c: RadialColor,
                                    _ a: Double, _ sw: Double) {
        let r = size * 0.4
        let path = hexagonPath(cx: 0, cy: 0, r: r)
        fillStroke(cg, path: path,
                   fill: c.pos.withAlpha(a * 0.3),
                   stroke: c.line.withAlpha(min(1.0, a * 1.3)),
                   lineWidth: sw)
        // Spokes from center to each vertex
        cg.saveGState()
        cg.setStrokeColor(c.line.withAlpha(a * 0.7).cgColor)
        cg.setLineWidth(CGFloat(sw * 0.7))
        cg.setLineCap(.round)
        for i in 0..<6 {
            let ang = Double(i) * .pi / 3 - .pi / 6
            cg.move(to: .zero)
            cg.addLine(to: CGPoint(x: r * cos(ang), y: r * sin(ang)))
            cg.strokePath()
        }
        cg.restoreGState()
        // Dots near each vertex
        cg.setFillColor(c.pos.withAlpha(min(1.0, a * 1.3)).cgColor)
        let dotR = sw * 1.6
        for i in 0..<6 {
            let ang = Double(i) * .pi / 3 - .pi / 6
            let vx = r * cos(ang) * 0.85
            let vy = r * sin(ang) * 0.85
            cg.fillEllipse(in: CGRect(x: vx - dotR, y: vy - dotR,
                                      width: dotR * 2, height: dotR * 2))
        }
        // Center dot
        let cR = sw * 1.4
        cg.fillEllipse(in: CGRect(x: -cR, y: -cR, width: cR * 2, height: cR * 2))
    }

    // MARK: - Helical

    private static func helical(_ cg: CGContext, _ size: Double, _ c: RadialColor,
                                _ a: Double, _ sw: Double) {
        let L = size * 0.85, W = size * 0.22, r = W / 2
        let rect = CGRect(x: -L / 2, y: -r, width: L, height: W)
        let path = CGPath(roundedRect: rect, cornerWidth: r, cornerHeight: r, transform: nil)
        fillStroke(cg, path: path,
                   fill: c.pos.withAlpha(a * 0.3),
                   stroke: c.line.withAlpha(min(1.0, a * 1.3)),
                   lineWidth: sw)
        let numStripes = max(5, Int((L / (W * 0.45)).rounded(.down)))
        let stripeRange = L - W * 0.6
        cg.saveGState()
        cg.setStrokeColor(c.line.withAlpha(a * 0.8).cgColor)
        cg.setLineWidth(CGFloat(sw * 0.6))
        cg.setLineCap(.round)
        for i in 0..<numStripes {
            let t = (Double(i) + 0.5) / Double(numStripes)
            let sx = -stripeRange / 2 + t * stripeRange
            cg.move(to: CGPoint(x: sx, y: -r * 0.75))
            cg.addLine(to: CGPoint(x: sx, y:  r * 0.75))
            cg.strokePath()
        }
        cg.restoreGState()
    }

    // MARK: - Bacteriophage

    private static func phage(_ cg: CGContext, _ size: Double, _ c: RadialColor,
                              _ a: Double, _ sw: Double) {
        let headR = size * 0.22
        let headCy = -size * 0.18
        // Head — hexagon (rotated so a flat side is at the bottom)
        let headPath = CGMutablePath()
        for i in 0..<6 {
            let ang = Double(i) * .pi / 3 - .pi / 2
            let p = CGPoint(x: headR * cos(ang), y: headCy + headR * sin(ang))
            if i == 0 { headPath.move(to: p) } else { headPath.addLine(to: p) }
        }
        headPath.closeSubpath()
        fillStroke(cg, path: headPath,
                   fill: c.pos.withAlpha(a * 0.35),
                   stroke: c.line.withAlpha(min(1.0, a * 1.3)),
                   lineWidth: sw)
        // Tail
        let tailW = headR * 0.4
        let tailTop = headCy + headR  // sin(π/2) = 1
        let tailBottom = size * 0.18
        let tailHeight = tailBottom - tailTop
        let tailRect = CGRect(x: -tailW / 2, y: tailTop, width: tailW, height: tailHeight)
        cg.addRect(tailRect)
        fillStroke(cg, path: CGPath(rect: tailRect, transform: nil),
                   fill: c.pos.withAlpha(a * 0.3),
                   stroke: c.line.withAlpha(min(1.0, a * 1.3)),
                   lineWidth: sw)
        // Tail stripes
        cg.saveGState()
        cg.setStrokeColor(c.line.withAlpha(a * 0.7).cgColor)
        cg.setLineWidth(CGFloat(sw * 0.5))
        for i in 1..<4 {
            let ty = tailTop + Double(i) / 4 * tailHeight
            cg.move(to: CGPoint(x: -tailW / 2, y: ty))
            cg.addLine(to: CGPoint(x:  tailW / 2, y: ty))
            cg.strokePath()
        }
        cg.restoreGState()
        // Baseplate
        let plateW = tailW * 1.6
        cg.saveGState()
        cg.setStrokeColor(c.line.withAlpha(min(1.0, a * 1.4)).cgColor)
        cg.setLineWidth(CGFloat(sw * 1.6))
        cg.setLineCap(.round)
        cg.move(to: CGPoint(x: -plateW / 2, y: tailBottom))
        cg.addLine(to: CGPoint(x:  plateW / 2, y: tailBottom))
        cg.strokePath()
        cg.restoreGState()
        // Six legs splaying out from the baseplate
        cg.saveGState()
        cg.setStrokeColor(c.line.withAlpha(min(1.0, a * 1.2)).cgColor)
        cg.setLineWidth(CGFloat(sw * 0.8))
        cg.setLineCap(.round); cg.setLineJoin(.round)
        let legLen = size * 0.22
        for i in 0..<6 {
            let t = (Double(i) + 0.5) / 6
            let startX = -plateW / 2 + t * plateW
            let startY = tailBottom
            let splay = (t - 0.5) * 2
            let midX = startX + splay * legLen * 0.55
            let midY = startY + legLen * 0.35
            let endX = midX + splay * legLen * 0.4
            let endY = midY + legLen * 0.55
            cg.move(to: CGPoint(x: startX, y: startY))
            cg.addLine(to: CGPoint(x: midX, y: midY))
            cg.addLine(to: CGPoint(x: endX, y: endY))
            cg.strokePath()
        }
        cg.restoreGState()
    }

    // MARK: - Enveloped (spiked sphere)

    private static func enveloped(_ cg: CGContext, _ size: Double, _ c: RadialColor,
                                  _ a: Double, _ sw: Double) {
        let r = size * 0.34
        // Envelope
        cg.addEllipse(in: CGRect(x: -r, y: -r, width: r * 2, height: r * 2))
        fillStroke(cg, path: CGPath(ellipseIn: CGRect(x: -r, y: -r,
                                                       width: r * 2, height: r * 2),
                                    transform: nil),
                   fill: c.pos.withAlpha(a * 0.3),
                   stroke: c.line.withAlpha(min(1.0, a * 1.3)),
                   lineWidth: sw)
        // Inner core
        let capR = r * 0.5
        let capRect = CGRect(x: -capR, y: -capR, width: capR * 2, height: capR * 2)
        fillStroke(cg, path: CGPath(ellipseIn: capRect, transform: nil),
                   fill: c.neg.withAlpha(a * 0.5),
                   stroke: c.neg.withAlpha(min(1.0, a * 1.3)),
                   lineWidth: sw * 0.7)
        // Spikes
        let numSpikes = 16
        let spikeLen = r * 0.22
        let knobR = sw * 1.4
        cg.saveGState()
        cg.setStrokeColor(c.line.withAlpha(min(1.0, a * 1.2)).cgColor)
        cg.setLineWidth(CGFloat(sw * 0.7))
        cg.setLineCap(.round)
        for i in 0..<numSpikes {
            let ang = Double(i) / Double(numSpikes) * 2 * .pi
            let x1 = r * cos(ang), y1 = r * sin(ang)
            let x2 = (r + spikeLen) * cos(ang), y2 = (r + spikeLen) * sin(ang)
            cg.move(to: CGPoint(x: x1, y: y1))
            cg.addLine(to: CGPoint(x: x2, y: y2))
            cg.strokePath()
        }
        cg.restoreGState()
        cg.setFillColor(c.pos.withAlpha(min(1.0, a * 1.4)).cgColor)
        for i in 0..<numSpikes {
            let ang = Double(i) / Double(numSpikes) * 2 * .pi
            let x2 = (r + spikeLen) * cos(ang), y2 = (r + spikeLen) * sin(ang)
            cg.fillEllipse(in: CGRect(x: x2 - knobR, y: y2 - knobR,
                                      width: knobR * 2, height: knobR * 2))
        }
    }

    // MARK: - Filovirus (curved filament)

    private static func filovirus(_ cg: CGContext, _ size: Double, _ c: RadialColor,
                                  _ a: Double, _ sw: Double,
                                  _ seed: Double, _ prng: PRNG) {
        let L = size * 0.95, W = size * 0.13, r = W / 2
        let N = 60
        let startX = -L / 2, startY = 0.0
        let endX = L / 2, endY = 0.0
        let bendSign: Double = prng.random(seed) > 0.5 ? 1 : -1
        let bendStrength = 0.25 + prng.random(seed + 0.1) * 0.15
        let ctrlX = 0.0, ctrlY = bendSign * L * bendStrength
        var spinePts: [(Double, Double)] = []
        var tangents: [(Double, Double)] = []
        for i in 0...N {
            let t = Double(i) / Double(N)
            let x = (1-t)*(1-t)*startX + 2*(1-t)*t*ctrlX + t*t*endX
            let y = (1-t)*(1-t)*startY + 2*(1-t)*t*ctrlY + t*t*endY
            spinePts.append((x, y))
            let tx = 2*(1-t)*(ctrlX - startX) + 2*t*(endX - ctrlX)
            let ty = 2*(1-t)*(ctrlY - startY) + 2*t*(endY - ctrlY)
            let tlen = (tx*tx + ty*ty).squareRoot()
            tangents.append((tx / tlen, ty / tlen))
        }
        // Outline path: top edge, end cap arc, bottom edge reversed, start cap arc
        var top: [(Double, Double)] = []
        var bot: [(Double, Double)] = []
        for i in 0...N {
            let (x, y) = spinePts[i]
            let (tx, ty) = tangents[i]
            let nx = -ty, ny = tx
            top.append((x + nx * r, y + ny * r))
            bot.append((x - nx * r, y - ny * r))
        }
        let path = CGMutablePath()
        path.move(to: CGPoint(x: top[0].0, y: top[0].1))
        for i in 1...N {
            path.addLine(to: CGPoint(x: top[i].0, y: top[i].1))
        }
        path.addArc(center: CGPoint(x: spinePts[N].0, y: spinePts[N].1),
                    radius: r,
                    startAngle: atan2(top[N].1 - spinePts[N].1, top[N].0 - spinePts[N].0),
                    endAngle:   atan2(bot[N].1 - spinePts[N].1, bot[N].0 - spinePts[N].0),
                    clockwise: false)
        for i in (0..<N).reversed() {
            path.addLine(to: CGPoint(x: bot[i].0, y: bot[i].1))
        }
        path.addArc(center: CGPoint(x: spinePts[0].0, y: spinePts[0].1),
                    radius: r,
                    startAngle: atan2(bot[0].1 - spinePts[0].1, bot[0].0 - spinePts[0].0),
                    endAngle:   atan2(top[0].1 - spinePts[0].1, top[0].0 - spinePts[0].0),
                    clockwise: false)
        path.closeSubpath()
        fillStroke(cg, path: path,
                   fill: c.pos.withAlpha(a * 0.3),
                   stroke: c.line.withAlpha(min(1.0, a * 1.3)),
                   lineWidth: sw)
        // Helical cross-stripes perpendicular to spine
        let numStripes = max(8, Int((L / (W * 0.5)).rounded(.down)))
        cg.saveGState()
        cg.setStrokeColor(c.line.withAlpha(a * 0.7).cgColor)
        cg.setLineWidth(CGFloat(sw * 0.5))
        cg.setLineCap(.round)
        for i in 0..<numStripes {
            let t = (Double(i) + 0.5) / Double(numStripes)
            let idx = min(N, Int(t * Double(N)))
            let (px, py) = spinePts[idx]
            let (tx, ty) = tangents[idx]
            let nx = -ty, ny = tx
            cg.move(to: CGPoint(x: px + nx * r * 0.75, y: py + ny * r * 0.75))
            cg.addLine(to: CGPoint(x: px - nx * r * 0.75, y: py - ny * r * 0.75))
            cg.strokePath()
        }
        cg.restoreGState()
    }

    // MARK: - Bullet (rabies-style)

    private static func bullet(_ cg: CGContext, _ size: Double, _ c: RadialColor,
                               _ a: Double, _ sw: Double) {
        let L = size * 0.72, W = size * 0.32, r = W / 2
        let topY = -L / 2, bottomY = L / 2, domeBaseY = topY + r
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -r, y: domeBaseY))
        path.addArc(center: CGPoint(x: 0, y: domeBaseY), radius: r,
                    startAngle: .pi, endAngle: 0, clockwise: false)
        path.addLine(to: CGPoint(x: r, y: bottomY))
        path.addLine(to: CGPoint(x: -r, y: bottomY))
        path.closeSubpath()
        fillStroke(cg, path: path,
                   fill: c.pos.withAlpha(a * 0.3),
                   stroke: c.line.withAlpha(min(1.0, a * 1.3)),
                   lineWidth: sw)
        let bodyH = bottomY - domeBaseY
        let numStripes = max(6, Int((bodyH / (W * 0.4)).rounded(.down)))
        cg.saveGState()
        cg.setStrokeColor(c.line.withAlpha(a * 0.75).cgColor)
        cg.setLineWidth(CGFloat(sw * 0.5))
        cg.setLineCap(.round)
        for i in 0..<numStripes {
            let t = (Double(i) + 0.5) / Double(numStripes)
            let sy = domeBaseY + t * bodyH
            cg.move(to: CGPoint(x: -r * 0.75, y: sy))
            cg.addLine(to: CGPoint(x:  r * 0.75, y: sy))
            cg.strokePath()
        }
        cg.restoreGState()
    }

    // MARK: - Geminate (twin icosahedra)

    private static func geminate(_ cg: CGContext, _ size: Double, _ c: RadialColor,
                                 _ a: Double, _ sw: Double) {
        let r = size * 0.32
        let offset = r * 0.85
        for sign in [-1.0, 1.0] {
            let cx = sign * offset
            let path = hexagonPath(cx: cx, cy: 0, r: r)
            fillStroke(cg, path: path,
                       fill: c.pos.withAlpha(a * 0.3),
                       stroke: c.line.withAlpha(min(1.0, a * 1.3)),
                       lineWidth: sw)
            cg.saveGState()
            cg.setStrokeColor(c.line.withAlpha(a * 0.6).cgColor)
            cg.setLineWidth(CGFloat(sw * 0.6))
            cg.setLineCap(.round)
            for i in 0..<6 {
                let ang = Double(i) * .pi / 3 - .pi / 6
                cg.move(to: CGPoint(x: cx, y: 0))
                cg.addLine(to: CGPoint(x: cx + r * cos(ang), y: r * sin(ang)))
                cg.strokePath()
            }
            cg.restoreGState()
            cg.setFillColor(c.pos.withAlpha(min(1.0, a * 1.3)).cgColor)
            let cR = sw * 1.2
            cg.fillEllipse(in: CGRect(x: cx - cR, y: -cR, width: cR * 2, height: cR * 2))
        }
    }

    // MARK: - Poxvirus (brick + tubules)

    private static func poxvirus(_ cg: CGContext, _ size: Double, _ c: RadialColor,
                                 _ a: Double, _ sw: Double,
                                 _ seed: Double, _ prng: PRNG) {
        let W = size * 0.75, H = size * 0.55, cornerR = size * 0.1
        let rect = CGRect(x: -W / 2, y: -H / 2, width: W, height: H)
        let path = CGPath(roundedRect: rect,
                          cornerWidth: cornerR, cornerHeight: cornerR, transform: nil)
        fillStroke(cg, path: path,
                   fill: c.pos.withAlpha(a * 0.3),
                   stroke: c.line.withAlpha(min(1.0, a * 1.3)),
                   lineWidth: sw)
        // Surface tubule squiggles
        let numSquiggles = 7
        let squiggleLen = W * 0.55
        let squiggleAmp = sw * 1.5
        cg.saveGState()
        cg.setStrokeColor(c.line.withAlpha(a * 0.75).cgColor)
        cg.setLineWidth(CGFloat(sw * 0.5))
        cg.setLineCap(.round)
        for i in 0..<numSquiggles {
            let fi = Double(i)
            let t = (fi + 0.5) / Double(numSquiggles)
            let cy = -H / 2 + t * H
            let xPad = (i % 2 == 0) ? W * 0.1 : -W * 0.1
            let xStart = -squiggleLen / 2 + xPad
            let N = 12
            cg.move(to: CGPoint(x: xStart, y: cy))
            for j in 1...N {
                let tt = Double(j) / Double(N)
                let x = xStart + tt * squiggleLen
                let y = cy + sin(tt * 3 * .pi + fi + prng.random(seed + fi)) * squiggleAmp
                cg.addLine(to: CGPoint(x: x, y: y))
            }
            cg.strokePath()
        }
        cg.restoreGState()
        // Inner core dots
        cg.setFillColor(c.pos.withAlpha(min(1.0, a * 1.4)).cgColor)
        let coreR = sw * 1.3
        for xs in [-W * 0.25, W * 0.25] {
            cg.fillEllipse(in: CGRect(x: xs - coreR, y: -coreR,
                                      width: coreR * 2, height: coreR * 2))
        }
    }
}
