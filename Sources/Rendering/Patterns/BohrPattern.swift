import CoreGraphics
import Foundation

/// Bohr atoms — concentric electron shells with dots, central nucleus.
/// Color sweeps with canvas position (shared with bacteria, feynman, etc.).
enum BohrPattern {

    private struct Element {
        let name: String
        let shells: [Int]
    }

    /// 8 elements with their electron-shell counts (H through Ar).
    private static let elements: [String: Element] = [
        "H":  Element(name: "H",  shells: [1]),
        "He": Element(name: "He", shells: [2]),
        "Li": Element(name: "Li", shells: [2, 1]),
        "C":  Element(name: "C",  shells: [2, 4]),
        "O":  Element(name: "O",  shells: [2, 6]),
        "Ne": Element(name: "Ne", shells: [2, 8]),
        "Na": Element(name: "Na", shells: [2, 8, 1]),
        "Ar": Element(name: "Ar", shells: [2, 8, 8]),
    ]

    /// Weighted roster — lighter elements over-represented.
    static let roster: [String] = [
        "H", "H", "He", "He",
        "Li", "C", "C", "O",
        "O", "Ne", "Na", "Ar",
    ]

    static func draw(in cg: CGContext, size: CGSize, config: RenderConfig,
                     scale: Double, areaScale: Double, prng: PRNG) {
        PlacementEngine.place(in: cg, size: size, config: config,
                              scale: scale, areaScale: areaScale, prng: prng,
                              weighted: roster) { elemCG, x, y, type, elemSize, prng in
            guard let element = elements[type] else { return }
            let color = radialPalette(x: x, y: y,
                                      w: Double(size.width), h: Double(size.height),
                                      config: config)
            let rotOffset = prng.random(prng.next() * 4.97) * 2 * .pi
            drawAtom(elemCG, element: element, size: elemSize,
                     color: color, rotationOffset: rotOffset, config: config)
        }
    }

    private static func drawAtom(_ cg: CGContext, element: Element, size: Double,
                                 color: RadialColor, rotationOffset: Double,
                                 config: RenderConfig) {
        let a = min(1.0, config.alpha * 1.5)
        let numShells = element.shells.count
        let sw = max(0.7, size / 200)
        let innerR = size * 0.12
        let outerR = size * 0.46
        let shellSpacing = numShells == 1 ? 0 : (outerR - innerR) / Double(numShells - 1)

        var shellRadii: [Double] = []
        for i in 0..<numShells {
            shellRadii.append(numShells == 1
                ? (innerR + outerR) / 2
                : innerR + Double(i) * shellSpacing)
        }

        // Concentric shells
        cg.saveGState()
        cg.setStrokeColor(color.line.withAlpha(a * 0.6).cgColor)
        cg.setLineWidth(CGFloat(sw))
        for r in shellRadii {
            cg.addEllipse(in: CGRect(x: -r, y: -r, width: 2 * r, height: 2 * r))
            cg.strokePath()
        }
        cg.restoreGState()

        // Electrons
        let electronR = max(1.5, size / 55)
        let electronFill = color.pos.withAlpha(min(1.0, a * 1.3)).cgColor
        cg.setFillColor(electronFill)
        for i in 0..<numShells {
            let r = shellRadii[i]
            let numE = element.shells[i]
            let shellOffset = rotationOffset + Double(i) * .pi / 5
            for j in 0..<numE {
                let angle = shellOffset + Double(j) * (2 * .pi / Double(numE))
                cg.fillEllipse(in: CGRect(
                    x: r * cos(angle) - electronR,
                    y: r * sin(angle) - electronR,
                    width: electronR * 2, height: electronR * 2
                ))
            }
        }

        // Nucleus
        let totalE = element.shells.reduce(0, +)
        let nucleusR = max(2.2, size * (0.025 + Double(min(totalE, 18)) * 0.0015))
        cg.setFillColor(color.pos.withAlpha(min(1.0, a * 1.8)).cgColor)
        cg.fillEllipse(in: CGRect(x: -nucleusR, y: -nucleusR,
                                  width: nucleusR * 2, height: nucleusR * 2))
    }
}
