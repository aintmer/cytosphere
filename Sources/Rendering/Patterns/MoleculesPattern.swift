import CoreGraphics
import CoreText
import Foundation

/// Molecular structures — classic skeletal formulas. Eight molecules: benzene,
/// cyclohexane, pyridine, furan, imidazole, naphthalene, ethanol, acetone.
/// Carbon atoms are implicit (no label); hetero-atoms (N, O, S) get a colored
/// letter on a small bg-colored mask that hides the bond crossing.
enum MoleculesPattern {

    // MARK: - Data

    private struct Atom { let element: String; let x: Double; let y: Double }
    private struct Bond { let a: Int; let b: Int; let order: Int }
    private struct Molecule { let atoms: [Atom]; let bonds: [Bond] }

    private static let molecules: [String: Molecule] = {
        // 6-membered ring atoms (hexagon)
        func hex(firstElement: String = "C") -> [Atom] {
            (0..<6).map { i in
                let a = Double(i) * .pi / 3 - .pi / 2
                return Atom(element: i == 0 ? firstElement : "C",
                            x: cos(a), y: sin(a))
            }
        }
        // 5-membered ring atoms (pentagon)
        func pent(elements: [String]) -> [Atom] {
            (0..<5).map { i in
                let a = Double(i) * 2 * .pi / 5 - .pi / 2
                return Atom(element: elements[i], x: cos(a), y: sin(a))
            }
        }
        let altHex: [Bond] = (0..<6).map {
            Bond(a: $0, b: ($0 + 1) % 6, order: $0 % 2 == 0 ? 2 : 1)
        }
        let singleHex: [Bond] = (0..<6).map {
            Bond(a: $0, b: ($0 + 1) % 6, order: 1)
        }
        let altPent: [Bond] = [
            Bond(a: 0, b: 1, order: 1), Bond(a: 1, b: 2, order: 2),
            Bond(a: 2, b: 3, order: 1), Bond(a: 3, b: 4, order: 2),
            Bond(a: 4, b: 0, order: 1),
        ]
        return [
            "benzene":     Molecule(atoms: hex(),                 bonds: altHex),
            "cyclohexane": Molecule(atoms: hex(),                 bonds: singleHex),
            "pyridine":    Molecule(atoms: hex(firstElement: "N"), bonds: altHex),
            "furan":       Molecule(atoms: pent(elements: ["O","C","C","C","C"]), bonds: altPent),
            "imidazole":   Molecule(atoms: pent(elements: ["N","C","N","C","C"]), bonds: altPent),
            "naphthalene": Molecule(
                atoms: [
                    Atom(element:"C", x:  0,     y: -1),
                    Atom(element:"C", x:  0.866, y: -0.5),
                    Atom(element:"C", x:  0.866, y:  0.5),
                    Atom(element:"C", x:  0,     y:  1),
                    Atom(element:"C", x: -0.866, y:  0.5),
                    Atom(element:"C", x: -0.866, y: -0.5),
                    Atom(element:"C", x:  1.732, y: -1),
                    Atom(element:"C", x:  2.598, y: -0.5),
                    Atom(element:"C", x:  2.598, y:  0.5),
                    Atom(element:"C", x:  1.732, y:  1),
                ],
                bonds: [
                    Bond(a:0,b:1,order:2), Bond(a:1,b:2,order:1), Bond(a:2,b:3,order:2),
                    Bond(a:3,b:4,order:1), Bond(a:4,b:5,order:2), Bond(a:5,b:0,order:1),
                    Bond(a:1,b:6,order:1), Bond(a:6,b:7,order:2), Bond(a:7,b:8,order:1),
                    Bond(a:8,b:9,order:2), Bond(a:9,b:2,order:1),
                ]
            ),
            "ethanol": Molecule(
                atoms: [
                    Atom(element:"C", x:-1.0, y:0.3),
                    Atom(element:"C", x: 0.0, y:-0.3),
                    Atom(element:"O", x: 1.0, y:0.3),
                ],
                bonds: [Bond(a:0,b:1,order:1), Bond(a:1,b:2,order:1)]
            ),
            "acetone": Molecule(
                atoms: [
                    Atom(element:"C", x:-1.0, y:0.3),
                    Atom(element:"C", x: 0.0, y:-0.3),
                    Atom(element:"C", x: 1.0, y:0.3),
                    Atom(element:"O", x: 0.0, y:-1.3),
                ],
                bonds: [Bond(a:0,b:1,order:1), Bond(a:1,b:2,order:1), Bond(a:1,b:3,order:2)]
            ),
        ]
    }()

    static let roster: [String] = [
        "benzene", "benzene", "benzene",
        "cyclohexane", "cyclohexane",
        "pyridine", "pyridine",
        "furan", "furan",
        "imidazole", "imidazole",
        "naphthalene", "naphthalene",
        "ethanol",
        "acetone",
    ]

