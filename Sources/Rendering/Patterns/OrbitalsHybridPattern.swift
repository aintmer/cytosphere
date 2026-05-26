import CoreGraphics
import Foundation

/// Atomic orbitals — hybrid style (soft probability clouds with two-tone phase
/// coloring). Each lobe / shell is a radial gradient clipped to its silhouette,
/// producing the fuzzy-density-plot look. Types: 1s, 2s, 3s, 2p, 3p, 3dz², 3d
/// cloverleaf.
enum OrbitalsHybridPattern {

    static let roster: [String] = [
        "1s", "1s",
        "2s", "2s",
        "3s",
        "2p", "2p", "2p", "2p",
        "3p", "3p", "3p",
        "3dz2", "3dz2",
        "3d_clover", "3d_clover", "3d_clover",
    ]

    static func draw(in cg: CGContext, size: CGSize, config: RenderConfig,
                     scale: Double, areaScale: Double, prng: PRNG) {
        PlacementEngine.place(in: cg, size: size, config: config,
                              scale: scale, areaScale: areaScale, prng: prng,
                              weighted: roster) { elemCG, x, y, type, slotSize, _ in
            let color = orbitalPhaseColors(x: x, y: y,
                                           w: Double(size.width),
                                           h: Double(size.height),
                                           config: config)
            drawOrbital(elemCG, type: type, size: slotSize,
                        color: color, config: config)
        }
    }

    private static func drawOrbital(_ cg: CGContext, type: String, size: Double,
                                    color: OrbitalPhaseColors, config: RenderConfig) {
        let a = min(1.0, config.alpha * 2.0)
        switch type {
        case "1s":
            sphericalCloud(cg, radius: size * 0.38, color: color, phase: .pos, alpha: a)
        case "2s":
            sphericalCloud(cg, radius: size * 0.45, color: color, phase: .pos, alpha: a * 0.65)
            nodalRing(cg, innerR: size * 0.18, outerR: size * 0.32,
                      color: color, phase: .neg, alpha: a * 0.85)
            sphericalCloud(cg, radius: size * 0.12, color: color, phase: .pos, alpha: a * 0.95)
        case "3s":
            sphericalCloud(cg, radius: size * 0.5, color: color, phase: .pos, alpha: a * 0.5)
            nodalRing(cg, innerR: size * 0.32, outerR: size * 0.46,
                      color: color, phase: .neg, alpha: a * 0.7)
            nodalRing(cg, innerR: size * 0.16, outerR: size * 0.28,
                      color: color, phase: .pos, alpha: a * 0.85)
            sphericalCloud(cg, radius: size * 0.09, color: color, phase: .neg, alpha: a)
        case "2p":
            let L = size * 0.42, W = size * 0.22
            teardropLobe(cg, length: L, width: W, color: color, phase: .pos, alpha: a, rotationDeg: 0)
            teardropLobe(cg, length: L, width: W, color: color, phase: .neg, alpha: a, rotationDeg: 180)
        case "3p":
            let L = size * 0.42, W = size * 0.22
            teardropLobe(cg, length: L, width: W, color: color, phase: .pos, alpha: a, rotationDeg: 0)
            teardropLobe(cg, length: L, width: W, color: color, phase: .neg, alpha: a, rotationDeg: 180)
            // Inner counter-phase pips
            let pipL = L * 0.22, pipW = W * 0.45
            teardropLobe(cg, length: pipL, width: pipW, color: color, phase: .neg, alpha: a * 0.85, rotationDeg: 0)
            teardropLobe(cg, length: pipL, width: pipW, color: color, phase: .pos, alpha: a * 0.85, rotationDeg: 180)
        case "3dz2":
            let L = size * 0.4, W = size * 0.2
            teardropLobe(cg, length: L, width: W, color: color, phase: .pos, alpha: a, rotationDeg: -90)
            teardropLobe(cg, length: L, width: W, color: color, phase: .pos, alpha: a, rotationDeg: 90)
            // Equatorial torus (negative phase) — a flattened ellipse with annular gradient
            equatorialTorus(cg, rx: size * 0.34, ry: size * 0.1, color: color, alpha: a)
        case "3d_clover":
            let L = size * 0.36, W = size * 0.18
            let phases: [Phase] = [.pos, .neg, .pos, .neg]
            for i in 0..<4 {
                teardropLobe(cg, length: L, width: W, color: color,
                             phase: phases[i], alpha: a, rotationDeg: Double(i) * 90)
            }
        default: break
        }
        // Nucleus: bright dot with halo
        let nucR = max(1.8, size / 90)
        cg.setFillColor(color.nucleus.withAlpha(min(1.0, a * 0.35)).cgColor)
        let haloR = nucR * 2.4
        cg.fillEllipse(in: CGRect(x: -haloR, y: -haloR,
                                  width: haloR * 2, height: haloR * 2))
        cg.setFillColor(color.nucleus.withAlpha(min(1.0, a * 1.6)).cgColor)
        cg.fillEllipse(in: CGRect(x: -nucR, y: -nucR,
                                  width: nucR * 2, height: nucR * 2))
    }

