import CoreGraphics
import Foundation

/// Feynman diagrams — particle-physics interaction sketches: t-channel,
/// s-channel, self-energy, vacuum polarization, gluon vertex. Each is a small
/// arrangement of fermion lines (straight), boson lines (wavy), and vertex dots.
enum FeynmanPattern {

    static let roster: [String] = [
        "tchannel", "schannel", "self_energy", "vacuum_polarization", "gluon_vertex",
    ]

    static func draw(in cg: CGContext, size: CGSize, config: RenderConfig,
                     scale: Double, areaScale: Double, prng: PRNG) {
        PlacementEngine.place(in: cg, size: size, config: config,
                              scale: scale, areaScale: areaScale, prng: prng,
                              weighted: roster) { elemCG, x, y, type, elemSize, _ in
            let color = radialPalette(x: x, y: y,
                                      w: Double(size.width), h: Double(size.height),
                                      config: config)
            drawDiagram(elemCG, type: type, size: elemSize,
                        color: color, config: config)
        }
    }

    private static func drawDiagram(_ cg: CGContext, type: String, size: Double,
                                    color: RadialColor, config: RenderConfig) {
        let sw = max(1.5, size / 90)
        let a  = min(1.0, config.alpha * 2.5)
        let s  = size * 0.4

        let lineColor   = color.line.withAlpha(a)
        let vertexColor = color.pos.withAlpha(min(1.0, a * 1.5))

        func fermion(_ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double) {
            cg.saveGState()
            cg.setStrokeColor(lineColor.cgColor)
            cg.setLineWidth(CGFloat(sw))
            cg.setLineCap(.round)
            cg.move(to: CGPoint(x: x1, y: y1))
            cg.addLine(to: CGPoint(x: x2, y: y2))
            cg.strokePath()
            cg.restoreGState()
        }

        func wavy(_ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double) {
            let dx = x2 - x1, dy = y2 - y1
            let len = (dx * dx + dy * dy).squareRoot()
            guard len > 0 else { return }
            let cycles = max(3, Int((len / (sw * 12)).rounded()))
            let amp = sw * 4
            let ux = dx / len, uy = dy / len
            let nx = -uy, ny = ux
            cg.saveGState()
            cg.setStrokeColor(lineColor.cgColor)
            cg.setLineWidth(CGFloat(sw))
            cg.setLineCap(.round)
            let steps = cycles * 12
            cg.move(to: CGPoint(x: x1, y: y1))
            for i in 1...steps {
                let t = Double(i) / Double(steps)
                let px = x1 + dx * t
                let py = y1 + dy * t
                let wave = sin(t * Double(cycles) * 2 * .pi) * amp
                cg.addLine(to: CGPoint(x: px + nx * wave, y: py + ny * wave))
            }
            cg.strokePath()
            cg.restoreGState()
            _ = ux  // silence unused-let (kept for the symmetry above)
        }

        func vertex(_ x: Double, _ y: Double) {
            let r = sw * 1.8
            cg.setFillColor(vertexColor.cgColor)
            cg.fillEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
        }

        switch type {
        case "tchannel":
            fermion(-s, -s, -s * 0.3, -s * 0.3)
            fermion(-s * 0.3, -s * 0.3, -s,  s)
            fermion( s, -s,  s * 0.3, -s * 0.3)
            fermion( s * 0.3, -s * 0.3,  s,  s)
            wavy   (-s * 0.3, -s * 0.3,  s * 0.3, -s * 0.3)
            vertex(-s * 0.3, -s * 0.3)
            vertex( s * 0.3, -s * 0.3)

        case "schannel":
            fermion(-s, -s, -s * 0.3, 0)
            fermion(-s,  s, -s * 0.3, 0)
            fermion( s * 0.3, 0,  s, -s)
            fermion( s * 0.3, 0,  s,  s)
            wavy   (-s * 0.3, 0,  s * 0.3, 0)
            vertex(-s * 0.3, 0)
            vertex( s * 0.3, 0)

        case "vacuum_polarization":
            wavy(-s, 0, -s * 0.4, 0)
            wavy( s * 0.4, 0,  s, 0)
            cg.saveGState()
            cg.setStrokeColor(lineColor.cgColor)
            cg.setLineWidth(CGFloat(sw))
            let lr = s * 0.4
            cg.addEllipse(in: CGRect(x: -lr, y: -lr, width: lr * 2, height: lr * 2))
            cg.strokePath()
            cg.restoreGState()
            vertex(-s * 0.4, 0)
            vertex( s * 0.4, 0)

        case "gluon_vertex":
            wavy(-s, -s * 0.6, 0, 0)
            wavy( s, -s * 0.6, 0, 0)
            wavy( 0,  s,       0, 0)
            vertex(0, 0)

        case "self_energy":
            fermion(-s, 0, -s * 0.4, 0)
            fermion(-s * 0.4, 0,  s * 0.4, 0)
            fermion( s * 0.4, 0,  s, 0)
            // Loop arc above the central fermion line
            let ar = s * 0.4
            cg.saveGState()
            cg.setStrokeColor(lineColor.cgColor)
            cg.setLineWidth(CGFloat(sw))
            let p = CGMutablePath()
            p.addArc(center: CGPoint(x: 0, y: 0), radius: ar,
                     startAngle: .pi, endAngle: 0, clockwise: false)
            cg.addPath(p)
            cg.strokePath()
            cg.restoreGState()
            vertex(-s * 0.4, 0)
            vertex( s * 0.4, 0)

        default:
            break
        }
    }
}
