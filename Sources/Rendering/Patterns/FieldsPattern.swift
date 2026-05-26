import CoreGraphics
import Foundation

/// Electric & magnetic field patterns: dipole, quadrupole, point charge, wire,
/// and like charges. Field lines are integrated by 4th-order Runge-Kutta from
/// each charge, then drawn as paths. Charge symbols (+/−) are placed on top.
enum FieldsPattern {

    static let roster: [String] = ["dipole", "quadrupole", "point", "wire", "like"]

    static func draw(in cg: CGContext, size: CGSize, config: RenderConfig,
                     scale: Double, areaScale: Double, prng: PRNG) {
        PlacementEngine.place(in: cg, size: size, config: config,
                              scale: scale, areaScale: areaScale, prng: prng,
                              weighted: roster) { elemCG, x, y, type, slotSize, _ in
            let color = radialPalette(x: x, y: y,
                                      w: Double(size.width), h: Double(size.height),
                                      config: config)
            drawFieldHero(elemCG, type: type, size: slotSize,
                          color: color, config: config)
        }
    }

    // MARK: - Field tracing (Runge-Kutta 4th order, normalized field)

    /// Walks a field-line path step by step, normalizing the field vector at
    /// each substep so spacing is even regardless of field magnitude. `dir = +1`
    /// integrates outward; `-1` would integrate inward. Bails out when the
    /// field collapses to zero or `term(x, y)` is reached.
    private static func trace(field: (Double, Double) -> (Double, Double),
                              x0: Double, y0: Double,
                              maxSteps: Int, stepSize: Double,
                              dir: Double = 1,
                              term: ((Double, Double) -> Bool)? = nil,
                              bounds: Double = 5000) -> [CGPoint] {
        var pts: [CGPoint] = [CGPoint(x: x0, y: y0)]
        var x = x0, y = y0
        for _ in 0..<maxSteps {
            let k1 = field(x, y)
            let m1 = (k1.0 * k1.0 + k1.1 * k1.1).squareRoot()
            if m1 < 1e-7 { break }
            let k1n = (dir * k1.0 / m1, dir * k1.1 / m1)

            let k2 = field(x + k1n.0 * stepSize / 2, y + k1n.1 * stepSize / 2)
            let m2 = (k2.0 * k2.0 + k2.1 * k2.1).squareRoot()
            if m2 < 1e-7 { break }
            let k2n = (dir * k2.0 / m2, dir * k2.1 / m2)

            let k3 = field(x + k2n.0 * stepSize / 2, y + k2n.1 * stepSize / 2)
            let m3 = (k3.0 * k3.0 + k3.1 * k3.1).squareRoot()
            if m3 < 1e-7 { break }
            let k3n = (dir * k3.0 / m3, dir * k3.1 / m3)

            let k4 = field(x + k3n.0 * stepSize, y + k3n.1 * stepSize)
            let m4 = (k4.0 * k4.0 + k4.1 * k4.1).squareRoot()
            if m4 < 1e-7 { break }
            let k4n = (dir * k4.0 / m4, dir * k4.1 / m4)

            let dx = (k1n.0 + 2*k2n.0 + 2*k3n.0 + k4n.0) / 6 * stepSize
            let dy = (k1n.1 + 2*k2n.1 + 2*k3n.1 + k4n.1) / 6 * stepSize
            x += dx; y += dy
            pts.append(CGPoint(x: x, y: y))
            if let term, term(x, y) { break }
            if abs(x) > bounds || abs(y) > bounds { break }
        }
        return pts
    }

    private static func drawPath(_ cg: CGContext, points: [CGPoint],
                                 stroke: RGBA, lineWidth: Double) {
        guard points.count > 1 else { return }
        cg.saveGState()
        cg.setStrokeColor(stroke.cgColor)
        cg.setLineWidth(CGFloat(lineWidth))
        cg.setLineCap(.round)
        cg.move(to: points[0])
        for i in 1..<points.count { cg.addLine(to: points[i]) }
        cg.strokePath()
        cg.restoreGState()
    }

    // MARK: - Charge symbols (+/−)

    private static func drawCharge(_ cg: CGContext, x: Double, y: Double,
                                   sign: Int, color: RadialColor, size: Double,
                                   config: RenderConfig) {
        let c = sign > 0 ? color.pos : color.neg
        let r = size * 0.07
        // Halo
        cg.setFillColor(c.withAlpha(0.25).cgColor)
        cg.fillEllipse(in: CGRect(x: x - r * 1.6, y: y - r * 1.6,
                                  width: r * 3.2, height: r * 3.2))
        // Main disc
        cg.setFillColor(c.withAlpha(0.42).cgColor)
        cg.fillEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
        // The +/− symbol — strokes in background color so they read against the disc.
        let bg: RGBA = config.background.isDark
            ? RGBA(hex: "#080a10") : RGBA(hex: "#f0f0f0")
        cg.saveGState()
        cg.setStrokeColor(bg.withAlpha(0.6).cgColor)
        cg.setLineWidth(CGFloat(r * 0.22))
        cg.setLineCap(.round)
        cg.move(to: CGPoint(x: x - r * 0.5, y: y))
        cg.addLine(to: CGPoint(x: x + r * 0.5, y: y))
        cg.strokePath()
        if sign > 0 {
            cg.move(to: CGPoint(x: x, y: y - r * 0.5))
            cg.addLine(to: CGPoint(x: x, y: y + r * 0.5))
            cg.strokePath()
        }
        cg.restoreGState()
    }

    // MARK: - Field heroes