    // MARK: - Drawing

    static func draw(in cg: CGContext, size: CGSize, config: RenderConfig,
                     scale: Double, areaScale: Double, prng: PRNG) {
        PlacementEngine.place(in: cg, size: size, config: config,
                              scale: scale, areaScale: areaScale, prng: prng,
                              weighted: roster) { elemCG, x, y, type, slotSize, _ in
            guard let mol = molecules[type] else { return }
            let color = radialPalette(x: x, y: y,
                                      w: Double(size.width), h: Double(size.height),
                                      config: config)
            let alpha = min(1.0, config.alpha * 1.5)
            drawMolecule(elemCG, mol: mol, size: slotSize,
                         color: color, alpha: alpha, config: config)
        }
    }

    private static func drawMolecule(_ cg: CGContext, mol: Molecule, size: Double,
                                     color: RadialColor, alpha: Double,
                                     config: RenderConfig) {
        let sw = max(0.9, size / 55)
        let scaleFactor = size * 0.42

        // Center the molecule around the centroid.
        var sx = 0.0, sy = 0.0
        for atom in mol.atoms { sx += atom.x; sy += atom.y }
        let cxAtoms = sx / Double(mol.atoms.count)
        let cyAtoms = sy / Double(mol.atoms.count)
        func pos(_ a: Atom) -> (Double, Double) {
            ((a.x - cxAtoms) * scaleFactor, (a.y - cyAtoms) * scaleFactor)
        }

        // ---- Bonds ----------------------------------------------------------
        cg.saveGState()
        cg.setStrokeColor(color.line.withAlpha(alpha).cgColor)
        cg.setLineWidth(CGFloat(sw))
        cg.setLineCap(.round)
        for bond in mol.bonds {
            let (x1, y1) = pos(mol.atoms[bond.a])
            let (x2, y2) = pos(mol.atoms[bond.b])
            let dx = x2 - x1, dy = y2 - y1
            let len = (dx * dx + dy * dy).squareRoot()
            guard len > 0 else { continue }
            let ux = dx / len, uy = dy / len
            let nx = -uy, ny = ux
            let inset = sw * 2.5

            // Main bond line (shortened so it doesn't crash into atom labels).
            cg.move(to: CGPoint(x: x1 + ux * inset, y: y1 + uy * inset))
            cg.addLine(to: CGPoint(x: x2 - ux * inset, y: y2 - uy * inset))
            cg.strokePath()

            if bond.order == 2 {
                // Inner line of a double bond — offset toward the molecule's
                // centroid (which is now at the origin after centering).
                let midX = (x1 + x2) / 2, midY = (y1 + y2) / 2
                let sign: Double = (-midX * nx + -midY * ny) > 0 ? 1 : -1
                let off = sw * 1.7
                let innerInset = inset * 1.8
                cg.move(to: CGPoint(x: x1 + nx * off * sign + ux * innerInset,
                                    y: y1 + ny * off * sign + uy * innerInset))
                cg.addLine(to: CGPoint(x: x2 + nx * off * sign - ux * innerInset,
                                       y: y2 + ny * off * sign - uy * innerInset))
                cg.strokePath()
            }
        }
        cg.restoreGState()

        // ---- Hetero-atom labels --------------------------------------------
        let labelBg = config.background.baseRGB
            .lightnessShifted(config.backgroundLightness / 100)
        for atom in mol.atoms {
            if atom.element == "C" { continue }
            let (x, y) = pos(atom)

            // Mask circle that hides the bond underneath.
            let maskR = sw * 4.5
            cg.setFillColor(labelBg.cgColor)
            cg.fillEllipse(in: CGRect(x: x - maskR, y: y - maskR,
                                      width: maskR * 2, height: maskR * 2))

            // Letter.
            let letterColor: RGBA
            switch atom.element {
            case "N", "S": letterColor = color.pos
            case "O":      letterColor = color.neg
            default:       letterColor = color.line
            }
            drawCenteredLabel(
                cg, text: atom.element,
                at: CGPoint(x: x, y: y),
                fontSize: sw * 7.5,
                color: letterColor.withAlpha(min(1.0, alpha * 1.8))
            )
        }
    }

    /// Draws `text` centered on `point` in the y-down context (the text matrix
    /// is briefly flipped because CoreText glyphs are oriented y-up).
    private static func drawCenteredLabel(_ cg: CGContext, text: String,
                                          at point: CGPoint, fontSize: Double,
                                          color: RGBA) {
        let font = CTFontCreateWithName("Helvetica-Bold" as CFString,
                                        CGFloat(fontSize), nil)
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
