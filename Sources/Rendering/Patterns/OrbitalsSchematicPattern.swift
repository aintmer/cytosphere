import CoreGraphics
import CoreText
import Foundation

/// Atomic orbitals — schematic textbook style. Crisp filled lobes with stroked
/// outlines, dashed x/y axes with arrow tips and italic labels. Types: 1s, 2s,
/// 2p, 3p, 3dz², 3dxy, 3dx²-y², 3dxz (foreshortened cloverleaf).
enum OrbitalsSchematicPattern {

    static let roster: [String] = [
        "1s", "1s",
        "2s",
        "2p", "2p", "2p",
        "3p", "3p",
        "3dz2", "3dz2", "3dz2",
        "3dxy", "3dxy",
        "3dx2y2", "3dx2y2",
        "3dxz",
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
            drawSchematic(elemCG, type: type, size: slotSize,
                          color: color, config: config)
        }
    }

    private static func drawSchematic(_ cg: CGContext, type: String, size: Double,
                                      color: OrbitalPhaseColors, config: RenderConfig) {
        let a = min(1.0, config.alpha * 2.2)
        let sw = max(1.0, size / 200)
        let nucR = max(1.5, size / 110)

        // Axes go below the lobes (mirrors HTML draw order)
        drawSchemAxes(cg, length: size * 0.55, color: color, alpha: a, sw: sw)

        switch type {
        case "1s":
            filledCircle(cg, r: size * 0.32,
                         fill: color.pos.withAlpha(min(1.0, a * 0.55)),
                         stroke: color.posLine.withAlpha(min(1.0, a * 1.4)),
                         lineWidth: sw * 0.8)

        case "2s":
            filledCircle(cg, r: size * 0.4,
                         fill: color.pos.withAlpha(min(1.0, a * 0.4)),
                         stroke: color.posLine.withAlpha(min(1.0, a * 1.4)),
                         lineWidth: sw * 0.8)
            filledCircle(cg, r: size * 0.16,
                         fill: color.neg.withAlpha(min(1.0, a * 0.6)),
                         stroke: color.negLine.withAlpha(min(1.0, a * 1.4)),
                         lineWidth: sw * 0.8)

        case "2p", "3p":
            let L = size * 0.42, W = size * 0.16, gap = size * 0.04
            drawSchemLobePlaced(cg, length: L, width: W, color: color,
                                phase: .pos, alpha: a, sw: sw,
                                translateX: gap, flipX: false)
            drawSchemLobePlaced(cg, length: L, width: W, color: color,
                                phase: .neg, alpha: a, sw: sw,
                                translateX: -gap, flipX: true)
            if type == "3p" {
                let Li = L * 0.28, Wi = W * 0.32
                drawSchemLobePlaced(cg, length: Li, width: Wi, color: color,
                                    phase: .neg, alpha: a * 0.85, sw: sw * 0.6,
                                    translateX: gap, flipX: false)
                drawSchemLobePlaced(cg, length: Li, width: Wi, color: color,
                                    phase: .pos, alpha: a * 0.85, sw: sw * 0.6,
                                    translateX: -gap, flipX: true)
            }

        case "3dz2":
            let L = size * 0.4, W = size * 0.15, gap = size * 0.04
            // Up lobe: rotate(-90) translate(gap, 0)
            drawSchemLobeRotated(cg, length: L, width: W, color: color,
                                 phase: .pos, alpha: a, sw: sw,
                                 rotationDeg: -90, translateX: gap, scaleX: 1)
            // Down lobe: rotate(90) translate(gap, 0)
            drawSchemLobeRotated(cg, length: L, width: W, color: color,
                                 phase: .pos, alpha: a, sw: sw,
                                 rotationDeg: 90, translateX: gap, scaleX: 1)
            // Equatorial ring
            filledEllipse(cg, rx: size * 0.3, ry: size * 0.08,
                          fill: color.neg.withAlpha(min(1.0, a * 0.65)),
                          stroke: color.negLine.withAlpha(min(1.0, a * 1.4)),
                          lineWidth: sw * 0.8)

        case "3dxy", "3dx2y2":
            let L = size * 0.36, W = size * 0.14, gap = size * 0.04
            let offsetDeg: Double = type == "3dxy" ? 45 : 0
            let phases: [Phase] = [.pos, .neg, .pos, .neg]
            for i in 0..<4 {
                let angle = offsetDeg + Double(i) * 90
                drawSchemLobeRotated(cg, length: L, width: W, color: color,
                                     phase: phases[i], alpha: a, sw: sw,
                                     rotationDeg: angle, translateX: gap, scaleX: 1)
            }

        case "3dxz":
            // Foreshortened cloverleaf: every other lobe scaled to 0.55 on x
            let L = size * 0.36, W = size * 0.14, gap = size * 0.04
            let phases: [Phase] = [.pos, .neg, .pos, .neg]
            for i in 0..<4 {
                let angle = 45 + Double(i) * 90
                let foreshorten = (i % 2 == 1) ? 0.55 : 1.0
                drawSchemLobeRotated(cg, length: L, width: W, color: color,
                                     phase: phases[i],
                                     alpha: a * (foreshorten < 1 ? 0.85 : 1),
                                     sw: sw,
                                     rotationDeg: angle, translateX: gap,
                                     scaleX: foreshorten)
            }

        default: break
        }

        // Nucleus dot
        cg.setFillColor(color.nucleus.withAlpha(min(1.0, a)).cgColor)
        cg.fillEllipse(in: CGRect(x: -nucR, y: -nucR,
                                  width: nucR * 2, height: nucR * 2))
    }

    // MARK: - Phase

    private enum Phase { case pos, neg }

    private static func phaseFill(_ c: OrbitalPhaseColors, _ p: Phase) -> RGBA {
        switch p {
        case .pos: return c.pos
        case .neg: return c.neg
        }
    }

    private static func phaseLine(_ c: OrbitalPhaseColors, _ p: Phase) -> RGBA {
        switch p {
        case .pos: return c.posLine
        case .neg: return c.negLine
        }
    }

    // MARK: - Schematic lobe (teardrop pointing along +x)

    private static func schemLobePath(length: Double, width: Double) -> CGPath {
        let w0 = width
        let path = CGMutablePath()
        path.move(to: CGPoint(x: length * 0.05, y: 0))
        path.addCurve(to: CGPoint(x: length * 0.6, y: -w0 * 0.95),
                      control1: CGPoint(x: length * 0.15, y: -w0 * 0.25),
                      control2: CGPoint(x: length * 0.35, y: -w0 * 0.7))
        path.addCurve(to: CGPoint(x: length, y: 0),
                      control1: CGPoint(x: length * 0.78, y: -w0 * 1.0),
                      control2: CGPoint(x: length * 0.92, y: -w0 * 0.7))
        path.addCurve(to: CGPoint(x: length * 0.6, y: w0 * 0.95),
                      control1: CGPoint(x: length * 0.92, y: w0 * 0.7),
                      control2: CGPoint(x: length * 0.78, y: w0 * 1.0))
        path.addCurve(to: CGPoint(x: length * 0.05, y: 0),
                      control1: CGPoint(x: length * 0.35, y: w0 * 0.7),
                      control2: CGPoint(x: length * 0.15, y: w0 * 0.25))
        path.closeSubpath()
        return path
    }

    /// Strokes/fills a teardrop lobe at the current origin, oriented along +x.
    private static func drawSchemLobe(_ cg: CGContext, length: Double, width: Double,
                                      color: OrbitalPhaseColors,
                                      phase: Phase, alpha: Double, sw: Double) {
        let fill = phaseFill(color, phase)
        let line = phaseLine(color, phase)
        let path = schemLobePath(length: length, width: width)
        cg.setFillColor(fill.withAlpha(min(1.0, alpha * 0.55)).cgColor)
        cg.setStrokeColor(line.withAlpha(min(1.0, alpha * 1.4)).cgColor)
        cg.setLineWidth(CGFloat(sw * 0.8))
        cg.setLineJoin(.round)
        cg.addPath(path)
        cg.drawPath(using: .fillStroke)
    }

    /// Translate by (translateX, 0), optionally flip in x, then draw lobe.
    /// Mirrors `translate(gap 0)` then optionally `scale(-1, 1)` from the HTML.
    private static func drawSchemLobePlaced(_ cg: CGContext, length: Double, width: Double,
                                            color: OrbitalPhaseColors,
                                            phase: Phase, alpha: Double, sw: Double,
                                            translateX: Double, flipX: Bool) {
        cg.saveGState()
        cg.translateBy(x: CGFloat(translateX), y: 0)
        if flipX { cg.scaleBy(x: -1, y: 1) }
        drawSchemLobe(cg, length: length, width: width,
                      color: color, phase: phase, alpha: alpha, sw: sw)
        cg.restoreGState()
    }

    /// Rotate by `rotationDeg`, translate by (translateX, 0), scale x by
    /// `scaleX`, then draw lobe. Mirrors `rotate(θ) translate(gap, 0) scale(s, 1)`.
    private static func drawSchemLobeRotated(_ cg: CGContext, length: Double, width: Double,
                                             color: OrbitalPhaseColors,
                                             phase: Phase, alpha: Double, sw: Double,
                                             rotationDeg: Double,
                                             translateX: Double, scaleX: Double) {
        cg.saveGState()
        cg.rotate(by: rotationDeg * .pi / 180)
        cg.translateBy(x: CGFloat(translateX), y: 0)
        if scaleX != 1 { cg.scaleBy(x: CGFloat(scaleX), y: 1) }
        drawSchemLobe(cg, length: length, width: width,
                      color: color, phase: phase, alpha: alpha, sw: sw)
        cg.restoreGState()
    }

    // MARK: - Filled + stroked primitives

    private static func filledCircle(_ cg: CGContext, r: Double,
                                     fill: RGBA, stroke: RGBA, lineWidth: Double) {
        let rect = CGRect(x: -r, y: -r, width: r * 2, height: r * 2)
        cg.setFillColor(fill.cgColor)
        cg.setStrokeColor(stroke.cgColor)
        cg.setLineWidth(CGFloat(lineWidth))
        cg.addEllipse(in: rect)
        cg.drawPath(using: .fillStroke)
    }

    private static func filledEllipse(_ cg: CGContext, rx: Double, ry: Double,
                                      fill: RGBA, stroke: RGBA, lineWidth: Double) {
        let rect = CGRect(x: -rx, y: -ry, width: rx * 2, height: ry * 2)
        cg.setFillColor(fill.cgColor)
        cg.setStrokeColor(stroke.cgColor)
        cg.setLineWidth(CGFloat(lineWidth))
        cg.addEllipse(in: rect)
        cg.drawPath(using: .fillStroke)
    }

    // MARK: - Dashed axes + arrow tips + italic labels

    private static func drawSchemAxes(_ cg: CGContext, length: Double,
                                      color: OrbitalPhaseColors,
                                      alpha: Double, sw: Double) {
        let lineColor = color.posLine
        let arrowSize = sw * 4
        let labels = ["x", "y"]
        for dir in 0..<2 {
            let dx: Double = dir == 0 ? 1 : 0
            let dy: Double = dir == 0 ? 0 : 1

            // Dashed line
            cg.saveGState()
            cg.setStrokeColor(lineColor.withAlpha(min(1.0, alpha * 0.85)).cgColor)
            cg.setLineWidth(CGFloat(sw * 0.8))
            cg.setLineCap(.round)
            cg.setLineDash(phase: 0, lengths: [CGFloat(sw * 5), CGFloat(sw * 3)])
            cg.move(to: CGPoint(x: -length * dx, y: -length * dy))
            cg.addLine(to: CGPoint(x: length * dx, y: length * dy))
            cg.strokePath()
            cg.restoreGState()

            // Arrow tip (solid triangle)
            let tipX = length * dx, tipY = length * dy
            let baseX = (length - arrowSize * 1.2) * dx
            let baseY = (length - arrowSize * 1.2) * dy
            let perpX = -dy * arrowSize * 0.5
            let perpY = dx * arrowSize * 0.5
            cg.setFillColor(lineColor.withAlpha(min(1.0, alpha)).cgColor)
            cg.move(to: CGPoint(x: tipX, y: tipY))
            cg.addLine(to: CGPoint(x: baseX + perpX, y: baseY + perpY))
            cg.addLine(to: CGPoint(x: baseX - perpX, y: baseY - perpY))
            cg.closePath()
            cg.fillPath()

            // Italic Georgia label
            let labelOffset = arrowSize * 1.8
            let labelPos = CGPoint(x: (length + labelOffset) * dx,
                                   y: (length + labelOffset) * dy)
            drawItalicLabel(cg, text: labels[dir], at: labelPos,
                            fontSize: sw * 8,
                            color: lineColor.withAlpha(min(1.0, alpha)))
        }
    }

    private static func drawItalicLabel(_ cg: CGContext, text: String,
                                        at point: CGPoint, fontSize: Double,
                                        color: RGBA) {
        // Prefer Georgia-Italic (matches HTML), fall back to Times-Italic.
        var font = CTFontCreateWithName("Georgia-Italic" as CFString,
                                        CGFloat(fontSize), nil)
        if CTFontCopyPostScriptName(font) as String != "Georgia-Italic" {
            font = CTFontCreateWithName("Times-Italic" as CFString,
                                        CGFloat(fontSize), nil)
        }
        let attrs: [CFString: Any] = [
            kCTFontAttributeName: font,
            kCTForegroundColorAttributeName: color.cgColor,
        ]
        guard let attrString = CFAttributedStringCreate(
            nil, text as CFString, attrs as CFDictionary
        ) else { return }
        let line = CTLineCreateWithAttributedString(attrString)
        var ascent: CGFloat = 0, descent: CGFloat = 0, leading: CGFloat = 0
        let width = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, &leading))
        cg.saveGState()
        cg.translateBy(x: point.x, y: point.y)
        cg.scaleBy(x: 1, y: -1)
        cg.textPosition = CGPoint(x: -width / 2,
                                  y: -(ascent + descent) / 2 + descent)
        CTLineDraw(line, cg)
        cg.restoreGState()
    }
}