    private static func drawFieldHero(_ cg: CGContext, type: String, size: Double,
                                      color: RadialColor, config: RenderConfig) {
        let sw = max(1.2, size / 160)
        let alpha = min(1.0, config.alpha * 1.6)
        let lineStroke = color.line.withAlpha(alpha)

        switch type {
        case "dipole":
            let d = size * 0.25
            let field: (Double, Double) -> (Double, Double) = { x, y in
                let dx1 = x + d, dy1 = y
                let r1 = (dx1 * dx1 + dy1 * dy1).squareRoot() + 0.001
                let dx2 = x - d, dy2 = y
                let r2 = (dx2 * dx2 + dy2 * dy2).squareRoot() + 0.001
                let r1c = r1 * r1 * r1
                let r2c = r2 * r2 * r2
                return (dx1 / r1c - dx2 / r2c, dy1 / r1c - dy2 / r2c)
            }
            let term: (Double, Double) -> Bool = { x, y in
                ((x - d) * (x - d) + y * y).squareRoot() < size * 0.04
            }
            for i in 0..<12 {
                let a = Double(i) / 12 * 2 * .pi
                let sx = -d + cos(a) * size * 0.04
                let sy = sin(a) * size * 0.04
                let pts = trace(field: field, x0: sx, y0: sy,
                                maxSteps: 250, stepSize: size * 0.012,
                                term: term)
                drawPath(cg, points: pts, stroke: lineStroke, lineWidth: sw)
            }
            drawCharge(cg, x: -d, y: 0, sign: +1, color: color, size: size, config: config)
            drawCharge(cg, x:  d, y: 0, sign: -1, color: color, size: size, config: config)

        case "quadrupole":
            let d = size * 0.22
            let charges: [(Double, Double, Int)] = [
                (-d, -d, +1), (d, -d, -1),
                ( d,  d, +1), (-d, d, -1),
            ]
            let field: (Double, Double) -> (Double, Double) = { x, y in
                var ex = 0.0, ey = 0.0
                for (cx, cy, q) in charges {
                    let dx = x - cx, dy = y - cy
                    let r = (dx * dx + dy * dy).squareRoot() + 0.001
                    let rc = r * r * r
                    ex += Double(q) * dx / rc
                    ey += Double(q) * dy / rc
                }
                return (ex, ey)
            }
            for (chx, chy, q) in charges where q > 0 {
                for i in 0..<10 {
                    let a = Double(i) / 10 * 2 * .pi
                    let sx = chx + cos(a) * size * 0.04
                    let sy = chy + sin(a) * size * 0.04
                    let pts = trace(field: field, x0: sx, y0: sy,
                                    maxSteps: 180, stepSize: size * 0.012)
                    drawPath(cg, points: pts, stroke: lineStroke, lineWidth: sw)
                }
            }
            for (chx, chy, q) in charges {
                drawCharge(cg, x: chx, y: chy, sign: q, color: color, size: size, config: config)
            }

        case "point":
            // Radial spokes from a positive point charge
            let inner = size * 0.06, outer = size * 0.42
            cg.saveGState()
            cg.setStrokeColor(lineStroke.cgColor)
            cg.setLineWidth(CGFloat(sw))
            cg.setLineCap(.round)
            for i in 0..<14 {
                let a = Double(i) / 14 * 2 * .pi
                cg.move(to: CGPoint(x: inner * cos(a), y: inner * sin(a)))
                cg.addLine(to: CGPoint(x: outer * cos(a), y: outer * sin(a)))
                cg.strokePath()
            }
            cg.restoreGState()
            drawCharge(cg, x: 0, y: 0, sign: +1, color: color, size: size, config: config)

        case "wire":
            // Magnetic field around a current-carrying wire (concentric loops)
            cg.saveGState()
            cg.setLineWidth(CGFloat(sw))
            for i in 1...5 {
                let r = size * 0.08 * Double(i)
                cg.setStrokeColor(color.line.withAlpha(alpha * (1 - Double(i) * 0.1)).cgColor)
                cg.addEllipse(in: CGRect(x: -r, y: -r, width: r * 2, height: r * 2))
                cg.strokePath()
            }
            cg.restoreGState()
            let r = size * 0.07
            cg.setFillColor(color.pos.withAlpha(min(1.0, alpha * 1.1)).cgColor)
            cg.fillEllipse(in: CGRect(x: -r, y: -r, width: r * 2, height: r * 2))

        case "like":
            // Two like-sign charges — field lines repel between them
            let d = size * 0.25
            let field: (Double, Double) -> (Double, Double) = { x, y in
                let dx1 = x + d, dy1 = y
                let r1 = (dx1 * dx1 + dy1 * dy1).squareRoot() + 0.001
                let dx2 = x - d, dy2 = y
                let r2 = (dx2 * dx2 + dy2 * dy2).squareRoot() + 0.001
                let r1c = r1 * r1 * r1
                let r2c = r2 * r2 * r2
                return (dx1 / r1c + dx2 / r2c, dy1 / r1c + dy2 / r2c)
            }
            for charge in [-d, d] {
                for i in 0..<12 {
                    let a = Double(i) / 12 * 2 * .pi
                    let sx = charge + cos(a) * size * 0.04
                    let sy = sin(a) * size * 0.04
                    let pts = trace(field: field, x0: sx, y0: sy,
                                    maxSteps: 200, stepSize: size * 0.012)
                    drawPath(cg, points: pts, stroke: lineStroke, lineWidth: sw)
                }
            }
            drawCharge(cg, x: -d, y: 0, sign: +1, color: color, size: size, config: config)
            drawCharge(cg, x:  d, y: 0, sign: +1, color: color, size: size, config: config)

        default: break
        }
    }
}