    // MARK: - Phase

    private enum Phase { case pos, neg }

    private static func fillColor(_ c: OrbitalPhaseColors, _ p: Phase) -> RGBA {
        switch p {
        case .pos: return c.pos
        case .neg: return c.neg
        }
    }

    // MARK: - Gradient helpers

    private static let colorSpace = CGColorSpaceCreateDeviceRGB()

    private static func radialGradient(_ cg: CGContext,
                                       stops: [(location: Double, color: RGBA)],
                                       center: CGPoint, radius: Double) {
        let cgColors = stops.map { $0.color.cgColor } as CFArray
        let locations = stops.map { CGFloat($0.location) }
        guard let gradient = CGGradient(colorsSpace: colorSpace,
                                        colors: cgColors,
                                        locations: locations) else { return }
        cg.drawRadialGradient(
            gradient,
            startCenter: center, startRadius: 0,
            endCenter: center, endRadius: CGFloat(radius),
            options: []
        )
    }

    // MARK: - Spherical cloud (used for s-orbital shells)

    private static func sphericalCloud(_ cg: CGContext, radius: Double,
                                       color: OrbitalPhaseColors,
                                       phase: Phase, alpha: Double) {
        let fill = fillColor(color, phase)
        let fillAlpha = phase == .pos ? alpha * 0.7 : alpha * 0.55
        let rect = CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2)
        cg.saveGState()
        cg.addEllipse(in: rect)
        cg.clip()
        radialGradient(cg, stops: [
            (0,   fill.withAlpha(fillAlpha)),
            (0.6, fill.withAlpha(fillAlpha * 0.6)),
            (1.0, fill.withAlpha(0)),
        ], center: .zero, radius: radius)
        cg.restoreGState()
        // Faint isosurface ring
        let ringR = radius * 0.8
        cg.saveGState()
        cg.setStrokeColor(fill.withAlpha(min(1.0, alpha * 0.7) * 0.55).cgColor)
        cg.setLineWidth(CGFloat(max(0.6, radius / 80)))
        cg.addEllipse(in: CGRect(x: -ringR, y: -ringR,
                                 width: ringR * 2, height: ringR * 2))
        cg.strokePath()
        cg.restoreGState()
    }

    // MARK: - Nodal ring (annular shell for s-orbital radial nodes)

    private static func nodalRing(_ cg: CGContext, innerR: Double, outerR: Double,
                                  color: OrbitalPhaseColors,
                                  phase: Phase, alpha: Double) {
        let fill = fillColor(color, phase)
        let fillAlpha = phase == .pos ? alpha * 0.55 : alpha * 0.42
        let innerStop = innerR / outerR
        let peakStop = (innerR + outerR) / 2 / outerR
        let rect = CGRect(x: -outerR, y: -outerR, width: outerR * 2, height: outerR * 2)
        cg.saveGState()
        cg.addEllipse(in: rect)
        cg.clip()
        radialGradient(cg, stops: [
            (0,          fill.withAlpha(0)),
            (innerStop,  fill.withAlpha(0)),
            (peakStop,   fill.withAlpha(fillAlpha)),
            (1.0,        fill.withAlpha(0)),
        ], center: .zero, radius: outerR)
        cg.restoreGState()
    }

    // MARK: - Teardrop lobe (p- and d-orbital lobes)

    private static func teardropLobe(_ cg: CGContext, length: Double, width: Double,
                                     color: OrbitalPhaseColors,
                                     phase: Phase, alpha: Double, rotationDeg: Double) {
        let fill = fillColor(color, phase)
        let fillAlpha = phase == .pos ? alpha * 0.7 : alpha * 0.55
        let w0 = width
        // Teardrop path: starts at origin (nucleus), swells to max width near
        // 0.65L, rounds to a tip at 1.0L.
        let path = CGMutablePath()
        path.move(to: .zero)
        path.addCurve(to: CGPoint(x: length * 0.55, y: -w0 * 0.85),
                      control1: CGPoint(x: length * 0.1, y: -w0 * 0.18),
                      control2: CGPoint(x: length * 0.3, y: -w0 * 0.55))
        path.addCurve(to: CGPoint(x: length, y: 0),
                      control1: CGPoint(x: length * 0.75, y: -w0 * 0.98),
                      control2: CGPoint(x: length * 0.92, y: -w0 * 0.65))
        path.addCurve(to: CGPoint(x: length * 0.55, y: w0 * 0.85),
                      control1: CGPoint(x: length * 0.92, y: w0 * 0.65),
                      control2: CGPoint(x: length * 0.75, y: w0 * 0.98))
        path.addCurve(to: .zero,
                      control1: CGPoint(x: length * 0.3, y: w0 * 0.55),
                      control2: CGPoint(x: length * 0.1, y: w0 * 0.18))
        path.closeSubpath()

        cg.saveGState()
        cg.rotate(by: rotationDeg * .pi / 180)
        // Gradient clipped to teardrop, peaking near the tip
        cg.saveGState()
        cg.addPath(path)
        cg.clip()
        radialGradient(cg, stops: [
            (0.0, fill.withAlpha(fillAlpha)),
            (0.4, fill.withAlpha(fillAlpha * 0.85)),
            (0.8, fill.withAlpha(fillAlpha * 0.3)),
            (1.0, fill.withAlpha(0)),
        ], center: CGPoint(x: length * 0.65, y: 0), radius: length * 0.6)
        cg.restoreGState()
        // Isosurface outline
        cg.setStrokeColor(fill.withAlpha(min(1.0, alpha * 0.7) * 0.6).cgColor)
        cg.setLineWidth(CGFloat(max(0.6, length / 250)))
        cg.setLineJoin(.round)
        cg.addPath(path)
        cg.strokePath()
        cg.restoreGState()
    }

    // MARK: - Equatorial torus (for 3dz²)

    private static func equatorialTorus(_ cg: CGContext, rx: Double, ry: Double,
                                        color: OrbitalPhaseColors, alpha: Double) {
        let fill = color.neg
        let fillAlpha = alpha * 0.7
        let rect = CGRect(x: -rx, y: -ry, width: rx * 2, height: ry * 2)
        cg.saveGState()
        cg.addEllipse(in: rect)
        cg.clip()
        // Linear gradient horizontally doesn't give a torus; use radial in a
        // distorted space. Simplest: scale Y so the ellipse is a unit circle,
        // draw the annular radial gradient, then unscale.
        let aspect = ry / rx
        cg.scaleBy(x: 1, y: CGFloat(aspect))
        // After scale-by-aspect on the y axis, the ellipse becomes a circle of
        // radius rx in the new space, but vertical extent of clip is now ry/aspect = rx.
        // Hmm — that's not right. Let me undo: scale the gradient itself instead.
        cg.scaleBy(x: 1, y: 1 / CGFloat(aspect))   // revert
        radialGradient(cg, stops: [
            (0.0, fill.withAlpha(0)),
            (0.5, fill.withAlpha(0)),
            (0.8, fill.withAlpha(fillAlpha)),
            (1.0, fill.withAlpha(0)),
        ], center: .zero, radius: rx)
        cg.restoreGState()
    }
}
